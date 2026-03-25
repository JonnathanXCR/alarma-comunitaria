import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../auth/data/models/user_model.dart';
import '../models/missing_person_model.dart';

class AdminRepository {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  /// Obtiene los usuarios pendientes de un barrio específico.
  Future<List<UserModel>> getPendingUsers(String barrioId) async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('estado_aprobacion', 'pendiente')
          .eq('barrio_id', barrioId);

      return (response as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al obtener usuarios pendientes: $e',
      );
    }
  }

  /// Obtiene todos los usuarios de un barrio específico.
  Future<List<UserModel>> getUsersByBarrio(String barrioId) async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('barrio_id', barrioId);

      return (response as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al obtener usuarios del barrio: $e',
      );
    }
  }

  /// Obtiene todos los usuarios pendientes de cualquier barrio (solo Admin).
  Future<List<UserModel>> getAllPendingUsers() async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .eq('estado_aprobacion', 'pendiente');

      return (response as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al obtener todos los usuarios pendientes: $e',
      );
    }
  }

  /// Obtiene todos los usuarios de cualquier barrio (solo Admin).
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client
          .from('perfiles')
          .select();

      return (response as List<dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al obtener todos los usuarios: $e',
      );
    }
  }

  /// Actualiza el estado de aprobación de un usuario.
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      final response = await _client
          .from('perfiles')
          .update({'estado_aprobacion': status})
          .eq('id', userId)
          .select();

      if (response.isEmpty) {
        throw sb.PostgrestException(
          message:
              'No se pudo actualizar el usuario. Verifica los permisos de RLS.',
        );
      }
    } catch (e) {
      if (e is sb.PostgrestException) rethrow;
      throw sb.PostgrestException(
        message: 'Error al actualizar estado del usuario: $e',
      );
    }
  }

  // --- PERSONAS DESAPARECIDAS ---

  /// Obtiene la lista de personas desaparecidas (activas e inactivas).
  Future<List<MissingPersonModel>> getMissingPersons() async {
    try {
      final response = await _client
          .from('personas_desaparecidas')
          .select('*, perfiles(nombre, apellido, barrio_id)')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => MissingPersonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al obtener personas desaparecidas: $e',
      );
    }
  }

  /// Agrega un nuevo reporte de persona desaparecida.
  Future<MissingPersonModel> addMissingPerson({
    required String nombre,
    required String contacto,
    required String lugar,
    required DateTime fecha,
    String? descripcion,
    String? imagenUrl,
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
  }) async {
    try {
      final response = await _client
          .from('personas_desaparecidas')
          .insert({
            'nombre': nombre,
            'contacto': contacto,
            'lugar': lugar,
            'fecha': fecha.toIso8601String().split('T').first,
            'descripcion': descripcion,
            'activo_estado': true,
            'imagen_url': imagenUrl,
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
            'usuario_id': _client.auth.currentUser?.id,
          })
          .select()
          .single();

      return MissingPersonModel.fromJson(response);
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al agregar persona desaparecida: $e',
      );
    }
  }

  /// Actualiza los datos de una persona desaparecida existente.
  Future<MissingPersonModel> updateMissingPerson({
    required String id,
    required String nombre,
    required String contacto,
    required String lugar,
    required DateTime fecha,
    String? descripcion,
    String? imagenUrl,
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
  }) async {
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        'contacto': contacto,
        'lugar': lugar,
        'fecha': fecha.toIso8601String().split('T').first,
        'descripcion': descripcion,
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

      if (imagenUrl != null) {
        data['imagen_url'] = imagenUrl;
      }

      final response = await _client
          .from('personas_desaparecidas')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return MissingPersonModel.fromJson(response);
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al actualizar persona desaparecida: $e',
      );
    }
  }

  /// Actualiza el estado (activo/inactivo) de una persona desaparecida.
  Future<void> updateMissingPersonStatus(String id, bool isActive) async {
    try {
      await _client
          .from('personas_desaparecidas')
          .update({'activo_estado': isActive})
          .eq('id', id);
    } catch (e) {
      throw sb.PostgrestException(
        message: 'Error al actualizar estado de la persona desaparecida: $e',
      );
    }
  }

  /// Sube una imagen al bucket de Supabase Storage.
  Future<String?> uploadMissingPersonImage(String fileName, dynamic fileBytes) async {
    try {
      // fileBytes puede ser un File o Uint8List
      // Usaremos desde Flutter image_picker
      final path = 'casos/$fileName';
      
      // Necesita File, si usas web, hay que usar uploadBinary
      await _client.storage.from('imagenes_personas').upload(path, fileBytes);
      
      final imageUrl = _client.storage.from('imagenes_personas').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      // Ignoramos el fallo y retornamos nulo o manejamos el error
      return null;
    }
  }
}
