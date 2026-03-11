import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    // Inicializa el cliente especial de pruebas sin dependencias nativas
    await initializeTestSupabase();
  });

  test('Test de inserción manual con cuenta real', () async {
    // 1) Login para que RLS funcione como en producción
    final email = 'jhonatancordo25@gmail.com';
    final password = 'Mamaquilla*1973';

    print('Iniciando sesión con: $email');
    AuthResponse authRes;
    try {
      authRes = await testClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      fail('❌ Error de Autenticación: ${e.message}');
    } catch (e) {
      fail('❌ Error inesperado durante login: $e');
    }

    final user = authRes.user;
    expect(user, isNotNull, reason: 'No se pudo iniciar sesión.');
    print('✅ Login OK: ${user!.id}');

    // Buscar un barrio válido dinámicamente o usar el proporcionado si se desea
    final barrios = await testClient.from('barrios').select('id').limit(1);
    expect(
      barrios,
      isNotEmpty,
      reason: 'No hay barrios en la base de datos para asociar la alerta.',
    );
    final barrioId = barrios.first['id'];

    // 2) Datos de prueba
    final random = Random();

    final payload = <String, dynamic>{
      'usuario_id': user.id, // uuid (string)
      'barrio_id': barrioId, // usar barrio real de la base de datos
      'tipo_emergencia': 'robo', // text
      'descripcion': 'Alerta de prueba desde Dart Test',
      'latitud': Geolocator,
      'longitud': -79.010 + random.nextDouble() / 100, // double
      'lugar': 'Parque Central',
      'que_paso':
          'Se escucharon ruidos sospechosos. Prueba de inserción autenticada.',
    };

    try {
      // 3) INSERT y devolver el registro creado
      print('Intentando insertar alerta...');
      final inserted = await testClient
          .from('alertas')
          .insert(payload)
          .select()
          .single();

      print('✅ Insert OK');
      print(inserted);
      expect(inserted, isNotNull);

      final insertedId = inserted['id'];
      print('🆔 ID insertado: $insertedId');

      // 4) SELECT por id para verificar
      final fetched = await testClient
          .from('alertas')
          .select('*')
          .eq('id', insertedId)
          .single();

      print('✅ Fetch OK');
      print(fetched);
      expect(fetched['id'], insertedId);
    } on PostgrestException catch (e) {
      print('❌ Error de Base de Datos (PostgrestException):');
      print('Código: ${e.code}');
      print('Mensaje: ${e.message}');
      print('Detalles: ${e.details}');
      rethrow;
    } catch (e) {
      print('❌ Error inesperado: $e');
      rethrow;
    } finally {
      // 5) Cerrar sesión
      await testClient.auth.signOut();
    }
  });
}
