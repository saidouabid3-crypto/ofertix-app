import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class RewardsService {
  static Future<void> addCoins(int coins) async {
    final userId = FirebaseService.userId;
    if (userId == null) return;

    await FirebaseService.users().doc(userId).set({
      'coins': coins,
    }, SetOptions(merge: true));
  }
}
