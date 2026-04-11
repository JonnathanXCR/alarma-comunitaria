import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/websocket_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _successMessage;
  /// Indica si los permisos de notificación fueron otorgados.
  bool _notificationsEnabled = false;
  /// Indica que el token FCM no pudo guardarse en Supabase (fallo de red/DB).
  bool _notificationsMisconfigured = false;
  /// Indica si ya se verificó/solicitó el permiso durante esta sesión.
  bool _hasCheckedNotifications = false;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _listenAuthChanges();
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  /// `true` si el sistema operativo otorgó permisos de notificación.
  bool get notificationsEnabled => _notificationsEnabled;
  /// `true` si ocurrió un error al guardar el token FCM tras el login.
  /// La UI puede usar este flag para mostrar un banner de advertencia.
  bool get notificationsMisconfigured => _notificationsMisconfigured;
  /// `true` si ya se terminó de verificar/solicitar el permiso en [_initPushNotifications].
  bool get hasCheckedNotifications => _hasCheckedNotifications;

  // ──────────────────────────────────────────────
  // Listener de cambios de sesión de Supabase
  // ──────────────────────────────────────────────

  /// Escucha eventos de autenticación de Supabase para mantener
  /// la sesión sincronizada: auto-restore, token refresh, sign out, etc.
  void _listenAuthChanges() {
    final client = Supabase.instance.client;
    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      switch (event) {
        // Sesión restaurada al abrir la app o token refrescado
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          if (session != null) {
            await _loadUserProfile(session.user.id);
          } else {
            _setUnauthenticated();
          }
          break;

        // Login exitoso (también cubre signUp con auto-confirm)
        case AuthChangeEvent.signedIn:
          if (session != null && _status != AuthStatus.authenticated) {
            await _loadUserProfile(session.user.id);
          }
          break;

        // Sesión cerrada (por el usuario o desde el servidor)
        case AuthChangeEvent.signedOut:
          _setUnauthenticated();
          RealtimeService.instance.disconnect();
          break;

        // Otros eventos (passwordRecovery, userUpdated, mfaChallenge, etc.)
        default:
          break;
      }
    });
  }

  /// Carga el perfil del usuario y establece el estado como autenticado.
  ///
  /// El guardado del token FCM es un paso secundario: si falla, el usuario
  /// permanece autenticado pero [notificationsMisconfigured] se marca
  /// como `true` para que la UI pueda mostrar un aviso.
  Future<void> _loadUserProfile(String userId) async {
    try {
      _user = await _repository.getPerfil(userId);
      _status = AuthStatus.authenticated;
      _connectRealtime();
    } catch (_) {
      // Si no se puede cargar el perfil, tratamos como no autenticado.
      _setUnauthenticated();
      notifyListeners();
      return;
    }

    // El guardado del token FCM es independiente del login.
    // Si falla, el usuario sigue autenticado pero se avisa via flag.
    await _initPushNotifications();

    notifyListeners();
  }

  Future<void> _initPushNotifications() async {
    if (_user?.isAprobado != true) return;

    try {
      final granted = await PushNotificationService.requestPermissionAndSaveToken();
      _notificationsEnabled = granted;
      _notificationsMisconfigured = false;

      if (granted && _user?.barrioId != null) {
        await PushNotificationService.subscribeToBarrio(_user!.barrioId!);
      }
    } catch (e) {
      _notificationsMisconfigured = true;
      if (kDebugMode) {
        print('[Auth] Advertencia: no se pudo guardar el FCM token: $e');
      }
    } finally {
      _hasCheckedNotifications = true;
      notifyListeners();
    }
  }

  void _setUnauthenticated() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Auto-login
  // ──────────────────────────────────────────────

  /// Intenta recuperar la sesión guardada al iniciar la app.
  /// Supabase restaura la sesión automáticamente; este método
  /// espera a que esté disponible y carga el perfil.
  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Espera a que Supabase restaure la sesión desde el almacenamiento local.
    // Si ya se restauró vía el listener, simplemente verificamos.
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Login / Logout
  // ──────────────────────────────────────────────

  /// Inicia sesión con email y contraseña.
  Future<void> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _user = await _repository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      await _initPushNotifications();
      _connectRealtime();
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      print('AuthException in login: ${e.message}');
    } catch (e, st) {
      _status = AuthStatus.error;
      _errorMessage = 'Error inesperado. Intenta de nuevo.';
      print('Unexpected error in login: $e');
      print('Stacktrace: $st');
    }
    notifyListeners();
  }

  /// Registra un nuevo usuario con email/contraseña y crea su perfil.
  Future<void> register({
    required String email,
    required String password,
    required String cedula,
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
    String? barrioId,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await _repository.register(
        email: email,
        password: password,
        cedula: cedula,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        direccion: direccion,
        barrioId: barrioId,
      );

      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _successMessage =
            'Registro exitoso. Revisa tu correo electrónico para obtener el código de verificación e ingrésalo a continuación.';
      } else {
        _user = user;
        _status = AuthStatus.authenticated;
        await _initPushNotifications();
        _connectRealtime();
      }
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Error inesperado. Intenta de nuevo.';
    }
    notifyListeners();
  }

  /// Actualiza el perfil del usuario autenticado.
  Future<void> updateProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
    String? barrioId,
  }) async {
    if (_user == null) return;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final oldBarrioId = _user!.barrioId;

      final updatedUser = await _repository.updateProfile(
        userId: _user!.id,
        nombre: nombre,
        apellido: apellido,
        direccion: direccion,
        telefono: telefono,
        barrioId: barrioId,
      );

      _user = updatedUser;

      // Reconectar WS y actualizar topic FCM si el barrio cambió
      if (barrioId != null && barrioId != oldBarrioId) {
        RealtimeService.instance.disconnect();
        _connectRealtime();

        if (oldBarrioId != null) {
          await PushNotificationService.unsubscribeFromBarrio(oldBarrioId);
        }
        await PushNotificationService.subscribeToBarrio(barrioId);
      }

      // El usuario ahora está pendiente de aprobación, así que el HomePage
      // y el router se encargarán de enviarlo a PendingApprovalPage
      _successMessage = 'Perfil actualizado. Pendiente de aprobación.';
      _status = AuthStatus
          .authenticated; // Mantener como autenticado para que HomePage pueda redirigir
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage =
          'Error inesperado al actualizar perfil. Intenta de nuevo.';
    }
    notifyListeners();
  }

  /// Verifica el OTP de registro.
  Future<bool> verifyOTP(String email, String otp) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await _repository.verifyOTP(email: email, token: otp);
      if (user != null) {
        await _loadUserProfile(user.id);
        return true;
      }
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error al verificar el código. Intenta de nuevo.';
    }
    notifyListeners();
    return false;
  }

  /// Limpia los mensajes de error/éxito (usado por la UI).
  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Reenvía el código OTP de registro.
  Future<void> resendOTP(String email) async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      print('Error resending OTP: $e');
    }
  }

  /// Cierra sesión, desconecta Realtime y limpia el estado.
  Future<void> logout() async {
    final oldBarrioId = _user?.barrioId;
    if (oldBarrioId != null) {
      await PushNotificationService.unsubscribeFromBarrio(oldBarrioId);
    }

    RealtimeService.instance.disconnect();
    await _repository.logout();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_fcm_token');
    } catch (_) {}

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  void _connectRealtime() {
    final barrioId = _user?.barrioId;
    if (barrioId == null) return;
    RealtimeService.instance.connect(barrioId: barrioId);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
