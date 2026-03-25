import '../../domain/entities/neighborhood.dart';

class BarrioModel extends Barrio {
  const BarrioModel({
    required super.id,
    required super.nombre,
    required super.ciudadId,
    super.ciudadNombre,
    super.whatsappUrl,
    super.supervisorId,
    super.presidenteId,
  });

  factory BarrioModel.fromJson(Map<String, dynamic> json) {
    return BarrioModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ciudadId: json['ciudad_id'] as String? ?? '',
      ciudadNombre: json['ciudades'] != null ? json['ciudades']['nombre'] as String? : null,
      whatsappUrl: json['whatsapp_url'] as String?,
      supervisorId: json['supervisor_id'] as String?,
      presidenteId: json['presidente_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'ciudad_id': ciudadId,
    'whatsapp_url': whatsappUrl,
    if (supervisorId != null) 'supervisor_id': supervisorId,
    if (presidenteId != null) 'presidente_id': presidenteId,
  };
}
