import '../../domain/entities/neighborhood.dart';

class BarrioModel extends Barrio {
  const BarrioModel({
    required super.id,
    required super.nombre,
    required super.ciudad,
  });

  factory BarrioModel.fromJson(Map<String, dynamic> json) {
    return BarrioModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ciudad: json['ciudad'] as String? ?? 'Cuenca',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'ciudad': ciudad,
  };
}
