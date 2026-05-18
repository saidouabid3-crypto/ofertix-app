import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin local =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await messaging.requestPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await local.initialize(settings);

    FirebaseMessaging.onMessage.listen((message) {
      showNotification(
        message.notification?.title ?? 'Ofertix',

        message.notification?.body ?? '',
      );
    });

    final token = await messaging.getToken();

    print('FCM TOKEN: $token');
  }

  static Future<void> showNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      'ofertix_channel',
      'Ofertix Notifications',

      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await local.show(0, title, body, details);
  }

  static Future<void> testNotification() async {
    await showNotification(
      '🔥 Ofertix Deal',
      'New hot discount available now!',
    );
  }
}
