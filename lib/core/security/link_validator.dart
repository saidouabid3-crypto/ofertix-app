class LinkValidator {
  static bool isSafeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  static bool isAffiliateUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('tag=') ||
        lower.contains('affiliate') ||
        lower.contains('aff') ||
        lower.contains('tracking');
  }
}
