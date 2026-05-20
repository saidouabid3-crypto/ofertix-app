import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  String language = 'es';
  String country = 'ES';
  String currency = 'EUR';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    language = prefs.getString('language') ?? 'es';

    country = prefs.getString('country') ?? 'ES';

    currency = prefs.getString('currency') ?? 'EUR';

    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();

    language = value;

    await prefs.setString('language', value);

    notifyListeners();
  }

  Future<void> setCountry(String value, String currencyValue) async {
    final prefs = await SharedPreferences.getInstance();

    country = value;
    currency = currencyValue;

    await prefs.setString('country', value);

    await prefs.setString('currency', currencyValue);

    notifyListeners();
  }
}
