import 'settings_service.dart';

class CountryService {
  CountryService._();

  static final CountryService instance = CountryService._();

  static String normalize(String code) {
    return code.trim().toLowerCase();
  }

  static bool isGlobal(String country) {
    return country.toLowerCase() == 'global';
  }

  Future<String> getCurrentCountry() => SettingsService.instance.getCountry();

  Future<bool> isCountryConfirmed() {
    return SettingsService.instance.isMarketConfirmed();
  }

  Future<void> setDetectedCountry(
    String countryCode, {
    String source = 'detected',
    double confidence = 0,
    bool confirmed = false,
  }) async {
    await SettingsService.instance.setCountry(normalize(countryCode));
    await SettingsService.instance.setMarketSource(source);
    await SettingsService.instance.setMarketConfidence(confidence);
    await SettingsService.instance.setMarketConfirmed(confirmed);
  }

  String getCountryCurrency(String countryCode) {
    switch (normalize(countryCode)) {
      case 'us':
        return 'USD';
      case 'gb':
      case 'uk':
        return 'GBP';
      case 'ma':
        return 'MAD';
      case 'fr':
      case 'de':
      case 'it':
      case 'pt':
      case 'es':
      default:
        return 'EUR';
    }
  }

  String getCountryFlag(String countryCode) {
    switch (normalize(countryCode)) {
      case 'us':
        return '🇺🇸';
      case 'gb':
      case 'uk':
        return '🇬🇧';
      case 'ma':
        return '🇲🇦';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'es':
      default:
        return '🇪🇸';
    }
  }

  String getCountryName(String countryCode) {
    switch (normalize(countryCode)) {
      case 'us':
        return 'United States';
      case 'gb':
      case 'uk':
        return 'United Kingdom';
      case 'ma':
        return 'Morocco';
      case 'fr':
        return 'France';
      case 'de':
        return 'Germany';
      case 'it':
        return 'Italy';
      case 'pt':
        return 'Portugal';
      case 'es':
      default:
        return 'Spain';
    }
  }
}
