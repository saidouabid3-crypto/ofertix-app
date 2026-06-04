import 'package:flutter/material.dart';

import 'rewards_repository.dart';

class RewardsProvider extends ChangeNotifier {
  final RewardsFeatureRepository _repository = RewardsFeatureRepository();

  int coins = 0;
  bool isLoading = false;
  bool _loaded = false;

  RewardsProvider() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    if (_loaded) return;
    isLoading = true;
    notifyListeners();
    try {
      coins = await _repository.getCoins();
      _loaded = true;
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loaded = false;
    await _loadCoins();
  }
}
