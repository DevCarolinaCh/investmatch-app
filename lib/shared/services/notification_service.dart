import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Handler de mensajes en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.showLocalNotification(
    title: message.notification?.title ?? 'InvestMatch',
    body: message.notification?.body ?? '',
    payload: message.data.toString(),
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  late ApiService _apiService;

  static const _androidChannel = AndroidNotificationChannel(
    'investmatch_high',
    'InvestMatch',
    description: 'Notificaciones de mensajes, matches y reuniones',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize(ApiService apiService) async {
    _apiService = apiService;

    // Solicitar permisos
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificaciones locales
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canal Android
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Registrar FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Escuchar refresh de token
    _fcm.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _apiService.registerPushToken(token, platform);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await showLocalNotification(
      title: message.notification?.title ?? 'InvestMatch',
      body: message.notification?.body ?? '',
      payload: message.data['type'] as String? ?? '',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navegar según el payload (tipo de notificación)
    // El router lo maneja a través de deeplinks
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _localNotifs.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Tipos de notificaciones para canales semánticos
  Future<void> notifyNewMessage(String senderName, String preview) =>
      showLocalNotification(
        title: senderName,
        body: preview,
        payload: 'message',
      );

  Future<void> notifyProjectViewed(String projectTitle) =>
      showLocalNotification(
        title: 'Tu proyecto fue visto',
        body: 'Alguien vio "$projectTitle"',
        payload: 'project_view',
      );

  Future<void> notifyNewMatch(String investorName, String projectTitle) =>
      showLocalNotification(
        title: '¡Nuevo match!',
        body: '$investorName está interesado en "$projectTitle"',
        payload: 'match',
      );

  Future<void> notifyMeetingScheduled(String counterpartName) =>
      showLocalNotification(
        title: 'Reunión agendada',
        body: 'Tu intro call con $counterpartName fue confirmada',
        payload: 'meeting',
      );
}
