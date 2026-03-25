import '../../domain/entities/provincia.dart';

class ProvinciaModel extends Provincia {
  const ProvinciaModel({
    required super.id,
    required super.nombre,
    super.supervisorId,
    super.createdAt,
  });

  factory ProvinciaModel.fromJson(Map<String, dynamic> json) {
    return ProvinciaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'nombre': nombre,
    };
    if (supervisorId != null) data['supervisor_id'] = supervisorId;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    return data;
  }
}
