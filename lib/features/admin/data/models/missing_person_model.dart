import 'package:equatable/equatable.dart';

class MissingPersonModel extends Equatable {
  final String id;
  final String nombre;
  final String contacto;
  final String lugar;
  final DateTime fecha;
  final String? descripcion;
  final bool activoEstado;
  final String? imagenUrl;
  final DateTime createdAt;
  final String? usuarioId;
  final String? usuarioNombre;
  final String? creatorBarrioId;

  final int? edad;
  final String? sexo;
  final DateTime? fechaDesaparicion;
  final String? ubicacion;
  final String? ultimoLugarVisto;
  final String? ciudadBarrio;
  final String? estaturaAproximada;
  final String? contextura;
  final String? colorPiel;
  final String? colorCabello;
  final String? tipoCabello;
  final String? colorOjos;
  final String? tatuajes;
  final String? cicatrices;
  final bool? usoLentes;
  final String? vestimentaSuperior;
  final String? vestimentaInferior;
  final String? zapatos;
  final String? accesorios;

  const MissingPersonModel({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.lugar,
    required this.fecha,
    this.descripcion,
    required this.activoEstado,
    this.imagenUrl,
    required this.createdAt,
    this.usuarioId,
    this.usuarioNombre,
    this.creatorBarrioId,
    this.edad,
    this.sexo,
    this.fechaDesaparicion,
    this.ubicacion,
    this.ultimoLugarVisto,
    this.ciudadBarrio,
    this.estaturaAproximada,
    this.contextura,
    this.colorPiel,
    this.colorCabello,
    this.tipoCabello,
    this.colorOjos,
    this.tatuajes,
    this.cicatrices,
    this.usoLentes,
    this.vestimentaSuperior,
    this.vestimentaInferior,
    this.zapatos,
    this.accesorios,
  });

  factory MissingPersonModel.fromJson(Map<String, dynamic> json) {
    return MissingPersonModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      contacto: json['contacto'] ?? '',
      lugar: json['lugar'] ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
      descripcion: json['descripcion'] as String?,
      activoEstado: json['activo_estado'] as bool? ?? true,
      imagenUrl: json['imagen_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      usuarioId: json['usuario_id'] as String?,
      usuarioNombre: json['perfiles'] != null 
          ? '${json['perfiles']['nombre'] ?? ''} ${json['perfiles']['apellido'] ?? ''}'.trim()
          : null,
      creatorBarrioId: json['perfiles'] != null ? json['perfiles']['barrio_id'] as String? : null,
      edad: json['edad'] as int?,
      sexo: json['sexo'] as String?,
      fechaDesaparicion: json['fecha_desaparicion'] != null ? DateTime.parse(json['fecha_desaparicion'] as String) : null,
      ubicacion: json['ubicacion'] as String?,
      ultimoLugarVisto: json['ultimo_lugar_visto'] as String?,
      ciudadBarrio: json['ciudad_barrio'] as String?,
      estaturaAproximada: json['estatura_aproximada'] as String?,
      contextura: json['contextura'] as String?,
      colorPiel: json['color_piel'] as String?,
      colorCabello: json['color_cabello'] as String?,
      tipoCabello: json['tipo_cabello'] as String?,
      colorOjos: json['color_ojos'] as String?,
      tatuajes: json['tatuajes'] as String?,
      cicatrices: json['cicatrices'] as String?,
      usoLentes: json['uso_lentes'] as bool?,
      vestimentaSuperior: json['vestimenta_superior'] as String?,
      vestimentaInferior: json['vestimenta_inferior'] as String?,
      zapatos: json['zapatos'] as String?,
      accesorios: json['accesorios'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'contacto': contacto,
      'lugar': lugar,
      'fecha': fecha.toIso8601String().split('T').first,
      'descripcion': descripcion,
      'activo_estado': activoEstado,
      'imagen_url': imagenUrl,
      'created_at': createdAt.toIso8601String(),
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'creator_barrio_id': creatorBarrioId,
      'edad': edad,
      'sexo': sexo,
      'fecha_desaparicion': fechaDesaparicion?.toIso8601String(),
      'ubicacion': ubicacion,
      'ultimo_lugar_visto': ultimoLugarVisto,
      'ciudad_barrio': ciudadBarrio,
      'estatura_aproximada': estaturaAproximada,
      'contextura': contextura,
      'color_piel': colorPiel,
      'color_cabello': colorCabello,
      'tipo_cabello': tipoCabello,
      'color_ojos': colorOjos,
      'tatuajes': tatuajes,
      'cicatrices': cicatrices,
      'uso_lentes': usoLentes,
      'vestimenta_superior': vestimentaSuperior,
      'vestimenta_inferior': vestimentaInferior,
      'zapatos': zapatos,
      'accesorios': accesorios,
    };
  }

  MissingPersonModel copyWith({
    String? id,
    String? nombre,
    String? contacto,
    String? lugar,
    DateTime? fecha,
    String? descripcion,
    bool? activoEstado,
    String? imagenUrl,
    DateTime? createdAt,
    String? usuarioId,
    String? usuarioNombre,
    String? creatorBarrioId,
    int? edad,
    String? sexo,
    DateTime? fechaDesaparicion,
    String? ubicacion,
    String? ultimoLugarVisto,
    String? ciudadBarrio,
    String? estaturaAproximada,
    String? contextura,
    String? colorPiel,
    String? colorCabello,
    String? tipoCabello,
    String? colorOjos,
    String? tatuajes,
    String? cicatrices,
    bool? usoLentes,
    String? vestimentaSuperior,
    String? vestimentaInferior,
    String? zapatos,
    String? accesorios,
  }) {
    return MissingPersonModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      contacto: contacto ?? this.contacto,
      lugar: lugar ?? this.lugar,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      activoEstado: activoEstado ?? this.activoEstado,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      createdAt: createdAt ?? this.createdAt,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      creatorBarrioId: creatorBarrioId ?? this.creatorBarrioId,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      fechaDesaparicion: fechaDesaparicion ?? this.fechaDesaparicion,
      ubicacion: ubicacion ?? this.ubicacion,
      ultimoLugarVisto: ultimoLugarVisto ?? this.ultimoLugarVisto,
      ciudadBarrio: ciudadBarrio ?? this.ciudadBarrio,
      estaturaAproximada: estaturaAproximada ?? this.estaturaAproximada,
      contextura: contextura ?? this.contextura,
      colorPiel: colorPiel ?? this.colorPiel,
      colorCabello: colorCabello ?? this.colorCabello,
      tipoCabello: tipoCabello ?? this.tipoCabello,
      colorOjos: colorOjos ?? this.colorOjos,
      tatuajes: tatuajes ?? this.tatuajes,
      cicatrices: cicatrices ?? this.cicatrices,
      usoLentes: usoLentes ?? this.usoLentes,
      vestimentaSuperior: vestimentaSuperior ?? this.vestimentaSuperior,
      vestimentaInferior: vestimentaInferior ?? this.vestimentaInferior,
      zapatos: zapatos ?? this.zapatos,
      accesorios: accesorios ?? this.accesorios,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        contacto,
        lugar,
        fecha,
        descripcion,
        activoEstado,
        imagenUrl,
        createdAt,
        usuarioId,
        usuarioNombre,
        creatorBarrioId,
        edad,
        sexo,
        fechaDesaparicion,
        ubicacion,
        ultimoLugarVisto,
        ciudadBarrio,
        estaturaAproximada,
        contextura,
        colorPiel,
        colorCabello,
        tipoCabello,
        colorOjos,
        tatuajes,
        cicatrices,
        usoLentes,
        vestimentaSuperior,
        vestimentaInferior,
        zapatos,
        accesorios,
      ];
}
