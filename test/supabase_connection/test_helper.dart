import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late SupabaseClient testClient;

Future<void> initializeTestSupabase() async {
  // Load .env relative to the project root for tests
  final file = File('.env');
  if (await file.exists()) {
    dotenv.testLoad(fileInput: await file.readAsString());
  } else {
    throw Exception(
      '.env file not found. Make sure to run tests from the project root.',
    );
  }

  // Instanciar directamente el cliente para evitar inicializar paquetes nativos
  // que causan MissingPluginException en unit tests puros de dart/flutter.
  testClient = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}
