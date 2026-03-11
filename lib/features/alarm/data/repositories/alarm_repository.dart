import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/alert.dart';
import '../models/alert_model.dart';

class AlarmRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Inserta una nueva alerta en la tabla `alertas`.
  Future<Alerta> sendAlert({
    required String barrioId,
    required TipoEmergencia tipo,
    String? descripcion,
    String? lugar,
    String? quePaso,
    double? latitud,
    double? longitud,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Unauthenticated user cannot send alert.');
    }

    final payload = {
      'barrio_id': barrioId,
      'usuario_id': userId,
      'tipo_emergencia': tipo.name,
      if (descripcion != null) 'descripcion': descripcion,
      if (lugar != null) 'lugar': lugar,
      if (quePaso != null) 'que_paso': quePaso,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };

    final data = await _client
        .from('alertas')
        .insert(payload)
        .select()
        .single();
    return AlertaModel.fromJson(data);
  }

  /// Obtiene el historial de alertas de un barrio ordenado por fecha.
  Future<List<Alerta>> getAlertHistory({
    required String barrioId,
    int limit = 50,
  }) async {
    final data = await _client
        .from('alertas')
        .select()
        .eq('barrio_id', barrioId)
        .order('creado_en', ascending: false)
        .limit(limit);

    return (data as List<dynamic>)
        .map((e) => AlertaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cambia el estado de una alerta insertando un registro en respuestas_alerta
  Future<void> changeAlertState({
    required String alertaId,
    required String estado,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Unauthenticated user cannot change alert state.');
    }

    await _client.from('respuestas_alerta').insert({
      'alerta_id': alertaId,
      'usuario_id': userId,
      'estado': estado,
    });
  }

  /// Desactiva la alerta (solo para roles permitidos)
  Future<void> deactivateAlert({required String alertaId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Unauthenticated user cannot change alert state.');
    }

    await _client.from('alertas').update({'active': false}).eq('id', alertaId);
  }
}
