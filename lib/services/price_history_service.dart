import 'firebase_service.dart';
import '../models/price_history_model.dart';

class PriceHistoryService {
  static final PriceHistoryService instance = PriceHistoryService();

  static Future<void> addPrice({
    required String productId,
    required double price,
  }) async {
    await FirebaseService.products()
        .doc(productId)
        .collection('price_history')
        .add({'price': price, 'date': DateTime.now().toIso8601String()});
  }

  Future<List<PriceHistoryModel>> getHistory(String productId) async {
    final snapshot = await FirebaseService.products()
        .doc(productId)
        .collection('price_history')
        .orderBy('date', descending: true)
        .limit(60)
        .get();

    return snapshot.docs
        .map((doc) => PriceHistoryModel.fromMap(doc.data()))
        .toList();
  }
}
