import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/neighborhood.dart';
import '../models/neighborhood_model.dart';

class NeighborhoodRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene todos los barrios disponibles desde la tabla `barrios`.
  Future<List<Barrio>> getBarrios({
    String? role,
    String? userId,
    String? userBarrioId,
    String? provinciaId,
    String? ciudadId,
  }) async {
    // Si filtramos por provincia, necesitamos un join !inner para que Supabase filtre correctamente
    var query = _client.from('barrios').select('*, ciudades!inner(nombre, provincia_id)');

    if (role == 'supervisor' && userId != null) {
      query = query.eq('supervisor_id', userId);
    } else if (role == 'presidente_barrio' && userBarrioId != null) {
      query = query.eq('id', userBarrioId);
    }

    if (ciudadId != null) {
      query = query.eq('ciudad_id', ciudadId);
    } else if (provinciaId != null) {
      query = query.eq('ciudades.provincia_id', provinciaId);
    }

    final data = await query.order('nombre', ascending: true);
    return (data as List<dynamic>)
        .map((e) => BarrioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un barrio por su [id].
  Future<Barrio> getBarrioById(String id) async {
    final data = await _client.from('barrios').select('*, ciudades(nombre)').eq('id', id).single();
    return BarrioModel.fromJson(data);
  }

  /// Crea un nuevo barrio en la base de datos.
  Future<BarrioModel> createBarrio(String nombre, String ciudadId, {String? whatsappUrl}) async {
    final data = await _client.from('barrios').insert({
      'nombre': nombre,
      'ciudad_id': ciudadId,
      'whatsapp_url': whatsappUrl,
    }).select('*, ciudades(nombre)').single();
    
    return BarrioModel.fromJson(data);
  }

  /// Actualiza un barrio existente en la base de datos.
  Future<BarrioModel> updateBarrio(
    String id, {
    String? nombre,
    String? ciudadId,
    String? whatsappUrl,
    String? supervisorId,
    String? presidenteId,
  }) async {
    final data = await _client.from('barrios').update({
      if (nombre != null) 'nombre': nombre,
      if (ciudadId != null) 'ciudad_id': ciudadId,
      if (whatsappUrl != null) 'whatsapp_url': whatsappUrl,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      if (presidenteId != null) 'presidente_id': presidenteId,
    }).eq('id', id).select('*, ciudades(nombre)').single();
    
    return BarrioModel.fromJson(data);
  }
}
