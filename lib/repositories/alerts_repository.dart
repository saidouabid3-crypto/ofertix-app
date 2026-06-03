import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';

class AlertsRepository {
  static final AlertsRepository instance = AlertsRepository();

  Future<void> initializeNotifications() async {}

  Stream<QuerySnapshot<Map<String, dynamic>>> userAlerts() {
    final userId = FirebaseService.userId;

    return FirebaseService.alerts()
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchAlerts({
    required String userId,
  }) {
    return FirebaseService.alerts()
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAlertsOnce({
    required String userId,
  }) async {
    final snapshot = await FirebaseService.alerts()
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs;
  }

  Future<String?> createAlert({
    required String productId,
    required double targetPrice,
  }) async {
    final userId = FirebaseService.userId;

    if (userId == null) return null;

    final doc = await FirebaseService.alerts().add({
      'userId': userId,
      'productId': productId,
      'targetPrice': targetPrice,
      'active': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return doc.id;
  }

  Future<String?> createProductAlert({
    required Product product,
    required double targetPrice,
    required String userId,
  }) async {
    final doc = await FirebaseService.alerts().add({
      'userId': userId,
      'type': 'product',
      'productId': product.id,
      'productName': product.name,
      'productImage': product.image,
      'store': product.store,
      'currency': product.currency,
      'currentPrice': product.newPrice,
      'targetPrice': targetPrice,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<String?> createAiAlert({
    required String productQuery,
    required double targetPrice,
    required String userId,
  }) async {
    final doc = await FirebaseService.alerts().add({
      'userId': userId,
      'type': 'ai',
      'productQuery': productQuery,
      'targetPrice': targetPrice,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      await FirebaseService.alerts().doc(alertId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAlertActive({
    required String alertId,
    required bool active,
  }) async {
    try {
      await FirebaseService.alerts().doc(alertId).update({'active': active});
      return true;
    } catch (_) {
      return false;
    }
  }
}
