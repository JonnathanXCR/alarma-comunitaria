import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String cedula;
  final String nombre;
  final String apellido;
  final String direccion;
  final String telefono;
  final String? barrioId;
  final String? barrioNombre;
  final String rol; // 'vecino' | 'supervisor' | 'admin'
  final String estadoAprobacion; // 'pendiente' | 'aprobado' | 'rechazado'

  const User({
    required this.id,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.telefono,
    this.barrioId,
    this.barrioNombre,
    this.rol = 'vecino',
    this.estadoAprobacion = 'pendiente',
  });

  String get nombreCompleto => '$nombre $apellido';

  bool get isAprobado => estadoAprobacion == 'aprobado';

  @override
  List<Object?> get props => [
    id,
    cedula,
    nombre,
    apellido,
    direccion,
    telefono,
    barrioId,
    barrioNombre,
    rol,
    estadoAprobacion,
  ];
}
