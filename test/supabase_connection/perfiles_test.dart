import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeTestSupabase();
  });

  group('Supabase Connection - Perfiles Table', () {
    test('Can fetch from perfiles table', () async {
      // Usa testClient en lugar de Supabase.instance.client para evitar MissingPluginException
      // Trata de hacer una consulta sencilla con un límite para verificar conexión
      final response = await testClient.from('perfiles').select().limit(1);

      // La respuesta no debería ser nula (puede ser una lista vacía si no hay registros)
      expect(response, isNotNull);
      expect(response, isA<List>());
      print(
        'Perfiles connection test passed! Found ${response.length} test records.',
      );
    });
  });
}
