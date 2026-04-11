import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import '../globals.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constantes del canal – centralizadas para evitar inconsistencias.
// IMPORTANTE: Cambiar el channelId obliga a Android a recrear el canal,
// aplicando el nuevo sonido/importancia a TODOS los usuarios.
// ─────────────────────────────────────────────────────────────────────────────
// Constants removed since alarm package is used

// ─────────────────────────────────────────────────────────────────────────────
// Disparador de la alarma con el package 'alarm'
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _triggerAlarm(String title, String body) async {
  try {
    // Asegurar que el plugin esté inicializado en contextos de background
    await alarm_pkg.Alarm.init();

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: 42,
      dateTime: DateTime.now().add(const Duration(seconds: 1)),
      assetAudioPath: 'assets/audio/alarma.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: const alarm_pkg.VolumeSettings.fixed(
        volume: 1.0,
        volumeEnforced: true,
      ),
      notificationSettings: alarm_pkg.NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Abrir App',
      ),
    );

    await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);
    if (kDebugMode) {
      print('[FCM] Alarma disparada correctamente.');
    }
  } catch (e, st) {
    if (kDebugMode) {
      print('[FCM] ERROR AL DISPARAR ALARMA: $e');
      print(st);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background handler (top-level, fuera de la clase)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[FCM] Background message: ${message.messageId}');
  }

  // Guardar flag en preferencias locales para que la app lo lea al abrirse.
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_alert', true);
  } catch (_) {}

  // (Removed _kChannel initialization)

  final String title =
      message.notification?.title ?? message.data['title'] ?? '⚠️ Emergencia reportada!';
  final String body =
      message.notification?.body ?? message.data['body'] ?? 'Alerta comunitaria recibida.';

  await _triggerAlarm(title, body);
}

// ─────────────────────────────────────────────────────────────────────────────
// Servicio principal
// ─────────────────────────────────────────────────────────────────────────────
class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // (Removed _kChannel initialization since alarm package handles its own notification)

    // 2. Listeners para segundo plano y app cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] App abierta desde notificación en background.');
      }
      globalHasActiveAlert.value = true;
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('[FCM] App abierta desde estado terminado por notificación.');
        }
        globalHasActiveAlert.value = true;
      }
    });

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('[FCM] Notificación local tocada: ${response.payload}');
        }
        globalHasActiveAlert.value = true;
      },
    );

    // 3. Handler para mensajes en primer plano (foreground)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final String title =
          message.notification?.title ?? message.data['title'] ?? '⚠️ Emergencia reportada!';
      final String body =
          message.notification?.body ?? message.data['body'] ?? 'Alerta comunitaria recibida.';

      _triggerAlarm(title, body);
      // El usuario debe tocar la notificación para abrir la alerta.
    });
  }

  // ─────────────────────────────────────────────
  // Permisos y token FCM
  // ─────────────────────────────────────────────

  /// Solicita permisos de notificación al sistema operativo y guarda el token
  /// FCM en Supabase. Si el guardado falla, lanza una excepción que el
  /// llamador debe capturar para manejar la situación apropiadamente.
  ///
  /// Retorna `true` si los permisos fueron otorgados, `false` en caso contrario.
  static Future<bool> requestPermissionAndSaveToken() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[FCM] Permiso: ${settings.authorizationStatus}');
    }

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      // 2. Obtener el token y guardarlo. Se usa await en lugar de .then()
      // para que los errores propaguen correctamente al llamador.
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('[FCM] Token obtenido correctamente.');
        }
        // Nota: _saveTokenToSupabase lanzará si hay error de red o DB.
        await _saveTokenToSupabase(token);
      } else {
        if (kDebugMode) {
          print('[FCM] Advertencia: getToken() devolvió null.');
        }
      }

      // 3. Escuchar renovaciones de token. Errores aquí se loguean
      //    pero no se propagan ya que este listener corre en background.
      _firebaseMessaging.onTokenRefresh.listen(
        (newToken) async {
          try {
            await _saveTokenToSupabase(newToken);
          } catch (e) {
            if (kDebugMode) {
              print('[FCM] Error al guardar token renovado: $e');
            }
          }
        },
      );
    }

    return granted;
  }

  /// Guarda el token FCM en la tabla `perfiles` de Supabase.
  /// Lanza una excepción si el guardado falla, para que el llamador
  /// pueda reaccionar (mostrar aviso al usuario, reintentar, etc.).
  // ─────────────────────────────────────────────
  // Suscripción a topics de Barrio
  // ─────────────────────────────────────────────

  /// Suscribe el dispositivo al topic del barrio especificado.
  static Future<void> subscribeToBarrio(String barrioId) async {
    try {
      final topic = 'barrio_${barrioId.trim()}';
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('[FCM] Suscrito explícitamente al tema: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al suscribirse al tema del barrio: $e');
      }
    }
  }

  /// Cancela la suscripción del dispositivo al topic del barrio especificado.
  static Future<void> unsubscribeFromBarrio(String barrioId) async {
    try {
      final topic = 'barrio_${barrioId.trim()}';
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('[FCM] Desuscrito explícitamente del tema: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al desuscribirse del tema del barrio: $e');
      }
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('cached_fcm_token');

    // Optimizacion: Si el token actual es igual al cacheado localmente, no hacemos UPDATE en DB
    if (cachedToken == token) {
      if (kDebugMode) {
        print('[FCM] Token idéntico al guardado localmente, omitiendo UPDATE.');
      }
      return;
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Si falla, la excepción se propaga al llamador. No se silencia.
      await supabase
          .from('perfiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      
      // Solo guardar en cache si la operación de BD fue un éxito
      await prefs.setString('cached_fcm_token', token);
      
      if (kDebugMode) {
        print('[FCM] Token guardado exitosamente en Supabase para userId=${user.id}');
      }
    }
  }

  // ─────────────────────────────────────────────
  // Cancelación de notificaciones
  // ─────────────────────────────────────────────

  /// Cancela todas las notificaciones locales activas.
  /// Esto detiene el sonido de la alarma insistente si aún está activo.
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await alarm_pkg.Alarm.stop(42);
      if (kDebugMode) {
        print('[FCM] Todas las notificaciones locales y la alarma canceladas.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al cancelar notificaciones: $e');
      }
    }
  }
}
