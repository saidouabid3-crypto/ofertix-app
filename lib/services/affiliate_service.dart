import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class AffiliateService {
  /// OPEN PRODUCT
  static Future<void> openProduct({
    required String productId,
    required String originalUrl,
    required String store,
  }) async {
    try {
      /// TRACK CLICK
      await ApiService().trackClick(productId: productId, store: store);

      /// GET AFFILIATE LINK
      final affiliateUrl = await ApiService().createAffiliateLink(
        productId: productId,
        originalUrl: originalUrl,
        store: store,
      );

      final finalUrl = affiliateUrl != null && affiliateUrl.isNotEmpty
          ? affiliateUrl
          : originalUrl;

      await _launch(finalUrl);
    } catch (_) {
      /// FALLBACK
      await _launch(originalUrl);
    }
  }

  /// SIMPLE OPEN
  static Future<void> open(String url) async {
    if (url.isEmpty) return;

    await _launch(url);
  }

  /// INTERNAL LAUNCH
  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
