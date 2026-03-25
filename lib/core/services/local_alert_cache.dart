import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/alarm/data/models/alert_model.dart';
import '../../features/alarm/domain/entities/alert.dart';

/// Servicio que persiste la última alerta activa en el almacenamiento local
/// del dispositivo usando SharedPreferences.
///
/// Esto permite que la app muestre la alerta activa inmediatamente al abrirse,
/// sin necesidad de hacer un request a Supabase.
class LocalAlertCache {
  static const _keyAlert = 'cached_active_alert';
  static const _keyHasAlert = 'has_active_alert';

  LocalAlertCache._();
  static final LocalAlertCache instance = LocalAlertCache._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Guarda una alerta activa en caché local.
  Future<void> saveAlert(Alerta alerta) async {
    final prefs = await _preferences;
    final json = AlertaModel.fromAlerta(alerta).toStorageJson();
    await prefs.setString(_keyAlert, jsonEncode(json));
    await prefs.setBool(_keyHasAlert, true);
  }

  /// Carga la alerta guardada, o null si no hay ninguna.
  Future<Alerta?> loadAlert() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_keyAlert);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AlertaModel.fromStorageJson(map);
    } catch (e) {
      // Si el dato está corrupto, limpiamos el caché
      await clearAlert();
      return null;
    }
  }

  /// Limpia la alerta guardada (se llama al desactivar/resolver).
  Future<void> clearAlert() async {
    final prefs = await _preferences;
    await prefs.remove(_keyAlert);
    await prefs.setBool(_keyHasAlert, false);
  }

  /// Devuelve rápidamente si hay alerta guardada (sin deserializar).
  Future<bool> hasActiveAlert() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyHasAlert) ?? false;
  }
}
