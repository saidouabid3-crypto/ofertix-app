import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1115);

  static const card = Color(0xFF1A1D24);

  static const card2 = Color(0xFF22252E);

  static const orange = Color(0xFFFF7A00);

  static const gray = Color(0xFF9CA3AF);

  static const green = Color(0xFF4CD964);

  static const red = Color(0xFFFF3B30);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,

      elevation: 0,

      centerTitle: true,
    ),

    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,

      secondary: AppColors.orange,

      surface: AppColors.card,
    ),
  );

  static ThemeData lightTheme = ThemeData.light().copyWith(
    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,

      secondary: AppColors.orange,
    ),
  );
}
