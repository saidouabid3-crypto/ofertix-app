import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static Future<String> language() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'es';
  }

  static Future<String> country() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('country') ?? 'ES';
  }

  static Future<String> currency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? 'EUR';
  }

  static Future<void> saveLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  static Future<void> saveCountry({
    required String country,
    required String currency,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('country', country);
    await prefs.setString('currency', currency);
  }

  static Future<void> saveTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', dark ? 'dark' : 'light');
  }
}
