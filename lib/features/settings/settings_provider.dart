import 'package:flutter/material.dart';

import '../../core/constants/app_languages.dart';
import 'settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();

  String language = 'es';
  String country = 'ES';
  String currency = 'EUR';
  bool darkMode = true;

  bool isLoading = true;

  Future<void> initialize() async {
    final savedLanguage = await _repository.getLanguage();
    final supportedLanguageCodes = AppLanguages.supported
        .map((language) => language['code'])
        .whereType<String>()
        .toSet();
    language = supportedLanguageCodes.contains(savedLanguage)
        ? savedLanguage
        : 'es';
    if (language != savedLanguage) {
      await _repository.saveLanguage(language);
    }
    country = await _repository.getCountry();
    currency = await _repository.getCurrency();
    darkMode = await _repository.getTheme();

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
