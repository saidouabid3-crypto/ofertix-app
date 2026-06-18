import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/navigation/app_router.dart';
import '../core/navigation/app_routes.dart';
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

    // Route user to the messages screen when tapping a message notification
    // from the background or terminated state.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageTap(initial);

    // Start token-refresh listener once and register token for any user
    // who is already logged in when the app starts.
    FcmTokenService.instance.startRefreshListener();
    final uid = FirebaseService.instance.currentUserId;
    if (uid != null && uid.isNotEmpty) {
      // Fire-and-forget — do not block notification setup.
      FcmTokenService.instance.registerForUser(uid);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    if (type == 'message' || type == 'marketplace_message' ||
        type == 'reel_message' || type == 'direct_message') {
      // Backend sends the canonical conversation_id in FCM data.
      // Pass it as route arguments so the inbox can auto-open that thread.
      final conversationId = message.data['conversationId']?.toString() ?? '';
      AppRouter.navigatorKey.currentState?.pushNamed(
        AppRoutes.marketplaceMessages,
        arguments: conversationId.isNotEmpty ? conversationId : null,
      );
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
