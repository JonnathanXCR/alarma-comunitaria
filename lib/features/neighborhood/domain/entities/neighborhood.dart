import 'package:equatable/equatable.dart';

class Barrio extends Equatable {
  final String id;
  final String nombre;
  final String ciudad;

  const Barrio({required this.id, required this.nombre, required this.ciudad});

  @override
  List<Object?> get props => [id, nombre, ciudad];
}
