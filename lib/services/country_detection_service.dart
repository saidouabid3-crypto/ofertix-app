import 'dart:async';
import 'dart:ui' as ui;

import 'package:geolocator/geolocator.dart';

import 'country_service.dart';
import 'market_service.dart';

class CountryDetectionResult {
  const CountryDetectionResult({
    required this.countryCode,
    required this.currency,
    required this.language,
    required this.source,
    required this.confidence,
  });

  final String countryCode;
  final String currency;
  final String language;
  final String source;
  final double confidence;
  bool get isReliable => confidence >= 0.70;
}

class CountryDetectionService {
  CountryDetectionService._();
  static final CountryDetectionService instance = CountryDetectionService._();

  final MarketService _markets = MarketService.instance;

  Future<CountryDetectionResult> detectCountry({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return _detect().timeout(
      timeout,
      onTimeout: () => _fromLocale(source: 'timeout_locale'),
    );
  }

  Future<CountryDetectionResult> detectAndSave({bool force = false}) async {
    final country = CountryService.instance;
    if (!force) {
      final saved = await country.getCurrentCountry();
      final confirmed = await country.isCountryConfirmed();
      if (confirmed && _markets.isSupported(saved))
        return _result(saved, 'saved', 1);
    }
    final detected = await detectCountry();
    await country.setDetectedCountry(
      detected.countryCode,
      source: detected.source,
      confidence: detected.confidence,
      confirmed: detected.isReliable,
    );
    return detected;
  }

  Future<CountryDetectionResult> _detect() async {
    final gps = await _fromGrantedGps();
    if (gps != null && gps.isReliable) return gps;
    return _fromLocale(source: 'device_region');
  }

  Future<CountryDetectionResult?> _fromGrantedGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse)
        return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 2),
        ),
      );
      final code = _countryFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (code == null) return null;
      return _result(code, 'gps', 0.96);
    } catch (_) {
      return null;
    }
  }

  CountryDetectionResult _fromLocale({required String source}) {
    final locale = ui.PlatformDispatcher.instance.locale;
    final country = locale.countryCode?.trim().toLowerCase();
    if (country != null && _markets.isSupported(country))
      return _result(country, source, 0.88);
    final lang = locale.languageCode.trim().toLowerCase();
    final byLang = _countryFromLanguage(lang);
    if (byLang != null) return _result(byLang, 'language_region', 0.72);
    return _result('es', 'default_launch_market', 0.60);
  }

  String? _countryFromLanguage(String lang) {
    switch (lang) {
      case 'es':
      case 'ca':
      case 'eu':
      case 'gl':
        return 'es';
      case 'fr':
        return 'fr';
      case 'de':
        return 'de';
      case 'it':
        return 'it';
      case 'pt':
        return 'pt';
      case 'ar':
        return 'ma';
      case 'en':
        return 'uk';
      default:
        return null;
    }
  }

  String? _countryFromCoordinates(double lat, double lng) {
    bool box(double a, double b, double c, double d) =>
        lat >= a && lat <= b && lng >= c && lng <= d;
    if (box(36.0, 43.9, -9.5, 4.5) || box(27.4, 29.6, -18.4, -13.0))
      return 'es';
    if (box(21.0, 36.2, -17.2, -1.0)) return 'ma';
    if (box(18.8, 37.2, -8.8, 12.1)) return 'dz';
    if (box(41.0, 51.5, -5.4, 9.8)) return 'fr';
    if (box(47.1, 55.2, 5.5, 15.5)) return 'de';
    if (box(35.4, 47.2, 6.2, 18.8)) return 'it';
    if (box(36.8, 42.3, -9.7, -6.0)) return 'pt';
    if (box(49.0, 61.0, -8.8, 2.2)) return 'uk';
    if (box(24.0, 49.8, -125.0, -66.0)) return 'us';
    if (box(42.0, 83.0, -141.0, -52.0)) return 'ca';
    if (box(22.0, 32.2, 24.5, 36.9)) return 'eg';
    if (box(16.0, 32.5, 34.0, 56.0)) return 'sa';
    if (box(22.5, 26.5, 51.0, 56.6)) return 'ae';
    if (box(14.0, 32.9, -118.5, -86.0)) return 'mx';
    return null;
  }

  CountryDetectionResult _result(
    String code,
    String source,
    double confidence,
  ) {
    final market = _markets.market(code);
    return CountryDetectionResult(
      countryCode: market.code,
      currency: market.currency,
      language: market.defaultLanguage,
      source: source,
      confidence: confidence,
    );
  }
}
