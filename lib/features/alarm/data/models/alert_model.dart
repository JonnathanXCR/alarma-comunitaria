import '../../domain/entities/alert.dart';

class AlertaModel extends Alerta {
  const AlertaModel({
    required super.id,
    required super.usuarioId,
    required super.barrioId,
    required super.tipoEmergencia,
    super.descripcion,
    super.lugar,
    super.quePaso,
    super.latitud,
    super.longitud,
    super.active = true,
    required super.creadoEn,
  });

  factory AlertaModel.fromJson(Map<String, dynamic> json) {
    return AlertaModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      barrioId: json['barrio_id'] as String,
      tipoEmergencia: TipoEmergencia.values.firstWhere(
        (e) => e.name == (json['tipo_emergencia'] as String).toLowerCase(),
        orElse: () => TipoEmergencia.seguridad,
      ),
      descripcion: json['descripcion'] as String?,
      lugar: json['lugar'] as String?,
      quePaso: json['que_paso'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': usuarioId,
    'barrio_id': barrioId,
    'tipo_emergencia': tipoEmergencia.name,
    if (descripcion != null) 'descripcion': descripcion,
    if (lugar != null) 'lugar': lugar,
    if (quePaso != null) 'que_paso': quePaso,
    if (latitud != null) 'latitud': latitud,
    if (longitud != null) 'longitud': longitud,
    'active': active,
  };
}
