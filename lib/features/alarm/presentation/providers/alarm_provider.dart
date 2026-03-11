import 'package:flutter/material.dart';

import '../../../../core/network/websocket_service.dart';
import '../../data/models/alert_model.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../domain/entities/alert.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/globals.dart';

class AlarmProvider extends ChangeNotifier {
  final AlarmRepository _repository;
  final AuthProvider _authProvider;

  Alerta? _activeAlert;
  List<Alerta> _history = [];
  bool _isSending = false;
  String? _error;

  // Rastrear qué alertas han sido recibidas localmente para cambiar estado de botón
  final Set<String> _receivedAlertIds = {};

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
  bool get isSending => _isSending;
  bool get hasActiveAlert => _activeAlert != null;
  String? get error => _error;

  /// Verifica si la alerta dada ya fue marcada como recibida
  bool isAlertReceived(String id) => _receivedAlertIds.contains(id);

  @override
  void dispose() {
    RealtimeService.instance.removeListener(_onRealtimeEvent);
    super.dispose();
  }

  /// Dispara una alerta de emergencia.
  Future<void> sendEmergencyAlert({
    TipoEmergencia tipo = TipoEmergencia.seguridad,
    String? descripcion,
    String? lugar,
    String? quePaso,
    double? latitud,
    double? longitud,
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
      );
      _activeAlert = alerta;
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

  bool _isFetchingLatest = false;

  /// Recupera la última alerta activa del barrio
  Future<void> fetchLatestAlert() async {
    if (_isFetchingLatest) return;
    
    final user = _authProvider.user;
    if (user == null || user.barrioId == null) return;
    
    _isFetchingLatest = true;
    try {
      final latest = await _repository.getAlertHistory(barrioId: user.barrioId!, limit: 1);
      if (latest.isNotEmpty) {
        _activeAlert = latest.first;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching latest alert: $e');
    } finally {
      _isFetchingLatest = false;
    }
  }

  /// Marca la alerta activa como resuelta y la elimina del estado local.
  void resolveCurrentAlert() {
    _activeAlert = null;
    notifyListeners();
  }

  /// Registra en la base de datos que la alerta fue recibida.
  Future<void> markAlertAsReceived(String alertaId) async {
    if (_receivedAlertIds.contains(alertaId)) return; // Ya se envió antes

    _receivedAlertIds.add(alertaId);
    notifyListeners();

    try {
      await _repository.changeAlertState(
        alertaId: alertaId,
        estado: 'RECIBIDA',
      );
    } catch (e) {
      print('Error marking alert as received: $e');
    }
  }

  /// Desactiva una alerta en curso (solo admin, supervisor o presidente)
  Future<void> deactivateAlert(String alertaId) async {
    try {
      await _repository.deactivateAlert(alertaId: alertaId);
      if (_activeAlert?.id == alertaId) {
        resolveCurrentAlert();
        globalHasActiveAlert.value = false;
      }
    } catch (e) {
      print('Error deactivating alert: $e');
      // Podrías mostrar un Snackbar con el error
    }
  }

  void _onRealtimeEvent(WsEvent event) {
    if (event.type == WsEventType.alertaNueva) {
      final alerta = AlertaModel.fromJson(event.payload);
      
      // Doble validación de seguridad: asegurar que la alerta es del barrio del usuario
      final userBarrioId = _authProvider.user?.barrioId;
      if (userBarrioId == null || alerta.barrioId != userBarrioId) {
        return;
      }

      _activeAlert = alerta;
      globalHasActiveAlert.value = true;
      notifyListeners();
    }
  }
}
