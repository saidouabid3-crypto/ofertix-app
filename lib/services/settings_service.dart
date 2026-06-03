import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/language_config.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String _countryKey = 'selected_country';
  static const String _currencyKey = 'selected_currency';
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'selected_theme';
  static const String _firstLaunchKey = 'first_launch';
  static const String _marketConfirmedKey = 'market_confirmed';
  static const String _marketSourceKey = 'market_source';
  static const String _marketConfidenceKey = 'market_confidence';

  Future<void> setCountry(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, countryCode.trim().toLowerCase());
  }

  Future<String> getCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_countryKey) ?? 'es').trim().toLowerCase();
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.trim().toUpperCase());
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'EUR';
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanCode = LanguageConfig.normalize(languageCode);
    await prefs.setString(_languageKey, cleanCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    return LanguageConfig.normalize(savedCode);
  }

  Future<bool> hasSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    return savedCode != null && savedCode.trim().isNotEmpty;
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, enabled);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> setFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setMarketConfirmed(bool confirmed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketConfirmedKey, confirmed);
  }

  Future<bool> isMarketConfirmed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_marketConfirmedKey) ?? false;
  }

  Future<void> setMarketSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_marketSourceKey, source);
  }

  Future<String> getMarketSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_marketSourceKey) ?? 'unknown';
  }

  Future<void> setMarketConfidence(double confidence) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_marketConfidenceKey, confidence);
  }

  Future<double> getMarketConfidence() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_marketConfidenceKey) ?? 0;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String> language() => instance.getLanguage();

  static Future<String> country() => instance.getCountry();

  static Future<String> currency() => instance.getCurrency();

  static Future<void> saveLanguage(String language) {
    return instance.setLanguage(language);
  }

  static Future<void> saveCountry({
    required String country,
    required String currency,
  }) async {
    await instance.setCountry(country);
    await instance.setCurrency(currency);
  }

  static Future<void> saveTheme(bool dark) => instance.setDarkMode(dark);
}
