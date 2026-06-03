import 'package:flutter/material.dart';

import 'country_selection_repository.dart';

class CountrySelectionProvider extends ChangeNotifier {
  final CountrySelectionRepository _repository = CountrySelectionRepository();

  String selectedCountry = 'ES';

  String selectedCurrency = 'EUR';

  final List<Map<String, String>> countries = [
    {'country': 'ES', 'currency': 'EUR', 'name': 'Spain', 'flag': '🇪🇸'},

    {'country': 'FR', 'currency': 'EUR', 'name': 'France', 'flag': '🇫🇷'},

    {'country': 'DE', 'currency': 'EUR', 'name': 'Germany', 'flag': '🇩🇪'},

    {'country': 'IT', 'currency': 'EUR', 'name': 'Italy', 'flag': '🇮🇹'},

    {
      'country': 'US',
      'currency': 'USD',
      'name': 'United States',
      'flag': '🇺🇸',
    },

    {'country': 'MA', 'currency': 'MAD', 'name': 'Morocco', 'flag': '🇲🇦'},
  ];

  void select({required String country, required String currency}) {
    selectedCountry = country;

    selectedCurrency = currency;

    notifyListeners();
  }

  Future<void> save() async {
    await _repository.saveCountry(
      country: selectedCountry,
      currency: selectedCurrency,
    );
  }
}
