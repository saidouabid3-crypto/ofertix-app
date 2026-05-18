import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF6B00);
  static const dark = Color(0xFF0F0F0F);
  static const card = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF2A2A2D);
  static const gray = Color(0xFF9E9E9E);
  static const green = Color(0xFF52D66B);
  static const red = Color(0xFFFF4D4D);
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dark,
    primaryColor: AppColors.orange,
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      surface: AppColors.card,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F4F4),
    primaryColor: AppColors.orange,
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black),
      bodyLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: Colors.black),
    ),
  );
}
