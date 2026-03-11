import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/neighborhood.dart';
import '../models/neighborhood_model.dart';

class NeighborhoodRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene todos los barrios disponibles desde la tabla `barrios`.
  Future<List<Barrio>> getBarrios() async {
    final data = await _client
        .from('barrios')
        .select()
        .order('nombre', ascending: true);

    return (data as List<dynamic>)
        .map((e) => BarrioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un barrio por su [id].
  Future<Barrio> getBarrioById(String id) async {
    final data = await _client.from('barrios').select().eq('id', id).single();
    return BarrioModel.fromJson(data);
  }
}
