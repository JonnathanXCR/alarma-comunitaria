import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  // Timeouts (para operaciones que los necesiten)
  static const Duration httpTimeout = Duration(seconds: 15);
}
