import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';

class AlertsRepository {
  static final AlertsRepository instance = AlertsRepository();

  // All alerts live in price_alerts, matching AlertService.
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseService.instance.firestore.collection('price_alerts');

  Future<void> initializeNotifications() async {}

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchAlerts({
    required String userId,
  }) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final docs = snap.docs;
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
      return docs;
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAlertsOnce({
    required String userId,
  }) async {
    try {
      final snap = await _col.where('userId', isEqualTo: userId).get();
      final docs = snap.docs;
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
    required String userId,
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    if (targetPrice <= 0) return null;
    final productId = product.id.trim().isNotEmpty ? product.id.trim() : product.name.trim();
    if (productId.isEmpty) return null;

    try {
      final existing = await _col
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return existing.docs.first.id;

      final doc = await _col.add({
        'userId': userId,
        'productId': productId,
        'productName': product.name,
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
        'currency': currency,
        'countryCode': countryCode,
        'targetPrice': targetPrice,
        'active': true,
        'triggered': false,
        'source': 'product',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<String?> createAiAlert({
    required String productQuery,
    required double targetPrice,
    required String userId,
    String countryCode = 'global',
    String currency = 'EUR',
  }) async {
    final clean = productQuery.trim();
    if (clean.isEmpty || targetPrice <= 0) return null;
    try {
      final existing = await _col
          .where('userId', isEqualTo: userId)
          .where('productQuery', isEqualTo: clean)
          .where('targetPrice', isEqualTo: targetPrice)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return existing.docs.first.id;

      final doc = await _col.add({
        'userId': userId,
        'productId': clean,
        'productName': clean,
        'productQuery': clean,
        'targetPrice': targetPrice,
        'currency': currency,
        'countryCode': countryCode,
        'active': true,
        'triggered': false,
        'source': 'ai',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    if (alertId.trim().isEmpty) return false;
    try {
      await _col.doc(alertId.trim()).delete();
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
      await _col.doc(alertId.trim()).update({
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
      await _col.doc(alertId.trim()).update({
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
}
