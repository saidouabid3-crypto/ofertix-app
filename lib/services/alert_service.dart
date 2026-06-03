import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class AlertService {
  AlertService._();

  static final AlertService instance = AlertService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final NotificationService _notifications = NotificationService.instance;

  // Same key as FavoriteService and WatchlistService — one device-scoped
  // guest identity is shared across all user collections.
  static const String _guestIdKey = 'ofertix_guest_id';

  CollectionReference<Map<String, dynamic>> get _alertsCollection {
    return _firestore.collection('price_alerts');
  }

  /// Returns the Firebase UID for authenticated users.
  /// For guests, returns a persistent device-scoped id (guest_{random32hex})
  /// stored in SharedPreferences — consistent with FavoriteService/WatchlistService.
  Future<String> _resolveUserId() async {
    final uid = AuthService.instance.currentUserId;
    if (uid != null && uid.trim().isNotEmpty) return uid.trim();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestIdKey);
    if (existing != null && existing.isNotEmpty) return 'guest_$existing';
    final newId = _generateGuestId();
    await prefs.setString(_guestIdKey, newId);
    return 'guest_$newId';
  }

  static String _generateGuestId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchAlerts({
    String userId = 'guest',
  }) {
    return _alertsCollection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final docs = snapshot.docs;

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });

        return docs;
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAlertsOnce({
    String userId = 'guest',
  }) async {
    try {
      final snapshot = await _alertsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final docs = snapshot.docs;

      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      return docs;
    } catch (_) {
      return [];
    }
  }

  Future<String?> createProductAlert({
    required Product product,
    required double targetPrice,
    String userId = 'guest',
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    if (targetPrice <= 0) return null;

    final resolvedUserId = (userId == 'guest' || userId.trim().isEmpty)
        ? await _resolveUserId()
        : userId;

    final productId = product.id.trim().isNotEmpty
        ? product.id.trim()
        : product.name.trim();

    final productName = product.name.trim().isNotEmpty
        ? product.name.trim()
        : productId;

    if (productId.isEmpty || productName.isEmpty) return null;

    try {
      final existing = await _alertsCollection
          .where('userId', isEqualTo: resolvedUserId)
          .where('productId', isEqualTo: productId)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final doc = await _alertsCollection.add({
        'userId': resolvedUserId,

        'productId': productId,
        'productName': productName,
        'productImage': product.image,
        'productQuery': product.name,
        'store': product.store,

        // Full product snapshot, باش نقدر نفتحو من Alerts
        'name': product.name,
        'image': product.image,
        'description': product.description,
        'category': product.category,
        'affiliateUrl': product.affiliateUrl,
        'country': product.country,
        'oldPrice': product.oldPrice,
        'newPrice': product.newPrice,
        'currentPrice': product.newPrice,
        'discount': product.discount,
        'isOnline': product.isOnline,
        'isGlobal': product.isGlobal,
        'featured': product.featured,
        'isHot': product.isHot,
        'isTrending': product.isTrending,
        'sponsored': product.sponsored,
        'views': product.views,
        'clicks': product.clicks,
        'sales': product.sales,
        'lat': product.lat,
        'lng': product.lng,

        'targetPrice': targetPrice,
        'currency': currency,
        'countryCode': countryCode,
        'active': true,
        'triggered': false,
        'source': 'product',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await _notifications.showLocalNotification(
          title: '🔔 Price alert created',
          body:
              '$productName — target ${targetPrice.toStringAsFixed(2)} $currency',
        );
      } catch (_) {}

      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<String?> createAiAlert({
    required String productQuery,
    required double targetPrice,
    String userId = 'guest',
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    final cleanQuery = productQuery.trim();

    if (cleanQuery.isEmpty || targetPrice <= 0) return null;

    final resolvedUserId = (userId == 'guest' || userId.trim().isEmpty)
        ? await _resolveUserId()
        : userId;

    try {
      final existing = await _alertsCollection
          .where('userId', isEqualTo: resolvedUserId)
          .where('productQuery', isEqualTo: cleanQuery)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final doc = await _alertsCollection.add({
        'userId': resolvedUserId,
        'productId': cleanQuery,
        'productName': cleanQuery,
        'productQuery': cleanQuery,
        'targetPrice': targetPrice,
        'currency': currency,
        'countryCode': countryCode,
        'active': true,
        'triggered': false,
        'source': 'ai',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await _notifications.showLocalNotification(
          title: '🔔 AI price alert created',
          body:
              '$cleanQuery — target ${targetPrice.toStringAsFixed(2)} $currency',
        );
      } catch (_) {}

      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    final cleanId = alertId.trim();

    if (cleanId.isEmpty) return false;

    try {
      await _alertsCollection.doc(cleanId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAlertActive({
    required String alertId,
    required bool active,
  }) async {
    final cleanId = alertId.trim();

    if (cleanId.isEmpty) return false;

    try {
      await _alertsCollection.doc(cleanId).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkLocalPriceDrop({
    required String alertId,
    required String productName,
    required double oldPrice,
    required double newPrice,
    required double targetPrice,
  }) async {
    if (newPrice <= targetPrice) {
      await _alertsCollection.doc(alertId).update({
        'triggered': true,
        'active': false,
        'triggeredAt': FieldValue.serverTimestamp(),
        'lastCheckedPrice': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _notifications.notifyPriceDrop(
        productName: productName,
        oldPrice: oldPrice.toStringAsFixed(2),
        newPrice: newPrice.toStringAsFixed(2),
      );
    }
  }
}
