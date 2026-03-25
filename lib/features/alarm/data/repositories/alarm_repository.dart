import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_response.dart';
import '../models/alert_model.dart';
import '../models/alert_response_model.dart';

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
    File? imageFile,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Unauthenticated user cannot send alert.');
    }

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadAlertImage(imageFile, userId);
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
      if (imageUrl != null) 'imagen_url': imageUrl,
    };

    final data = await _client
        .from('alertas')
        .insert(payload)
        .select('*, perfiles(nombre, apellido)')
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
        .select('*, perfiles(nombre, apellido)')
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

    // Intentar borrar la imagen asociada si existe para no ocupar espacio
    try {
      final alertData = await _client
          .from('alertas')
          .select('imagen_url')
          .eq('id', alertaId)
          .maybeSingle();

      if (alertData != null) {
        final imageUrl = alertData['imagen_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final urlParts = imageUrl.split('/alertas_imagenes/');
          if (urlParts.length > 1) {
            final path = urlParts[1];
            await _client.storage.from('alertas_imagenes').remove([path]);
          }
        }
      }
    } catch (e) {
      print('Error al intentar borrar la imagen de la alerta: $e');
    }

    // Desactivar la alerta y limpiar la URL de la imagen
    await _client.from('alertas').update({
      'active': false,
      'imagen_url': null,
    }).eq('id', alertaId);
  }

  /// Obtiene la alerta activa más reciente del barrio (si existe).
  Future<Alerta?> getActiveAlert({required String barrioId}) async {
    final data = await _client
        .from('alertas')
        .select('*, perfiles(nombre, apellido)')
        .eq('barrio_id', barrioId)
        .eq('active', true)
        .order('creado_en', ascending: false)
        .limit(1);

    final list = data as List<dynamic>;
    if (list.isEmpty) return null;
    return AlertaModel.fromJson(list.first as Map<String, dynamic>);
  }

  /// Obtiene las respuestas de una alerta, con datos del perfil del usuario.
  Future<List<RespuestaAlerta>> getAlertResponses({
    required String alertaId,
  }) async {
    final data = await _client
        .from('respuestas_alerta')
        .select('*, perfiles(nombre, apellido)')
        .eq('alerta_id', alertaId)
        .order('creado_en', ascending: false);

    return (data as List<dynamic>)
        .map((e) => RespuestaAlertaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene los datos básicos de un perfil por su ID.
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('perfiles')
          .select('nombre, apellido')
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      print('Error fetching profile $userId: $e');
      return null;
    }
  }

  /// Sube una imagen al bucket de Supabase Storage.
  Future<String?> _uploadAlertImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final path = '$userId/$fileName';
      
      await _client.storage.from('alertas_imagenes').upload(path, imageFile);
      
      return _client.storage.from('alertas_imagenes').getPublicUrl(path);
    } catch (e) {
      print('Error uploading alert image: $e');
      return null;
    }
  }
}
