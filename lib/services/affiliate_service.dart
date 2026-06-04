import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class AffiliateService {
  AffiliateService._();

  static final AffiliateService instance = AffiliateService._();

  /// Open product — tracks the click, creates affiliate link if available,
  /// then launches externally. Falls back to direct launch if backend fails.
  Future<void> openProduct({
    required String url,
    required String productId,
    String countryCode = 'es',
    String store = '',
  }) async {
    final normalized = _normalize(url);
    debugPrint('[AffiliateService] openProduct id=$productId '
        'rawUrl=${url.isNotEmpty ? "present" : "EMPTY"} '
        'normalized=${normalized.isNotEmpty ? "ok" : "EMPTY"}');

    if (normalized.isEmpty) {
      debugPrint('[AffiliateService] No valid URL — aborting');
      throw Exception('no_url');
    }

    String finalUrl = normalized;
    try {
      await ApiService.instance.trackClick(productId: productId, store: store);
      final affiliateUrl = await ApiService.instance.createAffiliateLink(
        productId: productId,
        originalUrl: normalized,
        store: store,
      );
      if (affiliateUrl != null && affiliateUrl.isNotEmpty) {
        finalUrl = affiliateUrl;
        debugPrint('[AffiliateService] Using backend affiliate URL');
      } else {
        debugPrint('[AffiliateService] No affiliate URL from backend — using original');
      }
    } catch (e) {
      debugPrint('[AffiliateService] Backend error, using original URL: $e');
    }

    await _launch(finalUrl);
  }

  /// Static API for backward compat.
  static Future<void> openProductStatic({
    required String productId,
    required String originalUrl,
    required String store,
  }) async {
    final normalized = _normalize(originalUrl);
    if (normalized.isEmpty) return;

    String finalUrl = normalized;
    try {
      await ApiService.instance.trackClick(productId: productId, store: store);
      final affiliateUrl = await ApiService.instance.createAffiliateLink(
        productId: productId,
        originalUrl: normalized,
        store: store,
      );
      if (affiliateUrl != null && affiliateUrl.isNotEmpty) {
        finalUrl = affiliateUrl;
      }
    } catch (_) {}

    await _launch(finalUrl);
  }

  static Future<void> open(String url) async {
    final normalized = _normalize(url);
    if (normalized.isEmpty) return;
    await _launch(normalized);
  }

  /// Normalize URL: add https:// if scheme is missing.
  static String _normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('www.')) url = 'https://$url';
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        url.contains('.')) {
      url = 'https://$url';
    }
    // Validate it can be parsed
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '';
    return url;
  }

  /// Launch URL externally. Does NOT use canLaunchUrl guard because on
  /// Android 11+ that requires explicit `<queries>` entries which may not
  /// cover all redirect chains. We launch directly and catch failures.
  static Future<void> _launch(String url) async {
    final normalized = _normalize(url);
    if (normalized.isEmpty) {
      debugPrint('[AffiliateService] _launch: empty URL after normalize');
      return;
    }
    final uri = Uri.parse(normalized);
    debugPrint('[AffiliateService] Launching: ${uri.scheme}://${uri.host}…');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('[AffiliateService] launchUrl returned false for ${uri.host}');
      }
    } catch (e) {
      debugPrint('[AffiliateService] Launch exception: $e');
      rethrow;
    }
  }
}
