import 'package:flutter/material.dart';

import 'cashback_repository.dart';

class CashbackProvider extends ChangeNotifier {
  final CashbackFeatureRepository _repository = CashbackFeatureRepository();

  bool isLoading = false;

  double cashback = 0;

  double finalPrice = 0;

  Future<void> calculate({
    required double price,
    required double percent,
  }) async {
    isLoading = true;

    notifyListeners();

    final result = await _repository.calculate(price: price, percent: percent);

    cashback = result['cashbackAmount'] ?? 0;

    finalPrice = result['finalPrice'] ?? 0;

    isLoading = false;

    notifyListeners();
  }
}
