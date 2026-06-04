import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

class RewardsService {
  /// Increments the user's coin balance by [coins] in Firestore.
  /// Uses FieldValue.increment so concurrent writes are safe.
  static Future<void> addCoins(int coins) async {
    final userId = FirebaseService.userId;
    if (userId == null) return;
    await FirebaseService.users().doc(userId).set({
      'coins': FieldValue.increment(coins),
    }, SetOptions(merge: true));
  }

  /// Returns the user's current coin balance from Firestore.
  /// Returns 0 if not authenticated or if no coins have been earned yet.
  static Future<int> getCoins() async {
    final userId = FirebaseService.userId;
    if (userId == null) return 0;
    try {
      final doc = await FirebaseService.users().doc(userId).get();
      return (doc.data()?['coins'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
