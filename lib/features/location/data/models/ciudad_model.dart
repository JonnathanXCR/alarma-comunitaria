import '../../domain/entities/ciudad.dart';
import 'provincia_model.dart';

class CiudadModel extends Ciudad {
  const CiudadModel({
    required super.id,
    required super.nombre,
    required super.provinciaId,
    super.supervisorId,
    super.createdAt,
    super.provincia,
  });

  factory CiudadModel.fromJson(Map<String, dynamic> json) {
    return CiudadModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      provinciaId: json['provincia_id'] as String,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      provincia: json['provincias'] != null ? ProvinciaModel.fromJson(json['provincias']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'nombre': nombre,
      'provincia_id': provinciaId,
    };
    if (supervisorId != null) data['supervisor_id'] = supervisorId;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    return data;
  }
}
