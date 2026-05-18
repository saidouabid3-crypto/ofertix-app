import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class OfertixApp extends StatelessWidget {
  const OfertixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ofertix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
