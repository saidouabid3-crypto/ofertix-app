import '../core/config/api_endpoints.dart';
import '../models/home_feed.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'country_service.dart';

class HomeFeedService {
  HomeFeedService._();
  static final HomeFeedService instance = HomeFeedService._();

  final ApiService _api = ApiService.instance;

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
    final country = await _country(countryCode);
    final response = await _api.get(
      ApiEndpoints.homeFeedForCountry(
        country: country,
        limit: 30,
        userId: userId,
      ),
    );
    if (response is Map)
      return HomeFeed.fromMap(Map<String, dynamic>.from(response));
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
