import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class AffiliateService {
  AffiliateService._();

  static final AffiliateService instance = AffiliateService._();

  /// Open product — instance API used by product_details_screen (Batch 10).
  Future<void> openProduct({
    required String url,
    required String productId,
    String countryCode = 'es',
    String store = '',
  }) async {
    try {
      await ApiService.instance.trackClick(productId: productId, store: store);
      final affiliateUrl = await ApiService.instance.createAffiliateLink(
        productId: productId,
        originalUrl: url,
        store: store,
      );
      final finalUrl =
          (affiliateUrl != null && affiliateUrl.isNotEmpty) ? affiliateUrl : url;
      await _launch(finalUrl);
    } catch (_) {
      await _launch(url);
    }
  }

  /// Static API for backward compat.
  static Future<void> openProductStatic({
    required String productId,
    required String originalUrl,
    required String store,
  }) async {
    try {
      await ApiService.instance.trackClick(productId: productId, store: store);
      final affiliateUrl = await ApiService.instance.createAffiliateLink(
        productId: productId,
        originalUrl: originalUrl,
        store: store,
      );
      final finalUrl = (affiliateUrl != null && affiliateUrl.isNotEmpty)
          ? affiliateUrl
          : originalUrl;
      await _launch(finalUrl);
    } catch (_) {
      await _launch(originalUrl);
    }
  }

  static Future<void> open(String url) async {
    if (url.isEmpty) return;
    await _launch(url);
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
