import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color.fromARGB(255, 255, 103, 1);
  static const Color secondary = Color.fromARGB(255, 253, 169, 1);
  static const Color teal = Color.fromARGB(255, 255, 124, 1);
  static const Color emerald = Color.fromARGB(255, 255, 154, 2);

  // Core brand
  static const Color orange = Color(0xFFFF8A00);
  static const Color orange2 = Color(0xFFFF6B00);
  static const Color redOrange = Color(0xFFFF3D1F);
  static const Color yellow = Color.fromARGB(255, 255, 109, 18);
  static const Color red = Color(0xFFFF3B30);
  static const Color green = Color(0xFF22C55E);

  // Dark backgrounds
  static const Color background = Color(0xFF071318);
  static const Color background2 = Color(0xFF0B1F26);
  static const Color dark = Color(0xFF061015);

  // Cards and surfaces
  static const Color card = Color(0xFF10232B);
  static const Color card2 = Color(0xFF17313A);
  static const Color glass = Color(0xCC10232B);

  // UI elements
  static const Color border = Color(0x1AFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFF8FAFC);
  static const Color gray = Color(0xFFA7B0B8);
  static const Color muted = Color(0xFF6B7A86);
  static const Color input = Color(0xFF122A33);
  static const Color inputBorder = Color(0x2634F5C5);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color lightBackground2 = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCard2 = Color(0xFFF0F6F8);
  static const Color lightGlass = Color(0xEFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightGray = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFF0F172A);

  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A00), Color(0xFFFF3D1F)],
  );
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1F26), Color(0xFF071318)],
  );
  static const LinearGradient primaryGradient = orangeGradient;
  static const LinearGradient logoGradient = orangeGradient;
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
  );
}

class AppThemeColors {
  AppThemeColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? AppColors.background : AppColors.lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? AppColors.card : AppColors.lightCard;

  static Color surfaceSoft(BuildContext context) =>
      isDark(context) ? AppColors.card2 : AppColors.lightCard2;

  static Color text(BuildContext context) =>
      isDark(context) ? AppColors.text : AppColors.lightText;

  static Color muted(BuildContext context) =>
      isDark(context) ? AppColors.gray : AppColors.lightGray;

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.border : AppColors.lightBorder;

  static Color shadow(BuildContext context) =>
      Colors.black.withValues(alpha: isDark(context) ? 0.32 : 0.06);

  static LinearGradient pageGradient(BuildContext context) =>
      isDark(context) ? AppColors.darkGradient : AppColors.lightGradient;
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
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,

      secondary: AppColors.orange,

      surface: AppColors.lightCard,
    ),
  );
}
