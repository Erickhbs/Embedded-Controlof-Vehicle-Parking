import 'dart:async';
import 'package:flutter/material.dart';
import './models/models.dart';
import 'mqtt_repo.dart';

class ParkingViewModel extends ChangeNotifier {
  final MqttRepository _repository;

  List<Vaga> vagas = [];
  List<Catraca> catracas = [];
  int vagasDisponiveis = 0;
  bool isLoading = true;

  late StreamSubscription _vagasSubscription;
  late StreamSubscription _catracasSubscription;
  late StreamSubscription _disponiveisSubscription;

  ParkingViewModel(this._repository) {
    _init();
  }

  Future<void> _init() async {
    await _repository.conectar();
    
    _vagasSubscription = _repository.vagasStream.listen((entities) {
      vagas = entities.map((e) => Vaga.fromEntity(e)).toList();
      _updateLoading();
    });

    _catracasSubscription = _repository.catracasStream.listen((entities) {
      catracas = entities.map((e) => Catraca.fromEntity(e)).toList();
      _updateLoading();
    });
    
    _disponiveisSubscription = _repository.vagasDisponiveisStream.listen((disponiveis) {
      vagasDisponiveis = disponiveis;
      _updateLoading();
    });
  }
  
  void _updateLoading() {
      if (isLoading && vagas.isNotEmpty) {
        isLoading = false;
      }
      notifyListeners();
  }
  
  // Retorna a vaga reservada atualmente, ou null se não houver nenhuma
  Vaga? get vagaReservada {
    try {
      return vagas.firstWhere((vaga) => vaga.reservada == true);
    } catch (e) {
      return null;
    }
  }

  void fazerReserva(String vagaId) {
    _repository.reservarVaga(vagaId, true);
    print('Tentando reservar a vaga: $vagaId');
  }

  void cancelarReserva(String vagaId) {
    _repository.cancelarReserva(vagaId, false);
    print('Tentando cancelar a reservar na vaga: $vagaId');
  }

  void solicitarAberturaCatraca(String catracaId) {
    _repository.abrirCatraca(catracaId);
    print('Solicitando abertura da catraca: $catracaId');
  }

  @override
  void dispose() {
    _vagasSubscription.cancel();
    _catracasSubscription.cancel();
    _disponiveisSubscription.cancel();
    _repository.dispose();
    super.dispose();
  }
}
