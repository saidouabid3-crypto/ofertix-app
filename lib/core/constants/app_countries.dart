class AppCountries {
  static const supported = <Map<String, String>>[
    {'code': 'ES', 'name': 'Spain', 'currency': 'EUR'},
    {'code': 'FR', 'name': 'France', 'currency': 'EUR'},
    {'code': 'MA', 'name': 'Morocco', 'currency': 'MAD'},
    {'code': 'PT', 'name': 'Portugal', 'currency': 'EUR'},
    {'code': 'IT', 'name': 'Italy', 'currency': 'EUR'},
    {'code': 'DE', 'name': 'Germany', 'currency': 'EUR'},
    {'code': 'US', 'name': 'United States', 'currency': 'USD'},
    {'code': 'OTHER', 'name': 'Other', 'currency': 'EUR'},
  ];

  static String currencyFor(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    return supported.firstWhere(
          (country) => country['code'] == code,
          orElse: () => supported.last,
        )['currency'] ??
        'EUR';
  }
}
