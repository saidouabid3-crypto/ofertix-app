import 'package:flutter/material.dart';

class LocalizationService {
  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
  ];

  static const fallbackLocale = Locale('es');

  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ar';
  }
}
