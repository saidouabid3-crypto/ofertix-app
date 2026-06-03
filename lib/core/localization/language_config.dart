import 'package:flutter/material.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRtl = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRtl;

  Locale get locale => Locale(code);
}

class LanguageConfig {
  LanguageConfig._();

  static const String defaultLanguageCode = 'es';
  static const Locale defaultLocale = Locale(defaultLanguageCode);

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇲🇦', isRtl: true),
    AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
  ];

  static List<Locale> get supportedLocales =>
      supportedLanguages.map((language) => language.locale).toList();

  static List<String> get supportedCodes =>
      supportedLanguages.map((language) => language.code).toList();

  static String normalize(String? languageCode) {
    final clean = (languageCode ?? '').trim().toLowerCase();
    if (clean.isEmpty) return defaultLanguageCode;

    final shortCode = clean.split(RegExp('[-_]')).first;
    if (supportedCodes.contains(shortCode)) return shortCode;

    return defaultLanguageCode;
  }

  static bool isRtl(String languageCode) {
    final clean = normalize(languageCode);
    return supportedLanguages.any(
      (language) => language.code == clean && language.isRtl,
    );
  }

  static AppLanguage byCode(String languageCode) {
    final clean = normalize(languageCode);
    return supportedLanguages.firstWhere(
      (language) => language.code == clean,
      orElse: () => supportedLanguages.first,
    );
  }
}
