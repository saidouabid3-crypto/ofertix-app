import '../models/product.dart';
import '../models/products_page.dart';

import '../services/product_service.dart';
import '../services/api_service.dart';

import '../core/storage/cache_service.dart';

class ProductRepository {
  final ProductService _productService = ProductService();

  // =========================
  // LIVE PRODUCTS
  // =========================

  Stream<List<Product>> getProducts({String countryCode = 'es'}) {
    return _productService.getProducts(countryCode: countryCode);
  }

  Stream<List<Product>> getHotProducts({String countryCode = 'es'}) {
    return _productService.getHotProducts(countryCode: countryCode);
  }

  Stream<List<Product>> getFeaturedProducts({String countryCode = 'es'}) {
    return _productService.getFeaturedProducts(countryCode: countryCode);
  }

  // =========================
  // SMART SEARCH
  // =========================

  Future<List<Product>> searchProducts(
    String query, {
    String countryCode = 'es',
    bool forceRefresh = false,
  }) async {
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) return [];

    final cacheKey = 'search_${countryCode}_$cleanQuery';

    if (!forceRefresh) {
      final cached = CacheService.get<List<Product>>(cacheKey);

      if (cached != null) return cached;
    }

    final products = await _productService.searchProducts(
      cleanQuery,
      countryCode: countryCode,
    );

    CacheService.set(cacheKey, products);

    return products;
  }

  // =========================
  // API PAGINATION
  // =========================

  Future<List<Product>> getProductsPage({
    required int page,
    int limit = 20,
    String countryCode = 'es',
  }) async {
    final ProductsPage response = await ApiService().getProductsPage(
      page: page,
      limit: limit,
      countryCode: countryCode,
    );

    return response.products;
  }

  // =========================
  // RECOMMENDATIONS
  // =========================

  Future<List<Product>> recommendedFor({
    required Product product,
    String countryCode = 'es',
  }) async {
    final query = '${product.category} ${product.store}';

    return searchProducts(query, countryCode: countryCode);
  }

  // =========================
  // CACHE
  // =========================

  void clearSearchCache() {
    CacheService.clear();
  }
}
