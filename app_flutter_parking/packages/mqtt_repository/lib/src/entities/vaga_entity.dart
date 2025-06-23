class VagaEntity {
  String? id;
  bool? ocupada;
  bool? reservada;
  List<double>? coordenadas;

  VagaEntity({
    required this.id,
    required this.ocupada,
    required this.reservada,
    this.coordenadas
  });

  Map<String, Object> toDocument(){
    return {
      'id': id!,
      'ocupada': ocupada!,
      'reservada': reservada!,
      'coordenada': coordenadas!
    };
  }

  static VagaEntity fromDocument(Map<String, dynamic> doc){
    return VagaEntity(
      id: doc['id'],
      ocupada: doc['ocupada'],
      reservada: doc['reservada'],
      coordenadas: doc['coordenada']
    );
  }
}

