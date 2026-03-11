import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/user.dart';
import '../models/user_model.dart';

class AuthRepository {
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  // ──────────────────────────────────────────────
  // Auth
  // ──────────────────────────────────────────────

  /// Login con email y contraseña usando Supabase Auth.
  /// Después carga el perfil desde la tabla `perfiles`.
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('==== SUPABASE LOGIN RESPONSE ====');
      print('Session: ${response.session?.toJson()}');
      print('User: ${response.user?.toJson()}');
      print('=================================');

      if (response.user == null) {
        throw const sb.AuthException('Credenciales inválidas');
      }

      try {
        final perfil = await getPerfil(response.user!.id);
        print('==== SUPABASE PERFIL ====');
        print('Perfil: $perfil');
        print('=========================');
        return perfil;
      } catch (e) {
        print('==== SUPABASE GET PERFIL ERROR ====');
        print(e.toString());
        print('===================================');
        // Si ocurre un PostgrestException (por ejemplo no hay perfil), reportarlo bien
        if (e is sb.PostgrestException && e.code == 'PGRST116') {
          throw const sb.AuthException(
            'Tu perfil está incompleto o dañado. Por favor, crea una nueva cuenta o contacta al administrador.',
          );
        }
        throw sb.AuthException('Error al cargar perfil: $e');
      }
    } catch (e) {
      print('==== SUPABASE LOGIN ERROR ====');
      print(e.toString());
      if (e is sb.AuthException) {
        print('StatusCode: ${e.statusCode}');
        print('Message: ${e.message}');
      }
      print('==============================');
      rethrow;
    }
  }

  /// Registra un nuevo usuario con Supabase Auth y crea su perfil vía Trigger.
  /// Si se requiere confirmación por email, retorna `null`.
  Future<User?> register({
    required String email,
    required String password,
    required String cedula,
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
    String? barrioId,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'direccion': direccion,
        'telefono': telefono,
        'barrio_id': barrioId ?? '',
      },
      emailRedirectTo: 'io.supabase.alarma://login-callback/',
    );

    if (response.user == null) {
      throw const sb.AuthException(
        'No se pudo crear la cuenta. Inténtalo de nuevo.',
      );
    }

    if (response.session == null) {
      // Significa que se envió un correo de confirmación.
      // El perfil ya se creó en DB vía Trigger, pero no podemos leerlo por RLS.
      return null;
    }

    // Si auto-confirm está habilitado y hay sesión
    return getPerfil(response.user!.id);
  }

  /// Cierra la sesión del usuario actual.
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Devuelve el perfil del usuario en sesión, o null si no hay sesión.
  Future<User?> getStoredSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    try {
      return await getPerfil(session.user.id);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // Perfil
  // ──────────────────────────────────────────────

  /// Obtiene el perfil de `perfiles` por [userId].
  Future<User> getPerfil(String userId) async {
    final data = await _client
        .from('perfiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }

  /// Crea el perfil en la tabla `perfiles` tras el registro.
  Future<User> createPerfil({
    required String userId,
    required String cedula,
    required String nombre,
    required String apellido,
    required String direccion,
    required String telefono,
    String? barrioId,
  }) async {
    final payload = {
      'id': userId,
      'cedula': cedula,
      'nombre': nombre,
      'apellido': apellido,
      'direccion': direccion,
      'telefono': telefono,
      if (barrioId != null) 'barrio_id': barrioId,
    };

    await _client.from('perfiles').insert(payload);
    return getPerfil(userId);
  }

  /// Actualiza el FCM token del perfil (para notificaciones push).
  Future<void> updateFcmToken(String userId, String token) async {
    await _client
        .from('perfiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }
}
