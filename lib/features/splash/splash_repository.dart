import '../../services/settings_service.dart';

class SplashRepository {
  Future<String> getLanguage() {
    return SettingsService.language();
  }

  Future<String> getCountry() {
    return SettingsService.country();
  }

  Future<String> getCurrency() {
    return SettingsService.currency();
  }
}
