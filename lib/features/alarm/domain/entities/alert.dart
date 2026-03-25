import 'package:equatable/equatable.dart';

enum TipoEmergencia { roboVia, roboCasa, secuestro, asesinato, sospechoso }

class Alerta extends Equatable {
  final String id;
  final String usuarioId;
  final String? usuarioNombre;
  final String barrioId;
  final TipoEmergencia tipoEmergencia;
  final String? descripcion;
  final String? lugar;
  final String? quePaso;
  final double? latitud;
  final double? longitud;
  final String? imagenUrl;
  final bool active;
  final DateTime creadoEn;

  const Alerta({
    required this.id,
    required this.usuarioId,
    this.usuarioNombre,
    required this.barrioId,
    required this.tipoEmergencia,
    this.descripcion,
    this.lugar,
    this.quePaso,
    this.latitud,
    this.longitud,
    this.imagenUrl,
    this.active = true,
    required this.creadoEn,
  });

  Alerta copyWith({
    String? id,
    String? usuarioId,
    String? usuarioNombre,
    String? barrioId,
    TipoEmergencia? tipoEmergencia,
    String? descripcion,
    String? lugar,
    String? quePaso,
    double? latitud,
    double? longitud,
    String? imagenUrl,
    bool? active,
    DateTime? creadoEn,
  }) {
    return Alerta(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      barrioId: barrioId ?? this.barrioId,
      tipoEmergencia: tipoEmergencia ?? this.tipoEmergencia,
      descripcion: descripcion ?? this.descripcion,
      lugar: lugar ?? this.lugar,
      quePaso: quePaso ?? this.quePaso,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      active: active ?? this.active,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  List<Object?> get props => [
    id,
    usuarioId,
    usuarioNombre,
    barrioId,
    tipoEmergencia,
    descripcion,
    lugar,
    quePaso,
    latitud,
    longitud,
    imagenUrl,
    active,
    creadoEn,
  ];
}
