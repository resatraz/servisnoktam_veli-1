import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // TODO: Update to flutter_local_notifications v22+ API
    // const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const settings = InitializationSettings(android: android);
    // await _plugin.initialize(
    //   settings,
    //   onDidReceiveNotificationResponse: (NotificationResponse response) {},
    // );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // TODO: Update to flutter_local_notifications v22+ API
    // const androidDetails = AndroidNotificationDetails(
    //   'servis_channel', 'Servis Bildirimleri',
    //   importance: Importance.high,
    //   priority: Priority.high,
    //   icon: '@mipmap/ic_launcher',
    // );
    // const details = NotificationDetails(android: androidDetails);
    // await _plugin.show(
    //   id: 0,
    //   title: title,
    //   body: body,
    //   notificationDetails: details,
    // );
  }
}
