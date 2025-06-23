class CatracaEntity {
  final String id;
  final String role;
  final double? x;
  final double? y;

  CatracaEntity({
    required this.id,
    required this.role,
    required this.x,
    required this.y,
  });

   Map<String, Object> toDocument(){
    return {
      'id': id,
      'role': role,
      'x': x ?? 0,
      'y': y ?? 0
    };
  }

  static CatracaEntity fromDocument(Map<String, dynamic> doc){
    return CatracaEntity(
      id: doc['id'],
      role: doc['role'],
      x: doc['x'],
      y: doc['y']
    );
  }
}