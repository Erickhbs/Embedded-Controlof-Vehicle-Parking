---
# Controlador Embarcado de Estacionamento Inteligente
Este repositório contém o firmware para um sistema de controle de estacionamento de veículos, desenvolvido para rodar em um ESP32 usando o FreeRTOS. O sistema gerencia vagas de estacionamento e catracas de entrada/saída, comunicando-se com um aplicativo Flutter via MQTT e sincronizando o estado com o Firebase.
## Funcionalidades
- Controle de até 4 vagas de estacionamento com sensores de presença (usando sensores magnéticos ou de proximidade).
- Controle de 2 catracas (entrada e saída) usando servomotores.
- Atualização em tempo real da disponibilidade de vagas.
- Reserva de vagas pelo aplicativo Flutter.
- Sincronização do estado do estacionamento com o Firebase para persistência.
- Publicação do estado (vagas disponíveis, ocupadas, reservadas) via MQTT para o aplicativo.
- Recebimento de comandos do aplicativo (abertura de catraca, reserva de vaga) via MQTT.
## Hardware Necessário
- Placa ESP32.
- Sensores de presença (por exemplo, sensores magnéticos de porta) para cada vaga.
- LEDs (vermelho para ocupado, RGB para livre/reservado) para cada vaga.
- 2 servomotores (para as catracas).
- Fonte de alimentação adequada.
## Configuração do Ambiente
1. **Arduino IDE**: Configure a IDE para programar o ESP32 (instale o suporte para ESP32 via Board Manager).
2. **Bibliotecas**: Instale as seguintes bibliotecas via Library Manager:
   - `WiFi`
   - `PubSubClient`
   - `ESP32Servo`
   - `ArduinoJson`
   - `Firebase_ESP_Client` (e suas dependências: `TokenHelper` e `RTDBHelper`)
3. **FreeRTOS**: Já incluído no ESP32 Arduino Core.
## Estrutura do Código
O código está organizado em:
- **Definições e configurações globais**: Credenciais de rede, Firebase, MQTT e constantes.
- **Structs e enums**: Definem as estruturas de dados para as vagas e catracas.
- **Variáveis globais e instâncias**: Objetos para WiFi, MQTT, Firebase, e arrays de vagas e catracas.
- **Funções de lógica**: `atualizarEstadoCompleto()` (atualiza contagem e LEDs) e `publicarEstado()` (envia estado via MQTT e Firebase).
- **Tarefas FreeRTOS**:
   - `taskLerSensores`: Lê os sensores das vagas periodicamente.
   - `taskControleCatracas`: Controla a abertura e fechamento das catracas.
   - `taskMQTT`: Gerencia a conexão MQTT e publica o estado quando alterado.
- **Setup**: Inicializa hardware, conexões, e cria as tarefas.
## Fluxo de Funcionamento
1. **Inicialização**:
   - Configura pinos, servos, LEDs.
   - Conecta ao WiFi, Firebase e MQTT.
   - Restaura o último estado salvo no Firebase.
   - Inicia as tarefas do FreeRTOS.
2. **Leitura dos Sensores**:
   - A tarefa `taskLerSensores` verifica o estado de cada sensor e atualiza o estado da vaga (ocupada/livre). Se houver mudança, atualiza os LEDs e a contagem de vagas.
3. **Controle das Catracas**:
   - A tarefa `taskControleCatracas` verifica se há comandos de abertura (recebidos via MQTT). Se for entrada, só abre se houver vaga disponível. Mantém aberta por 3 segundos.
4. **Comunicação MQTT**:
   - A tarefa `taskMQTT` mantém a conexão e processa mensagens. Recebe comandos do app (reservar vaga, abrir catraca) e publica o estado do estacionamento.
5. **Firebase**:
   - O estado do estacionamento (vagas) é enviado ao Firebase em tempo real. No boot, o estado é restaurado do Firebase.
## Comunicação (MQTT e Firebase)
- **MQTT**: 
   - Tópico de subscrição: `parking/commands` (recebe comandos).
   - Tópico de publicação: `parking/status` (publica o estado).
   - Formato: JSON. Exemplo de comando para reservar: `{"reservar_vaga": "V1", "estado": true}`. Para abrir catraca: `{"abrir_catraca": "C1"}`.
- **Firebase**:
   - Usado para persistência do estado. O caminho no RTDB é `/parking_status`.
   - No boot, o ESP32 lê esse caminho para restaurar o estado anterior.
## Tarefas (FreeRTOS)
- Prioridades: A tarefa MQTT tem prioridade 1, as demais prioridade 2.
- Mutex: `sharedStateMutex` protege todas as variáveis compartilhadas (estado das vagas, catracas, etc).
## Como Usar
1. Carregue o código no ESP32 (substitua as credenciais no código: WiFi, Firebase, MQTT).
2. Monte o circuito conforme as definições de pinos no código.
3. Inicie o broker MQTT (se for local) e verifique a conexão.
4. Configure o Firebase (crie um projeto e ative o RTDB).
5. Execute o aplicativo Flutter (disponível em outro repositório) para interagir com o sistema.
## Contribuição
Contribuições são bem-vindas! Siga as diretrizes:
- Faça um fork do projeto.
- Crie uma branch para sua feature (`git checkout -b feature/nova-feature`).
- Faça commit das suas alterações. (`git commit -m "sua mensagem"`)
- Push para a branch (`git push origin feature/nova-feature`).
- Abra um Pull Request.
