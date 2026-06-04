class PriceUtils {
  PriceUtils._();

  static String formatPrice(double price, String currency) {
    if (price <= 0) return '';
    final c = currency.trim().toUpperCase();
    final f = price.toStringAsFixed(2);
    switch (c) {
      case 'EUR':
        return '$f€';
      case 'USD':
        return '\$$f';
      case 'GBP':
        return '£$f';
      case 'JPY':
        return '¥${price.toStringAsFixed(0)}';
      case 'MAD':
        return '$f MAD';
      case 'DZD':
        return '$f DZD';
      default:
        return c.isEmpty ? '$f€' : '$f $c';
    }
  }
}
