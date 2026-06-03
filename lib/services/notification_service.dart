import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_token_service.dart';
import 'firebase_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseService.instance.messaging;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ofertix_channel',
    'Ofertix Notifications',
    description: 'Smart shopping alerts and AI deal notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _local.initialize(settings);

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? 'Ofertix',
        body: message.notification?.body ?? 'New smart deal available',
      );
    });

    // Start token-refresh listener once and register token for any user
    // who is already logged in when the app starts.
    FcmTokenService.instance.startRefreshListener();
    final uid = FirebaseService.instance.currentUserId;
    if (uid != null && uid.isNotEmpty) {
      // Fire-and-forget — do not block notification setup.
      FcmTokenService.instance.registerForUser(uid);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ofertix_channel',
      'Ofertix Notifications',
      channelDescription: 'Smart shopping alerts and AI deal notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> notifyHotDeal({
    required String productName,
    required String price,
  }) async {
    await showLocalNotification(
      title: '🔥 Hot Deal',
      body: '$productName now for $price',
    );
  }

  Future<void> notifyPriceDrop({
    required String productName,
    required String oldPrice,
    required String newPrice,
  }) async {
    await showLocalNotification(
      title: '📉 Price Drop',
      body: '$productName dropped from $oldPrice to $newPrice',
    );
  }

  Future<void> notifyAiRecommendation({required String productName}) async {
    await showLocalNotification(
      title: '🧠 AI Recommendation',
      body: 'AI found a smart deal: $productName',
    );
  }

  Future<void> notifyCashback({
    required String productName,
    required String cashback,
  }) async {
    await showLocalNotification(
      title: '💸 Cashback',
      body: '$cashback cashback available on $productName',
    );
  }
}
