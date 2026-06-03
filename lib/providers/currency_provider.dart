import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  String currency = 'EUR';

  String get symbol {
    switch (currency.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'GBP':
        return '£';
      case 'MAD':
        return 'MAD';
      case 'EUR':
      default:
        return '€';
    }
  }

  void setCurrency(String value) {
    currency = value.trim().isEmpty ? 'EUR' : value.trim().toUpperCase();
    notifyListeners();
  }
}
