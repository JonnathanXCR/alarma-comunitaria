import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  final file = File('.env');
  if (await file.exists()) {
    dotenv.testLoad(fileInput: await file.readAsString());
  }

  final testClient = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    final barrios = await testClient.from('barrios').select('id').limit(1);
    String barrioId;
    if (barrios.isEmpty) {
      final newBarrio = await testClient
          .from('barrios')
          .insert({'nombre': 'Script Test'})
          .select()
          .single();
      barrioId = newBarrio['id'];
    } else {
      barrioId = barrios.first['id'];
    }

    final testPayload = {
      'barrio_id': barrioId,
      'tipo_emergencia': 'Test',
      'descripcion': 'Test from script',
      'latitud': -0.1512900,
      'longitud': -78.4800000,
      'lugar': 'Test Lugar',
      'que_paso': 'script run',
    };

    final insertResponse = await testClient
        .from('alertas')
        .insert(testPayload)
        .select()
        .single();
    File('error_log.txt').writeAsStringSync('SUCCESS: $insertResponse');
  } on PostgrestException catch (e) {
    File('error_log.txt').writeAsStringSync(
      'ERROR CODE: ${e.code}\nERROR MESSAGE: ${e.message}\nERROR DETAILS: ${e.details}\nERROR HINT: ${e.hint}',
    );
  } catch (e) {
    File('error_log.txt').writeAsStringSync('OTHER ERROR: $e');
  }
  exit(0);
}
