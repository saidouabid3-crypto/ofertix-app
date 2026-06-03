import 'package:flutter/material.dart';

class RewardsProvider extends ChangeNotifier {
  int coins = 0;

  void addCoins(int value) {
    coins += value;
    notifyListeners();
  }

  void resetCoins() {
    coins = 0;
    notifyListeners();
  }
}
