import '../entities/entities.dart';

class Catraca {
  final String id;
  final String role;
  final double x;
  final double y;

  Catraca({
    required this.id,
    required this.role,
    required this.x,
    required this.y,
  });

  static Catraca fromEntity(CatracaEntity entity){
    return Catraca(
      id: entity.id,
      role: entity.role,
      x: entity.x ?? 0,
      y: entity.y ?? 0
    );
  }

  CatracaEntity toEntity(){
    return CatracaEntity(
      id: id,
      role: role,
      x: x,
      y: y
    );
  }

    @override
  String toString() {
    return 'catraca: $id, $role, $x, $y';
  }

}