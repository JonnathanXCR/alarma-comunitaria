import '../../domain/entities/alert.dart';

class AlertaModel extends Alerta {
  const AlertaModel({
    required super.id,
    required super.usuarioId,
    super.usuarioNombre,
    required super.barrioId,
    required super.tipoEmergencia,
    super.descripcion,
    super.lugar,
    super.quePaso,
    super.latitud,
    super.longitud,
    super.imagenUrl,
    super.active = true,
    required super.creadoEn,
  });

  static TipoEmergencia _parseTipoEmergencia(String? value) {
    if (value == null) return TipoEmergencia.roboVia;
    final lower = value.toLowerCase();
    switch (lower) {
      case 'robo':
      case 'robovia':
        return TipoEmergencia.roboVia;
      case 'robocasa':
        return TipoEmergencia.roboCasa;
      case 'secuestro':
        return TipoEmergencia.secuestro;
      case 'asesinato':
        return TipoEmergencia.asesinato;
      case 'sospechoso':
        return TipoEmergencia.sospechoso;
      default:
        return TipoEmergencia.roboVia;
    }
  }

  factory AlertaModel.fromJson(Map<String, dynamic> json) {
    String? nombreCompleto;
    if (json['perfiles'] != null) {
      final perfil = json['perfiles'] as Map<String, dynamic>;
      final nombre = perfil['nombre'] as String? ?? '';
      final apellido = perfil['apellido'] as String? ?? '';
      nombreCompleto = '$nombre $apellido'.trim();
      if (nombreCompleto.isEmpty) nombreCompleto = null;
    }

    return AlertaModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: nombreCompleto,
      barrioId: json['barrio_id'] as String,
      tipoEmergencia: _parseTipoEmergencia(json['tipo_emergencia'] as String?),
      descripcion: json['descripcion'] as String?,
      lugar: json['lugar'] as String?,
      quePaso: json['que_paso'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      imagenUrl: json['imagen_url'] as String?,
      active: json['active'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  /// Crea un AlertaModel a partir de una entidad Alerta.
  factory AlertaModel.fromAlerta(Alerta alerta) {
    return AlertaModel(
      id: alerta.id,
      usuarioId: alerta.usuarioId,
      usuarioNombre: alerta.usuarioNombre,
      barrioId: alerta.barrioId,
      tipoEmergencia: alerta.tipoEmergencia,
      descripcion: alerta.descripcion,
      lugar: alerta.lugar,
      quePaso: alerta.quePaso,
      latitud: alerta.latitud,
      longitud: alerta.longitud,
      imagenUrl: alerta.imagenUrl,
      active: alerta.active,
      creadoEn: alerta.creadoEn,
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
    if (imagenUrl != null) 'imagen_url': imagenUrl,
    'active': active,
  };

  /// Serializa todos los campos para almacenamiento local (incluye usuario_nombre).
  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'usuario_nombre': usuarioNombre,
    'barrio_id': barrioId,
    'tipo_emergencia': tipoEmergencia.name,
    'descripcion': descripcion,
    'lugar': lugar,
    'que_paso': quePaso,
    'latitud': latitud,
    'longitud': longitud,
    'imagen_url': imagenUrl,
    'active': active,
    'creado_en': creadoEn.toIso8601String(),
  };

  /// Deserializa desde el formato de almacenamiento local.
  factory AlertaModel.fromStorageJson(Map<String, dynamic> json) {
    return AlertaModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: json['usuario_nombre'] as String?,
      barrioId: json['barrio_id'] as String,
      tipoEmergencia: _parseTipoEmergencia(json['tipo_emergencia'] as String?),
      descripcion: json['descripcion'] as String?,
      lugar: json['lugar'] as String?,
      quePaso: json['que_paso'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      imagenUrl: json['imagen_url'] as String?,
      active: json['active'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }
}
