import 'firebase_service.dart';

class PriceHistoryService {
  static Future<void> addPrice({
    required String productId,
    required double price,
  }) async {
    await FirebaseService.products()
        .doc(productId)
        .collection('price_history')
        .add({'price': price, 'date': DateTime.now().toIso8601String()});
  }
}
