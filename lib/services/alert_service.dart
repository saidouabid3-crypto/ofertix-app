import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Price alert service. Requires Firebase authentication for all writes.
/// Guest users cannot create price alerts — they must log in first.
class AlertService {
  AlertService._();

  static final AlertService instance = AlertService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final NotificationService _notifications = NotificationService.instance;

  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _firestore.collection('price_alerts');

  String? get _uid => AuthService.instance.currentUserId?.trim();

  bool get _isAuthenticated {
    final uid = _uid;
    return uid != null && uid.isNotEmpty;
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchAlerts({
    required String userId,
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
    required String userId,
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

  /// Creates a product price alert. Requires the user to be logged in.
  /// Returns the alert document ID on success, null if not authenticated
  /// or on any error.
  Future<String?> createProductAlert({
    required Product product,
    required double targetPrice,
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    if (!_isAuthenticated) return null;
    if (targetPrice <= 0) return null;

    final uid = _uid!;
    final productId = product.id.trim().isNotEmpty
        ? product.id.trim()
        : product.name.trim();
    final productName = product.name.trim().isNotEmpty
        ? product.name.trim()
        : productId;

    if (productId.isEmpty || productName.isEmpty) return null;

    try {
      final existing = await _alertsCollection
          .where('userId', isEqualTo: uid)
          .where('productId', isEqualTo: productId)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return existing.docs.first.id;

      final doc = await _alertsCollection.add({
        'userId': uid,
        'productId': productId,
        'productName': productName,
        'productImage': product.image,
        'productQuery': product.name,
        'store': product.store,
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
          body: '$productName — target ${targetPrice.toStringAsFixed(2)} $currency',
        );
      } catch (_) {}

      return doc.id;
    } catch (_) {
      return null;
    }
  }

  /// Creates an AI price alert. Requires the user to be logged in.
  Future<String?> createAiAlert({
    required String productQuery,
    required double targetPrice,
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    if (!_isAuthenticated) return null;

    final cleanQuery = productQuery.trim();
    if (cleanQuery.isEmpty || targetPrice <= 0) return null;

    final uid = _uid!;

    try {
      final existing = await _alertsCollection
          .where('userId', isEqualTo: uid)
          .where('productQuery', isEqualTo: cleanQuery)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return existing.docs.first.id;

      final doc = await _alertsCollection.add({
        'userId': uid,
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
          body: '$cleanQuery — target ${targetPrice.toStringAsFixed(2)} $currency',
        );
      } catch (_) {}

      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    if (alertId.trim().isEmpty) return false;
    try {
      await _alertsCollection.doc(alertId.trim()).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAlertActive({
    required String alertId,
    required bool active,
  }) async {
    if (alertId.trim().isEmpty) return false;
    try {
      await _alertsCollection.doc(alertId.trim()).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTargetPrice({
    required String alertId,
    required double targetPrice,
  }) async {
    if (alertId.trim().isEmpty || targetPrice <= 0) return false;
    try {
      await _alertsCollection.doc(alertId.trim()).update({
        'targetPrice': targetPrice,
        'triggered': false,
        'active': true,
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
