import '../../repositories/cashback_repository.dart';

class CashbackFeatureRepository {
  final CashbackRepository _repository = CashbackRepository();

  Future<Map<String, dynamic>> calculate({
    required double price,
    required double percent,
  }) {
    return _repository.cashbackPreview(price: price, percent: percent);
  }
}
