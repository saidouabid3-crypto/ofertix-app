import '../../services/settings_service.dart';

class SettingsRepository {
  Future<String> getLanguage() {
    return SettingsService.language();
  }

  Future<String> getCountry() {
    return SettingsService.country();
  }

  Future<String> getCurrency() {
    return SettingsService.currency();
  }

  Future<bool> getTheme() {
    return SettingsService.instance.isDarkMode();
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
