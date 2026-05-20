import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';

class AlertsRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> alerts() {
    final userId = FirebaseService.userId;

    return FirebaseService.alerts()
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> createAlert({
    required String productId,
    required double targetPrice,
  }) async {
    final userId = FirebaseService.userId;

    if (userId == null) return;

    await FirebaseService.alerts().add({
      'userId': userId,
      'productId': productId,
      'targetPrice': targetPrice,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteAlert(String alertId) async {
    await FirebaseService.alerts().doc(alertId).delete();
  }
}
