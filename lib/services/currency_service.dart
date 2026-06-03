class CurrencyService {
  static String symbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'MAD':
        return 'MAD';
      default:
        return currency;
    }
  }

  static String format(double price, String currency) {
    final value = price.toStringAsFixed(2);
    final s = symbol(currency);

    if (currency.toUpperCase() == 'EUR') return '$value €';
    if (currency.toUpperCase() == 'MAD') return '$value MAD';

    return '$s$value';
  }
}
