import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../globals.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejar mensaje en background
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }

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
          final barrioId = userData['barrio_id'];
          await FirebaseMessaging.instance.subscribeToTopic('barrio_$barrioId');
          if (kDebugMode) {
            print('Successfully subscribed to topic: barrio_$barrioId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token or subscribing to topic: $e');
        }
      }
    }
  }
}
