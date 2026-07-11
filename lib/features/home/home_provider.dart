import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/home_feed.dart';
import '../../models/product.dart';
import '../../models/local_store_model.dart';
import '../../services/home_feed_service.dart';
import '../../services/local_engine_service.dart';
import '../../services/settings_service.dart';
import 'home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();
  final HomeFeedService _homeFeedService = HomeFeedService.instance;
  final LocalEngineService _localEngineService = LocalEngineService.instance;

  HomeFeed homeFeed = HomeFeed.empty();
  List<Product> products = [];
  List<Product> hotProducts = [];
  List<Product> featuredProducts = [];
  List<Product> globalOnlineProducts = [];
  List<Product> nearbyProducts = [];
  List<LocalStoreModel> localStores = [];
  // Discovery sections (Batch 14A)
  List<Product> forYouToday = [];
  List<Product> verifiedDeals = [];
  List<Product> freshArrivals = [];

  Position? userPosition;
  bool isLoading = true;
  String? errorMessage;

  int userPoints = 0;

  void markProductSeen(Product product) {
    _homeFeedService.markSeen(product.id);
  }

  Future<void> initialize({String? countryCode, bool isRefresh = false}) async {
    if (isRefresh) _homeFeedService.rotateVariant();
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _loadUserLocation();

    final country = countryCode ?? await SettingsService.instance.getCountry();

    try {
      homeFeed = await _homeFeedService.getHomeFeed(countryCode: country);
      products = _dedupe([
        ...homeFeed.heroDeals,
        ...homeFeed.hotDeals,
        ...homeFeed.globalOnline,
        ...homeFeed.topRated,
        ...homeFeed.bestSellers,
        ...homeFeed.under10,
        ...homeFeed.under25,
        ...homeFeed.recentlyAdded,
        ...homeFeed.surpriseDeals,
        ...homeFeed.recommended,
        ...homeFeed.products,
      ]);
      _buildDisplaySections();
      nearbyProducts = _filterNearbyProducts(products);
      localStores = await _loadLocalStores(country);
      // Mark top visible products as seen so next refresh demotes them
      for (final p in [...homeFeed.heroDeals, ...homeFeed.forYouToday]) {
        _homeFeedService.markSeen(p.id);
      }
    } catch (e) {
      errorMessage = e.toString();
      final fallback = await _repository
          .getProducts(countryCode: country)
          .first;
      products = fallback;
      _buildFallbackDisplaySections(fallback);
      nearbyProducts = _filterNearbyProducts(fallback);
      localStores = await _loadLocalStores(country);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<List<LocalStoreModel>> _loadLocalStores(String countryCode) async {
    try {
      return await _localEngineService.getFeaturedStores(
        countryCode: countryCode,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      userPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      userPosition = null;
    }
  }

  List<Product> _filterNearbyProducts(List<Product> allProducts) {
    final position = userPosition;
    if (position == null) return [];
    return allProducts.where((product) {
      if (product.isOnline || product.lat == 0.0 || product.lng == 0.0) {
        return false;
      }
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        product.lat,
        product.lng,
      );
      return distance <= 20000;
    }).toList();
  }

  double? getDistance(Product product) {
    final position = userPosition;
    if (position == null || product.lat == 0.0 || product.lng == 0.0) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      product.lat,
      product.lng,
    );
    return meters / 1000;
  }

  List<Product> get onlineProducts => globalOnlineProducts;
  List<Product> get localProducts =>
      products.where((product) => !product.isOnline).toList();
  List<HomeFacet> get stores => homeFeed.stores;
  List<HomeFacet> get categories => homeFeed.categories;

  List<Product> _dedupe(List<Product> items) {
    final seen = <String>{};
    final out = <Product>[];
    for (final item in items) {
      final key = item.fingerprint.isNotEmpty ? item.fingerprint : item.id;
      if (seen.add(key)) out.add(item);
    }
    return out;
  }

  void _buildDisplaySections() {
    final used = <String>{};
    hotProducts = _takeUnique(
      homeFeed.hotDeals.isNotEmpty
          ? homeFeed.hotDeals
          : products.where((p) => p.isHot || p.isTrending),
      used,
      8,
    );
    forYouToday = _takeUnique(homeFeed.forYouToday, used, 8);
    verifiedDeals = _takeUnique(homeFeed.verifiedDeals, used, 8);
    freshArrivals = _takeUnique(homeFeed.freshArrivals, used, 8);
    globalOnlineProducts = _takeUnique(
      homeFeed.globalOnline.isNotEmpty
          ? homeFeed.globalOnline
          : products.where((product) => product.isOnline),
      used,
      8,
    );
    featuredProducts = _takeUnique(
      [...homeFeed.topRated, ...homeFeed.bestSellers, ...homeFeed.trendingNow],
      used,
      8,
    );
    if (featuredProducts.isEmpty) {
      featuredProducts = _takeUnique(
        products.where((p) => p.featured || p.sponsored),
        used,
        8,
      );
    }
  }

  void _buildFallbackDisplaySections(List<Product> fallback) {
    final used = <String>{};
    hotProducts = _takeUnique(
      fallback.where((p) => p.isHot || p.isTrending),
      used,
      8,
    );
    forYouToday = [];
    verifiedDeals = [];
    freshArrivals = [];
    globalOnlineProducts = _takeUnique(
      fallback.where((product) => product.isOnline),
      used,
      8,
    );
    featuredProducts = _takeUnique(
      fallback.where((p) => p.featured || p.sponsored),
      used,
      8,
    );
  }

  List<Product> _takeUnique(
    Iterable<Product> items,
    Set<String> used,
    int limit,
  ) {
    final out = <Product>[];
    for (final item in items) {
      final keys = _identityKeys(item);
      if (keys.any(used.contains)) continue;
      used.addAll(keys);
      out.add(item);
      if (out.length >= limit) break;
    }
    return out;
  }

  List<String> _identityKeys(Product item) {
    final keys = <String>[];
    void add(String prefix, String value) {
      final text = value.trim().toLowerCase();
      if (text.isNotEmpty) keys.add('$prefix:$text');
    }

    add('id', item.id);
    add('url', _canonicalUrl(item.affiliateUrl));
    add('fp', item.fingerprint);
    return keys.toSet().toList();
  }

  String _canonicalUrl(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return text.toLowerCase();
    }
    final cleanQuery = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => key.toLowerCase().startsWith('utm_'));
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          query: cleanQuery.isEmpty
              ? ''
              : Uri(queryParameters: cleanQuery).query,
          fragment: '',
        )
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

}
