import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../auth/data/models/user_model.dart';

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
      throw sb.PostgrestException(message: 'Error al obtener usuarios pendientes: $e');
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
      throw sb.PostgrestException(message: 'Error al obtener usuarios del barrio: $e');
    }
  }

  /// Actualiza el estado de aprobación de un usuario.
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _client
          .from('perfiles')
          .update({'estado_aprobacion': status})
          .eq('id', userId);
    } catch (e) {
      throw sb.PostgrestException(message: 'Error al actualizar estado del usuario: $e');
    }
  }
}
