import 'package:equatable/equatable.dart';

class Provincia extends Equatable {
  final String id;
  final String nombre;
  final String? supervisorId;
  final DateTime? createdAt;

  const Provincia({
    required this.id,
    required this.nombre,
    this.supervisorId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, nombre, supervisorId, createdAt];
}
