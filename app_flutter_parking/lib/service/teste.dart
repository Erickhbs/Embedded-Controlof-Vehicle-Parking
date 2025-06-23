import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;

  int vagasLivres = 0;
  List<Map<String, dynamic>> vagas = []; // Para guardar {id, ocupada, reservada}

  // Callback para notificar a interface ou outro módulo
  Function(String message)? onMessageReceived;

  Future<void> connect() async {
    client = MqttServerClient('192.168.0.100', 'flutter_app_id');
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Erro ao conectar: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Conectado ao broker MQTT');
      subscribeToTopic('parking/status');
    } else {
      print('Falha ao conectar: ${client.connectionStatus}');
      Future.delayed(Duration(seconds: 5), connect);
    }
  }

  void onConnected() {
    print('Conexão MQTT estabelecida');
  }

  void onDisconnected() {
    print('Conexão perdida. Tentando reconectar...');
    Future.delayed(Duration(seconds: 5), connect);
  }

  void onSubscribed(String topic) {
    print('Inscrito no tópico: $topic');
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages != null && messages.isNotEmpty) {
        final MqttPublishMessage recMess = messages[0].payload as MqttPublishMessage;
        final String payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        print('Mensagem recebida de $topic:\n$payload');
        processMessage(payload);
        onMessageReceived?.call(payload);
      }
    });
  }

  void processMessage(String message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      vagasLivres = data['vagas_disponiveis'] ?? 0;

      vagas = List<Map<String, dynamic>>.from(data['vagas'] ?? []);

      print('Estado processado com sucesso:');
      print('Vagas livres: $vagasLivres');
      print('Todas as vagas: $vagas');
    } catch (e) {
      print('Erro ao processar JSON: $e');
    }
  }

  /// Envia comando para reservar/desreservar vaga
  void reservarVaga(String idVaga, bool reservar) {
    final message = jsonEncode({
      "reservar_vaga": idVaga,
      "estado": reservar,
    });
    publishMessage('parking/commands', message);
  }

  /// Envia comando para abrir catraca (entrada ou saída)
  void abrirCatraca(String idCatraca) {
    final message = jsonEncode({
      "abrir_catraca": idCatraca,
    });
    publishMessage('parking/commands', message);
  }

  /// Publicador genérico
  void publishMessage(String topic, String message) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Publicado em $topic:\n$message');
    } else {
      print('Cliente MQTT não está conectado');
    }
  }
}
