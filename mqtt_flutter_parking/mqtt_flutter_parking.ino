/**
 * @author Erick Henrique Barros da Silva 
 * @brief Controlador Embarcado de Estacionamento de Veículos baseado em FreeRTOS e Flutter.
 * @date 2025-06-27 -- 
 * @Orientador Prof. Dr. josenalde barbosa de oliveira
 */

// =================================================================
// INCLUSÃO DE BIBLIOTECAS
// =================================================================
#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// =================================================================
// DEFINIÇÕES E CONFIGURAÇÕES GLOBAIS
// =================================================================
// --- Credenciais de Rede ---
#define WIFI_SSID "WIFI_SSID"
#define WIFI_PASSWORD "WIFI_PASSWORD"

// --- Credenciais do Firebase ---
#define API_KEY "API_KEY"
#define USER_EMAIL "USER_EMAIL"
#define USER_PASSWORD "USER_PASSWORD"
#define DATABASE_URL "DATABASE_URL"

// --- Configurações do Broker MQTT ---
const char* mqtt_server = "mqtt_server";
const int mqtt_port = mqtt_port;

// --- Constantes do Projeto ---
const int TOTAL_VAGAS = 4;
const int TOTAL_CATRACAS = 2;
const size_t TAMANHO_ID_CATRACA = 10;

// =================================================================
// STRUCTS E ENUMS
// =================================================================
enum RoleCatraca { ENTRADA, SAIDA };
struct Coordenada { double x, y; };

struct Catraca {
  const char* id;
  Coordenada coordenada;
  RoleCatraca role;
  byte pinoServo;
  Servo servo;
};

struct Vaga {
  const char* id;
  bool ocupada;
  bool reservada;
  byte pinoSensor;
  byte pinoLedVermelho;
  byte pinoLedRgbG;
  byte pinoLedRgbB;
  Coordenada coordenada;
};

// =================================================================
// VARIÁVEIS GLOBAIS E INSTÂNCIAS DE OBJETOS
// =================================================================
// --- Instâncias de Rede e Firebase ---
WiFiClient espClient;
PubSubClient client(espClient);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// --- Definição do Hardware do Estacionamento ---
Catraca catracas[TOTAL_CATRACAS] = {
  {"C1", {0.0, 0.0}, ENTRADA, 23},
  {"C3", {0.0, 1.0}, SAIDA, 21}
};

Vaga vagas[TOTAL_VAGAS] = {
  {"V1", false, false, 27, 35, 12, 13, {-5.886109, -35.363188}},
  {"V2", false, false, 26, 32, 14, 15, {-5.886106, -35.363218}},
  {"V3", false, false, 25, 5, 17, 19, {-5.886103, -35.363248}},
  {"V4", false, false, 33, 18, 20, 24, {-5.886100, -35.363278}}
};

// --- Variáveis de Controle de Estado ---
int vagasDisponiveis = TOTAL_VAGAS; 
volatile bool estadoAlterado = true; 

char comandoAbrirCatraca[TAMANHO_ID_CATRACA] = "";

// --- Primitivas do FreeRTOS ---
SemaphoreHandle_t sharedStateMutex; // Mutex para proteger o acesso a TODAS as variáveis compartilhadas.

// --- Protótipos de Funções ---
void publicarEstado();
void reconnect();

// =================================================================
// FUNÇÕES DE LÓGICA DO PROJETO
// =================================================================
/**
 * @brief Atualiza a contagem de vagas e os LEDs. Chamado sempre DENTRO de um mutex.
 */
void atualizarEstadoCompleto() {
  int ocupadasOuReservadas = 0;
  for (int i = 0; i < TOTAL_VAGAS; i++) {
    if (vagas[i].ocupada || vagas[i].reservada) {
      ocupadasOuReservadas++;
    }

    // Lógica dos LEDs movida para cá para garantir consistência
    if (vagas[i].ocupada) { // Ocupada tem prioridade
      digitalWrite(vagas[i].pinoLedVermelho, HIGH);
      digitalWrite(vagas[i].pinoLedRgbG, HIGH); // Apaga verde
      digitalWrite(vagas[i].pinoLedRgbB, HIGH); // Apaga azul
    } else if (vagas[i].reservada) { // Reservada
      digitalWrite(vagas[i].pinoLedVermelho, LOW);
      digitalWrite(vagas[i].pinoLedRgbG, HIGH); // Apaga verde
      digitalWrite(vagas[i].pinoLedRgbB, LOW);  // Acende azul
    } else { // Livre
      digitalWrite(vagas[i].pinoLedVermelho, LOW);
      digitalWrite(vagas[i].pinoLedRgbG, LOW);  // Acende verde
      digitalWrite(vagas[i].pinoLedRgbB, HIGH); // Apaga azul
    }
  }
  vagasDisponiveis = TOTAL_VAGAS - ocupadasOuReservadas;
  estadoAlterado = true; 
}

// =================================================================
// TAREFAS DO FREERTOS
// =================================================================
/**
 * @brief Tarefa que lê continuamente os sensores das vagas.
 */
void taskLerSensores(void *pvParameters) {
  while (true) {
    bool algumaVagaMudou = false;

    if (xSemaphoreTake(sharedStateMutex, portMAX_DELAY) == pdTRUE) {
      for (int i = 0; i < TOTAL_VAGAS; i++) {
        bool estadoAtual = !digitalRead(vagas[i].pinoSensor);

        if (estadoAtual != vagas[i].ocupada) {
          algumaVagaMudou = true;
          vagas[i].ocupada = estadoAtual;

          if (estadoAtual && vagas[i].reservada) {
            vagas[i].reservada = false;
          }
          if (!estadoAtual) {
            vagas[i].reservada = false;
          }
        }
      }

      if (algumaVagaMudou) {
        atualizarEstadoCompleto();
      }
      xSemaphoreGive(sharedStateMutex);
    }
    vTaskDelay(200 / portTICK_PERIOD_MS); // Intervalo de leitura dos sensores
  }
}

/**
 * @brief Tarefa que processa comandos de abertura de catraca de forma segura e eficiente.
 */
void taskControleCatracas(void *pvParameters) {
  const int ANGULO_SERVO_ABERTO = 90;
  const int ANGULO_SERVO_FECHADO = 0;
  const int TEMPO_CATRACA_ABERTA_MS = 3000;
  while (true) {
    int indiceCatracaParaOperar = -1;
    char idCatracaLocal[TAMANHO_ID_CATRACA] = "";
    if (xSemaphoreTake(sharedStateMutex, portMAX_DELAY) == pdTRUE) {
      if (comandoAbrirCatraca[0] != '\0') {a
        strlcpy(idCatracaLocal, comandoAbrirCatraca, sizeof(idCatracaLocal));
        comandoAbrirCatraca[0] = '\0'; 

        for (int i = 0; i < TOTAL_CATRACAS; i++) {
          if (strcmp(catracas[i].id, idCatracaLocal) == 0) {
            bool podeAbrir = ((catracas[i].role == ENTRADA && vagasDisponiveis > 0) || catracas[i].role == SAIDA);
            if (podeAbrir) {
              indiceCatracaParaOperar = i;
            }
            break;
          }
        }
      }
      xSemaphoreGive(sharedStateMutex);
    }
    if (indiceCatracaParaOperar != -1) {
      Serial.printf("Acionando catraca: %s\n", catracas[indiceCatracaParaOperar].id);
      catracas[indiceCatracaParaOperar].servo.write(ANGULO_SERVO_ABERTO);
      vTaskDelay(TEMPO_CATRACA_ABERTA_MS / portTICK_PERIOD_MS);
      catracas[indiceCatracaParaOperar].servo.write(ANGULO_SERVO_FECHADO);
      Serial.printf("Catraca %s fechada.\n", catracas[indiceCatracaParaOperar].id);
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

/**
 * @brief Tarefa que gerencia a conexão e o loop do cliente MQTT.
 */
void taskMQTT(void *pvParameters) {
  while (true) {
    if (!client.connected()) {
      reconnect();
    }
    client.loop();

    if (estadoAlterado) {
      publicarEstado();
      estadoAlterado = false;
    }
    vTaskDelay(200 / portTICK_PERIOD_MS);
  }
}

// =================================================================
// CALLBACK E SETUP
// =================================================================
/**
 * @brief Callback do MQTT, processa comandos vindos do app Flutter.
 */
void callback(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<256> doc;
  deserializeJson(doc, payload, length);

  if (xSemaphoreTake(sharedStateMutex, portMAX_DELAY) == pdTRUE) {
    bool mudancaDeEstado = false;

    if (doc.containsKey("reservar_vaga")) {
      const char* id = doc["reservar_vaga"];
      bool reservar = doc["estado"];
      for (int i = 0; i < TOTAL_VAGAS; i++) {
        if (strcmp(vagas[i].id, id) == 0) {
          if (reservar && !vagas[i].ocupada && !vagas[i].reservada) {
            vagas[i].reservada = true;
            mudancaDeEstado = true;
          }else{
            vagas[i].reservada = false;
            mudancaDeEstado = true;
          }
          break;
        }
      }
    }

    if (doc.containsKey("abrir_catraca")) {
      strlcpy(comandoAbrirCatraca, doc["abrir_catraca"], sizeof(comandoAbrirCatraca));
    }

    if (mudancaDeEstado) {
      atualizarEstadoCompleto();
    }
    xSemaphoreGive(sharedStateMutex);
  }
}

/**
 * @brief Configura e conecta à rede Wi-Fi.
 */
void setup_wifi() {
  //Serial.print("Conectando ao WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    //Serial.print(".");
  }
  //Serial.println("\nWiFi conectado: " + WiFi.localIP().toString());
}

/**
 * @brief Configura e inicializa a conexão com o Firebase.
 */
void setup_firebase() {
  //Serial.print("Inicializando Firebase...");
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  unsigned long start = millis();
  while (!Firebase.ready()) {
    if(millis() - start > 15000) { 
        //Serial.println("\nFalha ao conectar com Firebase.");
        return;
    }
    delay(500);
    //Serial.print(".");
  }
  //Serial.println("\nFirebase pronto!");
  //Serial.println(Firebase.ready() ? "FBD conectado! ":"FBD com erro");
}

/**
 * @brief Tenta reconectar ao broker MQTT.
 */
void reconnect() {
  while (!client.connected()) {
    //Serial.print("Tentando conectar ao MQTT...");
    if (client.connect("ESP32_ParkingClient_Otimizado")) {
      //Serial.println(" conectado!");
      client.subscribe("parking/commands");
      estadoAlterado = true; // Força uma publicação de estado ao reconectar
    } else {
      //Serial.printf(" falhou, rc=%d. Tentando novamente em 5 segundos\n", client.state());
      vTaskDelay(5000 / portTICK_PERIOD_MS);
    }
  }
}

/**
 * @brief Publica o estado atual para o MQTT e Firebase.
 */
void publicarEstado() {
  StaticJsonDocument<512> doc;
  if (xSemaphoreTake(sharedStateMutex, portMAX_DELAY) == pdTRUE) {
    doc["vagas_disponiveis"] = vagasDisponiveis;
    JsonArray vagasStatus = doc.createNestedArray("vagas");
    for (int i = 0; i < TOTAL_VAGAS; i++) {
      JsonObject o = vagasStatus.createNestedObject();
      o["id"] = vagas[i].id;
      o["ocupada"] = vagas[i].ocupada;
      o["reservada"] = vagas[i].reservada;
    }
    xSemaphoreGive(sharedStateMutex);
  }
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  client.publish("parking/status", jsonBuffer);
  if (Firebase.ready()) {
    FirebaseJson firebaseJson;
    firebaseJson.setJsonData(jsonBuffer);
    Firebase.RTDB.setJSON(&fbdo, "/parking_status", &firebaseJson);
  }
  //Serial.println(jsonBuffer);
  //Serial.print("Estado publicado: ");
}

/**
 * @brief Restaura o último estado salvo no Firebase ao iniciar.
 */
void restaurarEstadoDoFirebase() {
  //Serial.println("Restaurando estado do Firebase...");
  if (Firebase.ready() && Firebase.RTDB.getJSON(&fbdo, "/parking_status")) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_json) {
        StaticJsonDocument<512> doc;
        deserializeJson(doc, fbdo.jsonString());
        if(xSemaphoreTake(sharedStateMutex, portMAX_DELAY) == pdTRUE) {
            JsonArray arr = doc["vagas"].as<JsonArray>();
            for (int i = 0; i < arr.size() && i < TOTAL_VAGAS; i++) {
                vagas[i].ocupada = arr[i]["ocupada"];
                vagas[i].reservada = arr[i]["reservada"];
            }
            atualizarEstadoCompleto();
            xSemaphoreGive(sharedStateMutex);
            //Serial.println("Estado restaurado com sucesso!");
        }
    }
  } else {
    //Serial.println("Nenhum backup encontrado ou Firebase indisponível.");
  }
}

// =================================================================
// SETUP
// =================================================================
void setup() {
  Serial.begin(115200);
  delay(1000); // Pausa para o Monitor Serial estabilizar

  for (int i = 0; i < TOTAL_CATRACAS; i++) {
    catracas[i].servo.attach(catracas[i].pinoServo);
    catracas[i].servo.write(0);
  }
  for (int i = 0; i < TOTAL_VAGAS; i++) {
    pinMode(vagas[i].pinoSensor, INPUT_PULLUP);
    pinMode(vagas[i].pinoLedVermelho, OUTPUT);
    pinMode(vagas[i].pinoLedRgbG, OUTPUT);
    pinMode(vagas[i].pinoLedRgbB, OUTPUT);
  }

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  setup_firebase();

  sharedStateMutex = xSemaphoreCreateMutex();

  restaurarEstadoDoFirebase();

  xTaskCreatePinnedToCore(taskLerSensores, "LerSensores", 3072, NULL, 2, NULL, 0);
  xTaskCreatePinnedToCore(taskControleCatracas, "CtrlCatracas", 3072, NULL, 2, NULL, 0);
  xTaskCreatePinnedToCore(taskMQTT, "TaskMQTT", 8192, NULL, 1, NULL, 1);

  //Serial.println("Setup concluído. Sistema em operação ;).");
}

void loop() {
  //não é necessária quando usamos FreeRTOS.
  vTaskDelete(NULL);
}
