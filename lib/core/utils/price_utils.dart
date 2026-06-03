class PriceUtils {
  static String formatPrice(dynamic price, String currency) {
    final value = double.tryParse(price.toString()) ?? 0;

    if (currency == 'EUR') return '${value.toStringAsFixed(2)} €';
    if (currency == 'USD') return '\$${value.toStringAsFixed(2)}';
    if (currency == 'MAD') return '${value.toStringAsFixed(2)} MAD';

    return '${value.toStringAsFixed(2)} $currency';
  }
}
