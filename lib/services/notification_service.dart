import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background Message: ${message.notification?.title}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static int _notificationCount = 0;

  static Future<void> init() async {
    // Firebase Messaging
    await _firebaseMessaging.requestPermission();
    
    // Firebase token al
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Firebase Messaging handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _incrementNotificationCount();
      _showLocalNotification(
        title: message.notification?.title ?? 'Bildirim',
        body: message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Bildirime tıklandığında
      _resetNotificationCount();
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        _resetNotificationCount();
      },
    );
  }

  static void _incrementNotificationCount() {
    _notificationCount++;
    _updateBadgeNumber();
  }

  static void _resetNotificationCount() {
    _notificationCount = 0;
    _updateBadgeNumber();
  }

  static Future<void> _updateBadgeNumber() async {
    // Android için badge number güncelle
    await _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.setBadgeNumber(_notificationCount);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    _incrementNotificationCount();
    await _showLocalNotification(title: title, body: body);
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'servisnoktam_channel',
      'Servis Noktam Bildirimleri',
      channelDescription: 'Servis yaklaştığında bildirim gönderir',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      badgeNumber: _notificationCount,
      ticker: 'ticker',
      icon: '@mipmap/launcher_icon',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}
