import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'ofertix_channel',
    'Ofertix Notifications',

    description: 'AI deals and smart alerts',

    importance: Importance.max,
  );

  /// INIT
  static Future<void> init() async {
    /// PERMISSIONS
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    /// LOCAL INIT
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await local.initialize(
      settings,

      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped');
      },
    );

    /// CHANNEL
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    /// FOREGROUND
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    /// CLICK
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Opened notification');
    });

    /// BACKGROUND CLICK
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from terminated notification');
    }

    /// TOKEN
    final token = await messaging.getToken();

    debugPrint('🔥 FCM TOKEN: $token');
  }

  /// FOREGROUND MESSAGE
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Ofertix';

    final body = message.notification?.body ?? 'New notification';

    await showNotification(title: title, body: body);
  }

  /// LOCAL NOTIFICATION
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ofertix_channel',
      'Ofertix Notifications',

      channelDescription: 'AI deals and alerts',

      importance: Importance.max,

      priority: Priority.high,

      playSound: true,

      enableVibration: true,

      visibility: NotificationVisibility.public,
    );

    const details = NotificationDetails(android: androidDetails);

    await local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,

      title,
      body,
      details,
    );
  }

  /// HOT DEAL
  static Future<void> showHotDealNotification({
    required String product,
    required String price,
  }) async {
    await showNotification(
      title: '🔥 Hot Deal Detected',
      body: '$product now for $price',
    );
  }

  /// PRICE DROP
  static Future<void> showPriceDropNotification({
    required String product,
    required String oldPrice,
    required String newPrice,
  }) async {
    await showNotification(
      title: '📉 Price Drop Alert',
      body: '$product dropped from $oldPrice to $newPrice',
    );
  }

  /// CASHBACK
  static Future<void> showCashbackNotification({
    required String product,
    required String cashback,
  }) async {
    await showNotification(
      title: '💸 Cashback Available',
      body: '$cashback cashback on $product',
    );
  }

  /// AI PICK
  static Future<void> showAiRecommendation({required String product}) async {
    await showNotification(
      title: '🧠 AI Recommendation',
      body: 'AI found a smart deal: $product',
    );
  }

  /// TEST
  static Future<void> testNotification() async {
    await showNotification(
      title: '🚀 Ofertix',
      body: 'Your AI shopping system is active.',
    );
  }
}
