import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.cedula,
    required super.nombre,
    required super.apellido,
    required super.direccion,
    required super.telefono,
    super.barrioId,
    super.barrioNombre,
    super.rol,
    super.estadoAprobacion,
  });

  /// Construye un [UserModel] a partir de la respuesta de la tabla `perfiles`.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      cedula: json['cedula'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      direccion: json['direccion'] as String,
      telefono: json['telefono'] as String,
      barrioId: json['barrio_id'] as String?,
      barrioNombre: (json['barrios'] as Map<String, dynamic>?)?['nombre'] as String?,
      rol: json['rol'] as String? ?? 'vecino',
      estadoAprobacion: json['estado_aprobacion'] as String? ?? 'pendiente',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cedula': cedula,
    'nombre': nombre,
    'apellido': apellido,
    'direccion': direccion,
    'telefono': telefono,
    if (barrioId != null) 'barrio_id': barrioId,
    'rol': rol,
    'estado_aprobacion': estadoAprobacion,
  };
}
