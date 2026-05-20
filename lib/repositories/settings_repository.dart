import '../services/settings_service.dart';

class SettingsRepository {
  Future<String> language() {
    return SettingsService.language();
  }

  Future<String> country() {
    return SettingsService.country();
  }

  Future<String> currency() {
    return SettingsService.currency();
  }

  Future<void> saveLanguage(String language) {
    return SettingsService.saveLanguage(language);
  }

  Future<void> saveCountry({
    required String country,
    required String currency,
  }) {
    return SettingsService.saveCountry(country: country, currency: currency);
  }

  Future<void> saveTheme(bool dark) {
    return SettingsService.saveTheme(dark);
  }
}
