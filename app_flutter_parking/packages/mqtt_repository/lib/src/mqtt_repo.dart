import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import './entities/entities.dart';
import 'abstract_mqtt.dart';

class MqttRepository implements AbstractMqttRepository {
  late MqttServerClient _client;

  final _vagasController = StreamController<List<VagaEntity>>.broadcast();
  final _catracasController = StreamController<List<CatracaEntity>>.broadcast();
  final _vagasDisponiveisController = StreamController<int>.broadcast();

  @override
  Stream<List<VagaEntity>> get vagasStream => _vagasController.stream;
  @override
  Stream<List<CatracaEntity>> get catracasStream => _catracasController.stream;
  @override
  Stream<int> get vagasDisponiveisStream => _vagasDisponiveisController.stream;

  @override
  Future<void> conectar() async {
    _client = MqttServerClient('test.mosquitto.org', 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    _client.port = 1883;
    _client.keepAlivePeriod = 60;
    _client.onConnected = () => print('MQTT Conectado');
    _client.onDisconnected = () => print('MQTT Desconectado');
    
    final connMess = MqttConnectMessage().withClientIdentifier(_client.clientIdentifier).startClean();
    
    try {
      await _client.connect();
    } catch (e) {
      print('MQTT Erro ao conectar: $e');
      _client.disconnect();
      return;
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _client.subscribe('parking/status', MqttQos.atLeastOnce);
      _client.subscribe('parking/commands', MqttQos.atLeastOnce);

      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = c[0].topic;

        _processarMensagem(topic, payload);
      });
    }
  }

  void _processarMensagem(String topic, String payload) {
    try {
      final json = jsonDecode(payload);

      if (topic == 'parking/status') {
        final List<VagaEntity> vagas = (json['vagas'] as List)
            .map((vagaJson) => VagaEntity.fromDocument(vagaJson))
            .toList();
        final int vagasDisponiveis = json['vagas_disponiveis'] ?? 0;

        _vagasController.add(vagas);
        _vagasDisponiveisController.add(vagasDisponiveis);
        print('Estado das vagas atualizado.');

      } else if (topic == 'parking/commands') {
        if (json is Map<String, dynamic>) {
          if (json.containsKey('id') && json.containsKey('role')) {
            // Mensagem de configuração de catraca
            final catraca = CatracaEntity.fromDocument(json);
            _catracasController.add([catraca]);
            print('Catraca recebida: ${catraca.id} (${catraca.role})');
          } else if (json.containsKey('reservar_vaga')) {
            // Mensagem de reserva/cancelamento
            final id = json['reservar_vaga'];
            final estado = json['estado'];
            print('Comando de reserva recebido: Vaga $id, estado: $estado');
            // Aqui você pode adicionar lógica adicional se quiser
          } else {
            print('Comando desconhecido: $json');
          }
        } else {
          print('Formato inválido para parking/commands: esperado Map');
        }
      }

    } catch (e) {
      print('Erro ao processar mensagem do tópico $topic: $e');
    }
  }


  @override
  void reservarVaga(String id, bool estado) {
    final mensagem = jsonEncode({"reservar_vaga": id, "estado": estado});
    _publicar("parking/commands", mensagem);
  }

  @override
  void cancelarReserva(String id, bool estado) {
    final mensagem = jsonEncode({"reservar_vaga": id, "estado": estado});
    _publicar("parking/commands", mensagem);
  }

  @override
  void abrirCatraca(String id) {
    final mensagem = jsonEncode({"abrir_catraca": id});
    _publicar("parking/commands", mensagem);
  }

  void _publicar(String topico, String mensagem) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder()..addString(mensagem);
      _client.publishMessage(topico, MqttQos.atLeastOnce, builder.payload!);
      print('Publicado em $topico: $mensagem');
    }
  }

  @override
  void dispose() {
    _vagasController.close();
    _catracasController.close();
    _vagasDisponiveisController.close();
    _client.disconnect();
  }
}