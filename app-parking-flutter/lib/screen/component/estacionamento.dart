import 'package:flutter/material.dart';
import 'package:parking_lot/screen/component/mqttservice.dart';

class Estacionamento extends StatefulWidget {
  const Estacionamento({super.key});

  @override
  State<Estacionamento> createState() => _EstacionamentoState();
}

class _EstacionamentoState extends State<Estacionamento> {
  final MQTTService mqttService = MQTTService();
  int vagasLivres = 0;
  List<int> corVaga = [1,1,1,1]; // Índices das cores para cada vaga
  List<bool> reservado = [false,false,false,false]; // Estado de reserva de cada vaga

  @override
  void initState() {
    super.initState();
    mqttService.onMessageReceived = (message) {
      setState(() {
        mqttService.processMessage(message);
        vagasLivres = mqttService.vagasLivres;
        corVaga = mqttService.corVagaIndices;
        reservado = mqttService.reservadoStatus;
      });
    };
    mqttService.connect();
  }

  static Color res = Colors.amber;
  final List<Color> cores = [Colors.red, Colors.green, Colors.amber];
  final List<double> tamanhos = [70, 65];

  void _sendMessageToBroker() {
    vagasLivres = corVaga.where((cor) => cor == 0).length;
    final message = '${vagasLivres}_${corVaga.join('')}_${reservado.map((e) => e ? 1 : 0).join('')}';
    mqttService.publishMessage('parking/vagas', message);
  }

  void _onVagaPressed(int index) {
    if (corVaga[index] == 1 && !reservado[index]) { // Verifica se a vaga está verde e não reservada
      setState(() {
        // Altera a cor da vaga para "amber"
        corVaga[index] = 2;
        reservado[index] = true;
        vagasLivres--;
        // Envia a mensagem para o broker MQTT
        _sendMessageToBroker();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Painel de vagas livres
          Container(
            width: 400,
            height: 200,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            child: Column(
              children: [
                Text("Vagas Livres: $vagasLivres", style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
          // Estacionamento
          Stack(
            children: [
              // Chão do estacionamento
              Container(
                width: 390,
                height: 390,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              // Loja
              Container(
                width: 390,
                height: 100,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              // Muros e muretas
              _buildMuro(context, left: 0, height: 400),
              _buildMuro(context, right: 0, height: 400),
              _buildMuro(context, bottom: 0, width: 90),
              _buildMuro(context, right: 0, bottom: 0, width: 100),
              _buildMuro(context, left: 150, bottom: 0, width: 75),
              _buildMuro(context, right: 0, top: 150, width: 75),
              _buildMuro(context, right: 0, top: 220, width: 75),
              _buildMuro(context, right: 0, top: 290, width: 75),
              _buildMuro(context, left: 0, top: 150, width: 75),
              _buildMuro(context, left: 0, top: 220, width: 75),
              _buildMuro(context, left: 0, top: 290, width: 75),
              
              // Botões das vagas
              _buildVagaButton(context, 0, left: 5, top: 155),
              _buildVagaButton(context, 1, left: 5, bottom: 100),
              _buildVagaButton(context, 2, right: 5, top: 155),
              _buildVagaButton(context, 3, right: 5, bottom: 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuro(BuildContext context,
      {double? left, double? right, double? top, double? bottom, double? width, double? height}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: width ?? 5,
        height: height ?? 5,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildVagaButton(BuildContext context, int index,
    {double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        color: reservado[index] ? res : cores[corVaga[index] == 2 ? 1 : corVaga[index]],
        width: tamanhos[0],
        height: tamanhos[1],
        child: TextButton(
          onPressed: corVaga[index] == 1 && !reservado[index]
              ? () => _onVagaPressed(index)
              : null, // Desativa o botão se não for verde ou se estiver reservado
          child: Icon(
            Icons.car_crash,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}