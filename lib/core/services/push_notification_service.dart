import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../globals.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejar mensaje en background
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }

  // Marcar que hay alerta activa en el caché local
  // Esto permite que al abrir la app se sepa que hay una alerta pendiente
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_alert', true);
  } catch (_) {}

  final FlutterLocalNotificationsPlugin localNotif =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'emergency_alarm_channel_3', // id updated to bypass caching
    'Emergency Alarms', // name
    description:
        'This channel is used for community emergency alerts.', // description
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarma'),
    enableVibration: true,
  );

  await localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  String title = message.notification?.title ??
      message.data['title'] ??
      '⚠️ Emergencia reportada!';
  String body = message.notification?.body ??
      message.data['body'] ??
      'Alerta comunitaria recibida.';

  await localNotif.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@mipmap/ic_launcher',
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarma'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT para que el sonido se repita
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    ),
  );
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Configurar notificaciones locales para Android (foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergency_alarm_channel_3', // id updated to bypass caching
      'Emergency Alarms', // name
      description:
          'This channel is used for community emergency alerts.', // description
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarma'),
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 2. Manejar notificaciones en segundo plano y app cerrada (tap sobre la notificacion)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("A new onMessageOpenedApp event was published!");
      }
      globalHasActiveAlert.value = true;
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print("App opened from terminated state by notification!");
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
          print("Local notification tapped: ${response.payload}");
        }
        globalHasActiveAlert.value = true;
      },
    );

    // 3. Configurar handlers de FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String title = message.notification?.title ??
          message.data['title'] ??
          '⚠️ Emergencia reportada!';
      String body = message.notification?.body ??
          message.data['body'] ??
          'Alerta comunitaria recibida.';

      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            priority: Priority.max,
            fullScreenIntent: true,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('alarma'),
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT para que el sonido se repita
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
      );
      // Removed automatic active alert opening. The user must tap the notification.
    });
  }

  static Future<void> requestPermissionAndSaveToken() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Obtener y guardar el token
      _firebaseMessaging.getToken().then((token) {
        if (token != null) {
          if (kDebugMode) {
            print("FCM Token: $token");
          }
          _saveTokenToSupabase(token);
        }
      });

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    // The target table is 'perfiles', which binds the user details to the auth profile.
    if (user != null) {
      try {
        await supabase
            .from('perfiles')
            .update({'fcm_token': token})
            .eq('id', user.id);

        // Get the neighborhood ID to subscribe to the relevant topic
        final userData = await supabase
            .from('perfiles')
            .select('barrio_id')
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null && userData['barrio_id'] != null) {
          await configurarSuscripcionBarrio(userData['barrio_id'].toString());
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token or subscribing to topic: $e');
        }
      }
    }
  }

  /// Gestiona la suscripción al topic FCM del barrio del usuario.
  ///
  /// Si el usuario cambia de barrio, se desuscribe del topic anterior antes
  /// de suscribirse al nuevo. El [idBarrio] es el identificador único del barrio.
  static Future<void> configurarSuscripcionBarrio(String idBarrio) async {
    const prefsKey = 'subscribed_barrio_id';
    final nuevoTopic = 'barrio_$idBarrio';

    try {
      final prefs = await SharedPreferences.getInstance();
      final barrioAnterior = prefs.getString(prefsKey);

      // 1. Desuscribir del topic viejo si el barrio cambió
      if (barrioAnterior != null && barrioAnterior != idBarrio) {
        final topicAnterior = 'barrio_$barrioAnterior';
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topicAnterior);
          if (kDebugMode) {
            print('[FCM] Desuscrito del topic anterior: $topicAnterior');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[FCM] Error al desuscribirse de $topicAnterior: $e');
          }
          // Continuamos aunque falle la desuscripción
        }
      }

      // 2. Suscribir al nuevo topic
      await FirebaseMessaging.instance.subscribeToTopic(nuevoTopic);
      await prefs.setString(prefsKey, idBarrio);

      if (kDebugMode) {
        print('[FCM] Suscrito correctamente al topic: $nuevoTopic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al configurar suscripción al topic $nuevoTopic: $e');
      }
      rethrow; // Propaga el error para que el llamador pueda manejarlo
    }
  }

  /// Cancela todas las notificaciones locales activas.
  /// Esto detiene el sonido de la alarma si está sonando.
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      if (kDebugMode) {
        print('All local notifications cancelled.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling notifications: $e');
      }
    }
  }
}
