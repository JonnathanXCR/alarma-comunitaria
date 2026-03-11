import 'package:equatable/equatable.dart';

enum TipoEmergencia { seguridad, medica, incendio, sospechoso }

class Alerta extends Equatable {
  final String id;
  final String usuarioId;
  final String barrioId;
  final TipoEmergencia tipoEmergencia;
  final String? descripcion;
  final String? lugar;
  final String? quePaso;
  final double? latitud;
  final double? longitud;
  final bool active;
  final DateTime creadoEn;

  const Alerta({
    required this.id,
    required this.usuarioId,
    required this.barrioId,
    required this.tipoEmergencia,
    this.descripcion,
    this.lugar,
    this.quePaso,
    this.latitud,
    this.longitud,
    this.active = true,
    required this.creadoEn,
  });

  @override
  List<Object?> get props => [
    id,
    usuarioId,
    barrioId,
    tipoEmergencia,
    descripcion,
    lugar,
    quePaso,
    latitud,
    longitud,
    active,
    creadoEn,
  ];
}
