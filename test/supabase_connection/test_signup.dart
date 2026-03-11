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

  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final password = 'TestPassword123!';

  print('Intentando crear usuario temporal: $email');
  try {
    final authResponse = await testClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'cedula': '0000000000',
        'nombre': 'Auto',
        'apellido': 'Test',
        'direccion': 'Test Dir',
        'telefono': '00000000',
      },
    );

    if (authResponse.session != null) {
      print('ÉXITO: Usuario creado y sesión iniciada automáticamente.');
    } else {
      print(
        'INFO: Usuario creado, pero requiere confirmación de email (sesión nula).',
      );
    }
  } catch (e) {
    print('ERROR: $e');
  }
  exit(0);
}
