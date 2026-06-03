import 'package:flutter/material.dart';

import 'rewards_repository.dart';

class RewardsProvider extends ChangeNotifier {
  final RewardsFeatureRepository _repository = RewardsFeatureRepository();

  int coins = 0;

  bool isLoading = false;

  Future<void> earn(int amount) async {
    isLoading = true;
    notifyListeners();

    await _repository.addCoins(amount);

    coins += amount;

    isLoading = false;
    notifyListeners();
  }
}
