import 'package:flutter/material.dart';

class AppColors {
  // Main backgrounds
  static const Color background = Color(0xFF071318);
  static const Color background2 = Color(0xFF0B1F26);
  static const Color dark = Color(0xFF061015);

  // Cards / surfaces
  static const Color card = Color(0xFF10232B);
  static const Color card2 = Color(0xFF17313A);
  static const Color glass = Color(0xCC10232B);
  static const Color border = Color(0x1AFFFFFF);

  // Brand colors
  static const Color primary = Color(0xFF00C896);
  static const Color secondary = Color(0xFF00E0B8);
  static const Color teal = Color(0xFF00C2A8);
  static const Color emerald = Color(0xFF00B981);

  // Accent colors
  static const Color orange = Color(0xFFFF8A00);
  static const Color yellow = Color(0xFFFFC857);
  static const Color red = Color(0xFFFF3B30);
  static const Color green = Color(0xFF22C55E);

  // Text colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFF8FAFC);
  static const Color gray = Color(0xFFA7B0B8);
  static const Color muted = Color(0xFF6B7A86);

  // Inputs
  static const Color input = Color(0xFF122A33);
  static const Color inputBorder = Color(0x2634F5C5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E0B8), Color(0xFF00B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF071318), Color(0xFF0B1F26), Color(0xFF061015)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFFB020), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
