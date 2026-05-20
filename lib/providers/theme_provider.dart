import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('theme_mode') ?? 'dark';

    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;

    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;

    await prefs.setString('theme_mode', dark ? 'dark' : 'light');

    notifyListeners();
  }
}
