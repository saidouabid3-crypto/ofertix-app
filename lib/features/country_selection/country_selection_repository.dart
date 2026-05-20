import '../../services/settings_service.dart';

class CountrySelectionRepository {
  Future<void> saveCountry({
    required String country,
    required String currency,
  }) {
    return SettingsService.saveCountry(country: country, currency: currency);
  }
}
