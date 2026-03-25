import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/provincia.dart';
import '../../domain/entities/ciudad.dart';
import '../models/provincia_model.dart';
import '../models/ciudad_model.dart';

class LocationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Provincia>> getProvincias() async {
    final data = await _client.from('provincias').select().order('nombre', ascending: true);
    return (data as List).map((e) => ProvinciaModel.fromJson(e)).toList();
  }

  Future<List<Ciudad>> getCiudadesByProvincia(String provinciaId) async {
    final data = await _client
        .from('ciudades')
        .select()
        .eq('provincia_id', provinciaId)
        .order('nombre', ascending: true);
    return (data as List).map((e) => CiudadModel.fromJson(e)).toList();
  }

  Future<List<Ciudad>> getAllCiudades() async {
    final data = await _client.from('ciudades').select().order('nombre', ascending: true);
    return (data as List).map((e) => CiudadModel.fromJson(e)).toList();
  }
}
