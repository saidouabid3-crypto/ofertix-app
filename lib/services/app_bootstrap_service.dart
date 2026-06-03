import 'country_detection_service.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.countryCode,
    required this.source,
    required this.confidence,
    required this.recoveredFromTimeout,
  });
  final String countryCode;
  final String source;
  final double confidence;
  final bool recoveredFromTimeout;
}

class AppBootstrapService {
  AppBootstrapService._();
  static final AppBootstrapService instance = AppBootstrapService._();

  Future<AppBootstrapResult> initialize() async {
    try {
      final detected = await CountryDetectionService.instance.detectAndSave();
      return AppBootstrapResult(
        countryCode: detected.countryCode,
        source: detected.source,
        confidence: detected.confidence,
        recoveredFromTimeout: false,
      );
    } catch (_) {
      final fallback = await CountryDetectionService.instance.detectCountry();
      return AppBootstrapResult(
        countryCode: fallback.countryCode,
        source: fallback.source,
        confidence: fallback.confidence,
        recoveredFromTimeout: true,
      );
    }
  }
}
