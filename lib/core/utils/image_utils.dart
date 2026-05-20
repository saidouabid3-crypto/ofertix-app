class ImageUtils {
  static bool isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http') &&
        (lower.contains('.jpg') ||
            lower.contains('.jpeg') ||
            lower.contains('.png') ||
            lower.contains('.webp') ||
            lower.contains('images'));
  }
}
