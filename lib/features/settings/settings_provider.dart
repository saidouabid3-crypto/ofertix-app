import 'package:flutter/material.dart';

import 'settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();

  String language = 'es';
  String country = 'ES';
  String currency = 'EUR';
  bool darkMode = true;

  bool isLoading = true;

  Future<void> initialize() async {
    language = await _repository.getLanguage();
    country = await _repository.getCountry();
    currency = await _repository.getCurrency();

    isLoading = false;
    notifyListeners();
  }

  Future<void> changeLanguage(String value) async {
    language = value;
    await _repository.saveLanguage(value);
    notifyListeners();
  }

  Future<void> changeCountry({
    required String countryCode,
    required String currencyCode,
  }) async {
    country = countryCode;
    currency = currencyCode;

    await _repository.saveCountry(country: countryCode, currency: currencyCode);

    notifyListeners();
  }

  Future<void> changeTheme(bool value) async {
    darkMode = value;
    await _repository.saveTheme(value);
    notifyListeners();
  }
}
