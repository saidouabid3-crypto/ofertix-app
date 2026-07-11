import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final dark = await SettingsService.instance.isDarkMode();
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;

    await SettingsService.instance.setDarkMode(dark);

    notifyListeners();
  }
}
