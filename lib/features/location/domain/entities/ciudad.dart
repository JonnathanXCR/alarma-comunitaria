import 'package:equatable/equatable.dart';
import 'provincia.dart';

class Ciudad extends Equatable {
  final String id;
  final String nombre;
  final String provinciaId;
  final String? supervisorId;
  final DateTime? createdAt;
  final Provincia? provincia; // For relations

  const Ciudad({
    required this.id,
    required this.nombre,
    required this.provinciaId,
    this.supervisorId,
    this.createdAt,
    this.provincia,
  });

  @override
  List<Object?> get props => [id, nombre, provinciaId, supervisorId, createdAt, provincia];
}
