import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeTestSupabase();
  });

  group('Supabase Connection - Alertas Table', () {
    test('Can fetch from alertas table', () async {
      // Usar testClient inicializado en test_helper.dart
      final response = await testClient.from('alertas').select().limit(1);

      // La respuesta no debería ser nula (puede ser una lista vacía si no hay registros)
      expect(response, isNotNull);
      expect(response, isA<List>());
      print(
        'Alertas connection test passed! Found ${response.length} test records.',
      );
    });

    test('Can save an alert to alertas table', () async {
      // 1. Obtener un barrio válido para adjuntarlo al usuario
      print('usuario_login1: ${testClient.auth.currentUser}');
      print('barrios: ${await testClient.from('barrios').select('*')}');
      final barrios = await testClient.from('barrios').select('id').limit(1);

      if (barrios.isEmpty) {
        print('====================================================');
        print('🚫 SKIP: No hay barrios registrados en la base de datos.');
        print(
          'Para que la prueba RLS funcione, debes crear al menos un "Barrio"',
        );
        print(
          'manualmente desde tu panel de Supabase. El test necesita un barrio',
        );
        print('existente para asociar al usuario de prueba temporal.');
        print('====================================================');
        return;
      }

      final barrioId = barrios.first['id'];
      print('Barrio ID: $barrioId');

      // 2. Crear un usuario temporal asociando el barrio
      final testEmail =
          'test_${DateTime.now().millisecondsSinceEpoch}@ejemplo.com';
      final testPassword = 'PasswordTest123!';

      print('Intentando registrar usuario temporal para la prueba: $testEmail');
      final authResponse = await testClient.auth.signUp(
        email: testEmail,
        password: testPassword,
        data: {
          'nombre': 'Auto',
          'apellido': 'Test',
          'cedula': '0000000000',
          'direccion': 'N/A',
          'telefono': '000000000',
          'barrio_id': barrioId,
        },
      );

      if (authResponse.session == null) {
        print('SKIP: La creación de usuario requiere confirmación de correo.');
        print(
          'No se puede probar la inserción RLS sin un usuario autenticado activo.',
        );
        return;
      }

      final usuarioId = authResponse.user!.id;
      print('Usuario autenticado exitosamente. ID: $usuarioId');

      // 3. Crear los datos de prueba abarcando la estructura completa de la tabla
      final testPayload = {
        'barrio_id': barrioId,
        'usuario_id':
            usuarioId, // Ahora tenemos un ID de usuario real y en sesión
        'tipo_emergencia': 'Test',
        'descripcion': 'Test generico de inserción autenticada',
        'latitud': -0.1512900,
        'longitud': -78.4800000,
        'lugar': 'Casa de prueba',
        'que_paso': 'Prueba automatizada desde alertas_test.dart autenticada',
      };

      // 4. Insertar la alerta
      print(
        'Attempting to insert an alert for barrio_id: $barrioId y usuario_id: $usuarioId...',
      );
      try {
        final insertResponse = await testClient
            .from('alertas')
            .insert(testPayload)
            .select()
            .single();

        expect(insertResponse, isNotNull);
        expect(insertResponse['id'], isNotNull);
        expect(insertResponse['descripcion'], testPayload['descripcion']);
        expect(insertResponse['lugar'], testPayload['lugar']);
        expect(insertResponse['que_paso'], testPayload['que_paso']);

        final insertedId = insertResponse['id'];
        print('Successfully inserted alert with ID: $insertedId');
        print('Alert details: $insertResponse');
      } on PostgrestException catch (e) {
        // Usa print normal en caso de fallo, pero sin truncar
        print('=============================');
        print('POSTGREST ERROR:');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
        print('=============================');
        rethrow;
      }

      // 5. Limpiar los datos insertados (descomentado temporalmente)
      print('Cleaning up inserted alert...');
      //await testClient.from('alertas').delete().eq('id', insertedId);

      await testClient.auth.signOut();

      print(
        'Cleanup complete. Note: deletions are commented out so you can see them in Supabase, but you should clean them mechanically later.',
      );
    });
  });
}
