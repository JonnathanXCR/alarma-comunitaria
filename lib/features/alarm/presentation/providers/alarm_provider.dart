import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/network/websocket_service.dart';
import '../../../../core/services/local_alert_cache.dart';
import '../../data/models/alert_model.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/globals.dart';

class AlarmProvider extends ChangeNotifier {
  final AlarmRepository _repository;
  final AuthProvider _authProvider;
  final LocalAlertCache _cache = LocalAlertCache.instance;

  Alerta? _activeAlert;
  List<Alerta> _history = [];
  List<RespuestaAlerta> _alertResponses = [];
  bool _isSending = false;
  String? _error;

  // Rastrear qué alertas han sido recibidas localmente para cambiar estado de botón
  final Set<String> _receivedAlertIds = {};

  // Timer de polling (solo activo cuando hay alerta activa)
  Timer? _pollingTimer;
  static const _pollingInterval = Duration(minutes: 3);

  bool _isInitialized = false;

  AlarmProvider({
    required AuthProvider authProvider,
    AlarmRepository? repository,
  }) : _authProvider = authProvider,
       _repository = repository ?? AlarmRepository() {
    // Escuchar eventos Realtime de nuevas alertas
    RealtimeService.instance.addListener(_onRealtimeEvent);
  }

  Alerta? get activeAlert => _activeAlert;
  List<Alerta> get history => List.unmodifiable(_history);
  List<RespuestaAlerta> get alertResponses =>
      List.unmodifiable(_alertResponses);
  bool get isSending => _isSending;
  bool get hasActiveAlert => _activeAlert != null;
  String? get error => _error;

  /// Verifica si la alerta dada ya fue marcada como recibida
  bool isAlertReceived(String id) => _receivedAlertIds.contains(id);

  @override
  void dispose() {
    RealtimeService.instance.removeListener(_onRealtimeEvent);
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Inicialización: caché local + sync con Supabase
  // ──────────────────────────────────────────────

  /// Debe llamarse después de la autenticación exitosa.
  /// 1. Carga la alerta desde caché local (instantáneo, 0 requests)
  /// 2. Valida con Supabase si sigue activa (1 request)
  /// 3. Inicia polling si hay alerta activa
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Paso 1: cargar desde caché local
    final cachedAlert = await _cache.loadAlert();
    if (cachedAlert != null) {
      _activeAlert = cachedAlert;
      globalHasActiveAlert.value = true;
      notifyListeners();
    }

    // Paso 2: sincronizar con Supabase
    await _syncWithSupabase();
  }

  /// Sincroniza el estado de la alerta activa con Supabase.
  /// - Si hay alerta activa en el servidor, la actualiza localmente
  /// - Si ya no hay, limpia el caché
  Future<void> _syncWithSupabase() async {
    final user = _authProvider.user;
    if (user == null || user.barrioId == null) return;

    try {
      final serverAlert = await _repository.getActiveAlert(
        barrioId: user.barrioId!,
      );

      if (serverAlert != null) {
        _activeAlert = serverAlert;
        globalHasActiveAlert.value = true;
        await _cache.saveAlert(serverAlert);
        await _loadAlertResponses(serverAlert.id);
        _startPolling();
      } else {
        // No hay alerta activa en el servidor
        _activeAlert = null;
        globalHasActiveAlert.value = false;
        await _cache.clearAlert();
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      print('Error syncing alert with Supabase: $e');
      // Si falla la sincronización, mantenemos lo del caché
    }
  }

  // ──────────────────────────────────────────────
  //  Polling (solo mientras hay alerta activa)
  // ──────────────────────────────────────────────

  void _startPolling() {
    _stopPolling(); // Evitar duplicados
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _syncWithSupabase();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ──────────────────────────────────────────────
  //  Enviar alerta
  // ──────────────────────────────────────────────

  /// Dispara una alerta de emergencia.
  Future<void> sendEmergencyAlert({
    required TipoEmergencia tipo,
    String? descripcion,
    String? lugar,
    String? quePaso,
    double? latitud,
    double? longitud,
    File? imageFile,
  }) async {
    final user = _authProvider.user;
    if (user == null || user.barrioId == null) return;

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final alerta = await _repository.sendAlert(
        barrioId: user.barrioId!,
        tipo: tipo,
        descripcion: descripcion,
        lugar: lugar,
        quePaso: quePaso,
        latitud: latitud,
        longitud: longitud,
        imageFile: imageFile,
      );
      _activeAlert = alerta;
      globalHasActiveAlert.value = true;
      await _cache.saveAlert(alerta);
      _startPolling();
    } catch (e, st) {
      print('================= ERROR EN SEND ALERT =================');
      print(e);
      print(st);
      print('=======================================================');
      _error = e.toString();
    }

    _isSending = false;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  //  Historial
  // ──────────────────────────────────────────────

  /// Carga el historial de alertas del barrio.
  Future<void> loadHistory() async {
    final user = _authProvider.user;
    if (user == null || user.barrioId == null) return;
    try {
      _history = await _repository.getAlertHistory(barrioId: user.barrioId!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  //  Acciones sobre alertas
  // ──────────────────────────────────────────────

  /// Marca la alerta activa como resuelta y limpia el caché.
  Future<void> resolveCurrentAlert() async {
    _activeAlert = null;
    globalHasActiveAlert.value = false;
    await _cache.clearAlert();
    _stopPolling();
    notifyListeners();
  }

  /// Registra en la base de datos que la alerta fue recibida.
  Future<void> markAlertAsReceived(String alertaId) async {
    if (_receivedAlertIds.contains(alertaId)) return; // Ya se envió antes

    _receivedAlertIds.add(alertaId);

    // Detener sonido de la alarma si está sonando
    PushNotificationService.cancelAllNotifications();

    notifyListeners();

    try {
      await _repository.changeAlertState(
        alertaId: alertaId,
        estado: 'RECIBIDA',
      );
      // Recargar respuestas después de insertar la nuestra
      await _loadAlertResponses(alertaId);
    } catch (e) {
      print('Error marking alert as received: $e');
    }
  }

  /// Desactiva una alerta en curso (solo admin, supervisor o presidente)
  Future<void> deactivateAlert(String alertaId) async {
    try {
      await _repository.deactivateAlert(alertaId: alertaId);
      if (_activeAlert?.id == alertaId) {
        await resolveCurrentAlert();
      }
    } catch (e) {
      print('Error deactivating alert: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  Realtime handler
  // ──────────────────────────────────────────────

  void _onRealtimeEvent(WsEvent event) async {
    if (event.type == WsEventType.alertaNueva) {
      final alertaModel = AlertaModel.fromJson(event.payload);

      // Doble validación de seguridad: asegurar que la alerta es del barrio del usuario
      final userBarrioId = _authProvider.user?.barrioId;
      if (userBarrioId == null || alertaModel.barrioId != userBarrioId) {
        return;
      }

      Alerta alerta = alertaModel;

      // Intentar cargar el nombre si no viene en el payload (Realtime estándar)
      if (alerta.usuarioNombre == null) {
        try {
          final perfilData = await _repository.getProfileById(alerta.usuarioId);
          if (perfilData != null) {
            alerta = alerta.copyWith(
              usuarioNombre: '${perfilData['nombre']} ${perfilData['apellido']}'
                  .trim(),
            );
          }
        } catch (e) {
          print('Error fetching profile for realtime alert: $e');
        }
      }

      _activeAlert = alerta;
      globalHasActiveAlert.value = true;
      await _cache.saveAlert(alerta);
      _alertResponses = []; // Limpiar respuestas de alerta anterior
      _startPolling();
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  //  Respuestas de alerta
  // ──────────────────────────────────────────────

  /// Carga las respuestas de una alerta desde Supabase.
  Future<void> _loadAlertResponses(String alertaId) async {
    try {
      _alertResponses = await _repository.getAlertResponses(alertaId: alertaId);
      notifyListeners();
    } catch (e) {
      print('Error loading alert responses: $e');
    }
  }

  /// Recarga pública de las respuestas de la alerta activa.
  Future<void> refreshAlertResponses() async {
    if (_activeAlert == null) return;
    await _loadAlertResponses(_activeAlert!.id);
  }
}
