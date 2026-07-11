import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThemeProvider loads the saved app theme', () async {
    SharedPreferences.setMockInitialValues({'selected_theme': true});

    final provider = ThemeProvider();
    await provider.loadTheme();

    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.isDark, isTrue);
  });

  test('ThemeProvider toggles and persists light and dark mode', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = ThemeProvider();
    await provider.loadTheme();
    expect(provider.themeMode, ThemeMode.light);

    await provider.toggleTheme(true);
    expect(provider.themeMode, ThemeMode.dark);

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('selected_theme'), isTrue);

    await provider.toggleTheme(false);
    expect(provider.themeMode, ThemeMode.light);

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('selected_theme'), isFalse);
  });
}
