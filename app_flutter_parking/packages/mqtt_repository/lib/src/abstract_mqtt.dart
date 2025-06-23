import './entities/vaga_entity.dart';
import './entities/catraca_entity.dart';

abstract class AbstractMqttRepository {

  Stream<List<VagaEntity>> get vagasStream;
  Stream<List<CatracaEntity>> get catracasStream;
  Stream<int> get vagasDisponiveisStream;

  Future<void> conectar();
  
  void reservarVaga(String id, bool estado);

  void cancelarReserva(String id, bool estado);

  void abrirCatraca(String id);
  
  void dispose();
}