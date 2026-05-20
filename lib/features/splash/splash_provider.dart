import 'package:flutter/material.dart';

import 'splash_repository.dart';

class SplashProvider extends ChangeNotifier {
  final SplashRepository _repository = SplashRepository();

  bool isLoading = true;

  String language = 'es';

  String country = 'ES';

  String currency = 'EUR';

  Future<void> initialize() async {
    try {
      language = await _repository.getLanguage();

      country = await _repository.getCountry();

      currency = await _repository.getCurrency();
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
