import '../services/cashback_service.dart';

class CashbackRepository {
  Future<double> calculate({
    required double price,
    required double percent,
  }) async {
    return CashbackService.calculate(price: price, percent: percent);
  }

  Future<double> estimateProductCashback({
    required double productPrice,
    double cashbackPercent = 5,
  }) async {
    return CashbackService.calculate(
      price: productPrice,
      percent: cashbackPercent,
    );
  }

  Future<Map<String, dynamic>> cashbackPreview({
    required double price,
    required double percent,
  }) async {
    final cashback = CashbackService.calculate(price: price, percent: percent);

    return {
      'originalPrice': price,
      'cashbackPercent': percent,
      'cashbackAmount': cashback,
      'finalPrice': price - cashback,
    };
  }
}
