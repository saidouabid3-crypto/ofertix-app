import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_endpoints.dart';
import '../models/home_feed.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'country_service.dart';

class HomeFeedService {
  HomeFeedService._();
  static final HomeFeedService instance = HomeFeedService._();

  final ApiService _api = ApiService.instance;

  static const String _seenKey = 'ofertix_seen_products_v1';
  static const int _maxSeen = 80;
  static const int _maxSeenParam = 50;

  // In-session seen product IDs — persisted via SharedPreferences across restarts
  final List<String> _seenIds = [];
  bool _seenLoaded = false;

  // Variant cycles on pull-to-refresh; initialized to random 0-9 on first run
  int _variantIndex = Random().nextInt(10);

  /// Called by HomeProvider before re-fetching on pull-to-refresh.
  void rotateVariant() {
    _variantIndex = (_variantIndex + 1) % 10;
  }

  String _sessionVariant() => _variantIndex.toString();

  Future<void> _ensureSeenLoaded() async {
    if (_seenLoaded) return;
    _seenLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_seenKey) ?? [];
      for (final id in stored.take(_maxSeen)) {
        if (!_seenIds.contains(id)) _seenIds.add(id);
      }
    } catch (_) {}
  }

  void markSeen(String productId) {
    if (productId.isEmpty || _seenIds.contains(productId)) return;
    _seenIds.add(productId);
    if (_seenIds.length > _maxSeen) _seenIds.removeAt(0);
    _persistSeen();
  }

  void _persistSeen() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(_seenKey, List<String>.from(_seenIds));
    }).catchError((_) {});
  }

  Future<String> _country([String countryCode = 'auto']) async {
    if (countryCode == 'auto' || countryCode == 'global') {
      return CountryService.instance.getCurrentCountry();
    }
    return countryCode;
  }

  Future<HomeFeed> getHomeFeed({
    String countryCode = 'auto',
    String? userId,
  }) async {
    await _ensureSeenLoaded();
    final country = await _country(countryCode);
    final variant = _sessionVariant();

    // Send the most recently seen IDs (last _maxSeenParam, capped)
    final recentSeen = _seenIds.length > _maxSeenParam
        ? _seenIds.sublist(_seenIds.length - _maxSeenParam)
        : List<String>.from(_seenIds);
    final seenParam = recentSeen.isNotEmpty ? recentSeen.join(',') : null;

    final response = await _api.get(
      ApiEndpoints.homeFeedForCountry(
        country: country,
        limit: 40,
        userId: userId,
        variant: variant,
        seenIds: seenParam,
      ),
    );
    if (response is Map) {
      return HomeFeed.fromMap(Map<String, dynamic>.from(response));
    }
    return HomeFeed.empty();
  }

  Future<ProductDetailAi?> getProductDetailAi(
    Product product, {
    String countryCode = 'auto',
  }) async {
    final country = await _country(countryCode);
    try {
      final response = await _api.get(
        ApiEndpoints.productDetailForCountry(product.id, country),
      );
      if (response is Map && response['ok'] != false) {
        return ProductDetailAi.fromMap(
          Map<String, dynamic>.from(response),
          product,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> trackProductView(Product product) async {
    markSeen(product.id);
    try {
      await _api.post(
        ApiEndpoints.eventProductView,
        body: {
          'productId': product.id,
          'store': product.store,
          'category': product.categoryGroup,
        },
      );
    } catch (_) {}
  }

  Future<void> trackOfferClick(Product product) async {
    markSeen(product.id);
    try {
      await _api.post(
        ApiEndpoints.eventOfferClick,
        body: {
          'productId': product.id,
          'store': product.store,
          'category': product.categoryGroup,
        },
      );
    } catch (_) {}
  }

  Future<void> reportProduct(Product product, String reason) async {
    try {
      await _api.post(
        ApiEndpoints.eventReportProduct,
        body: {
          'productId': product.id,
          'reason': reason,
          'store': product.store,
        },
      );
    } catch (_) {}
  }
}
