import '../entities/entities.dart';

class Vaga {
  String? id;
  bool? ocupada;
  bool? reservada;
  List<double>? coordenadas;

  Vaga({
    required this.id,
    required this.ocupada,
    required this.reservada,
    required this.coordenadas
  });

  static Vaga fromEntity(VagaEntity entity){
    return Vaga(
      id: entity.id,
      ocupada: entity.ocupada,
      reservada: entity.reservada,
      coordenadas: entity.coordenadas
    );
  }

  VagaEntity toEntity(){
    return VagaEntity(
      id: id,
      ocupada: ocupada,
      reservada: reservada,
      coordenadas: coordenadas
    );
  }

    @override
  String toString() {
    return 'Vaga: $id, $ocupada, $reservada, $coordenadas';
  }
}

