import '../../domain/entities/alert_response.dart';

class RespuestaAlertaModel extends RespuestaAlerta {
  const RespuestaAlertaModel({
    required super.id,
    required super.alertaId,
    required super.usuarioId,
    required super.estado,
    required super.creadoEn,
    super.usuarioNombre,
  });

  factory RespuestaAlertaModel.fromJson(Map<String, dynamic> json) {
    String? nombreCompleto;
    if (json['perfiles'] != null) {
      final perfil = json['perfiles'] as Map<String, dynamic>;
      final nombre = perfil['nombre'] as String? ?? '';
      final apellido = perfil['apellido'] as String? ?? '';
      nombreCompleto = '$nombre $apellido'.trim();
      if (nombreCompleto.isEmpty) nombreCompleto = null;
    }

    return RespuestaAlertaModel(
      id: json['id'] as String,
      alertaId: json['alerta_id'] as String,
      usuarioId: json['usuario_id'] as String,
      estado: json['estado'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      usuarioNombre: nombreCompleto,
    );
  }
}
