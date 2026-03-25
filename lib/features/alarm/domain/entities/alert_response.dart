import 'package:equatable/equatable.dart';

class RespuestaAlerta extends Equatable {
  final String id;
  final String alertaId;
  final String usuarioId;
  final String estado;
  final DateTime creadoEn;
  final String? usuarioNombre;

  const RespuestaAlerta({
    required this.id,
    required this.alertaId,
    required this.usuarioId,
    required this.estado,
    required this.creadoEn,
    this.usuarioNombre,
  });

  @override
  List<Object?> get props => [id, alertaId, usuarioId, estado, creadoEn, usuarioNombre];
}
