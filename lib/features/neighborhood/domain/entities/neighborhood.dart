import 'package:equatable/equatable.dart';

class Barrio extends Equatable {
  final String id;
  final String nombre;
  final String ciudadId;
  final String? ciudadNombre;
  final String? whatsappUrl;
  final String? supervisorId;
  final String? presidenteId;

  const Barrio({
    required this.id,
    required this.nombre,
    required this.ciudadId,
    this.ciudadNombre,
    this.whatsappUrl,
    this.supervisorId,
    this.presidenteId,
  });

  @override
  List<Object?> get props => [id, nombre, ciudadId, ciudadNombre, whatsappUrl, supervisorId, presidenteId];
}
