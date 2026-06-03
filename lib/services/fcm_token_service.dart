import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Handles FCM token registration and persistence for authenticated users.
///
/// Stores tokens in Firestore users/{uid} so the backend
/// PushNotificationService can read them when sending price-drop alerts.
///
/// Guest users (not logged in) are never written to — this service is
/// a no-op for unauthenticated sessions.
class FcmTokenService {
  FcmTokenService._();

  static final FcmTokenService instance = FcmTokenService._();

  final FirebaseMessaging _messaging = FirebaseService.instance.messaging;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  bool _refreshListenerStarted = false;

  /// Start listening for FCM token refreshes.
  ///
  /// Safe to call multiple times — only registers the listener once.
  /// Call this at app startup (e.g. inside NotificationService.initialize()).
  void startRefreshListener() {
    if (_refreshListenerStarted) return;
    _refreshListenerStarted = true;

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        final uid = FirebaseService.instance.currentUserId;
        if (uid != null && uid.isNotEmpty) {
          await _persist(uid, newToken);
        }
      },
      onError: (_) {}, // silent
    );
  }

  /// Fetch the current FCM token and write it to Firestore users/{uid}.
  ///
  /// Silent on all errors — permission denied, Firebase not ready, or
  /// Firestore write failure never crash the caller.
  Future<void> registerForUser(String uid) async {
    if (uid.trim().isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _persist(uid, token);
    } catch (_) {
      // Permission denied or messaging not available — do nothing.
    }
  }

  Future<void> _persist(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': _platformLabel,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Firestore write failed — silent.
    }
  }

  static String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }
}
