
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;
  int vagasLivres = 0;
  List<int> corVagaIndices = [];
  List<bool> reservadoStatus = [];
  Function(String message)? onMessageReceived;

  Future<void> connect() async {
    //colocar o broker ou o conectar via tcp/ip
    client = MqttServerClient('192.168.0.100', 'mqttx_a0d8e8d1');
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
      .withClientIdentifier('jubijubi')
      .startClean()
      .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Erro de conexão: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Conectado ao broker MQTT');
      subscribeToTopic('parking/vagas');
    } else {
      print('Erro na conexão: ${client.connectionStatus}');
      // Tentar reconectar após um breve intervalo
      Future.delayed(Duration(seconds: 5), () {
        connect();
      });
    }
  }

  void onConnected() {
    print('Conectado!');
  }

  void onDisconnected() {
    print('Desconectado!');
    // Tentar reconectar após um breve intervalo
    Future.delayed(Duration(seconds: 5), () {
      connect();
    });
  }

  void onSubscribed(String topic) {
    print('Inscrito em $topic');
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
    if (client.updates != null) {
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        if (c != null && c.isNotEmpty) {
          try {
            final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
            final String pt =
                MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

            print('Mensagem recebida de $topic: $pt');
            processMessage(pt);
            if (onMessageReceived != null) {
              onMessageReceived!(pt);
            } else {
              print('Nenhum callback registrado para processar a mensagem.');
            }
          } catch (e) {
            print('Erro ao processar mensagem: $e');
          }
        } else {
          print('Erro: Mensagem MQTT recebida vazia ou nula.');
        }
      });
    } else {
      print('Erro: Listener de atualizações MQTT não está ativo.');
    }
  }

  void processMessage(String message) {
    final parts = message.split('_');
    if (parts.length == 3) {
      try {
        vagasLivres = int.parse(parts[0]);
        corVagaIndices = parts[1].split('').map(int.parse).toList();
        reservadoStatus = parts[2].split('').map((e) => e == '1').toList();
        print(
            'Vagas Livres: $vagasLivres, Cor da Vaga: $corVagaIndices, Reservado: $reservadoStatus');
      } catch (e) {
        print('Erro ao processar os dados da mensagem: $e');
      }
    } else {
      print('Formato de mensagem inválido: $message');
    }
  }

  void publishMessage(String topic, String message) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    } else {
      print('Erro: Cliente MQTT não está conectado.');
    }
  }
}
