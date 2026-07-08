import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService instance = ProductService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Session-level cache: avoids repeated 200-doc Firestore reads when
  // multiple Product Details screens open in the same session.
  List<Product>? _similarProductsCache;

  Stream<List<Product>> getProducts({String countryCode = 'es'}) {
    return Stream.fromFuture(getProductsOnce(countryCode: countryCode));
  }

  Stream<List<Product>> getHotProducts({String countryCode = 'es'}) {
    return getProducts(countryCode: countryCode).map(
      (products) => products.where((p) => p.isHot || p.discount >= 20).toList(),
    );
  }

  Stream<List<Product>> getFeaturedProducts({String countryCode = 'es'}) {
    return getProducts(countryCode: countryCode).map((products) {
      final featured = products.where((p) => p.featured).toList();
      return featured.isNotEmpty ? featured : products;
    });
  }

  Future<List<Product>> searchProducts(
    String query, {
    String countryCode = 'es',
  }) async {
    final local = await _searchFirebase(query, countryCode: countryCode);
    final remote = await _searchBackend(query, countryCode: countryCode);

    final merged = _mergeProducts([...remote, ...local]);
    merged.sort(_sortProducts);

    return merged;
  }

  Future<List<Product>> getProductsOnce({
    String countryCode = 'es',
    int limit = 300,
  }) async {
    try {
      return await _loadBackendProducts(countryCode: countryCode, limit: limit);
    } catch (_) {
      return _loadFirestoreProducts(countryCode: countryCode, limit: limit);
    }
  }

  Future<List<Product>> _searchFirebase(
    String query, {
    String countryCode = 'es',
  }) async {
    final snapshot = await _db.collection('products').limit(300).get();

    final q = query.toLowerCase();
    final country = countryCode.toLowerCase();

    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((p) {
          if (p.image.isEmpty) return false;
          if (p.newPrice <= 0) return false;

          if (!p.isOnline && p.country.toLowerCase() != country) {
            return false;
          }

          final text = '${p.name} ${p.description} ${p.category} ${p.store}'
              .toLowerCase();

          return text.contains(q);
        })
        .toList();
  }

  Future<List<Product>> _loadBackendProducts({
    required String countryCode,
    required int limit,
  }) async {
    final page = await ApiService.instance.getProductsPage(
      page: 1,
      limit: limit.clamp(1, 40).toInt(),
      countryCode: countryCode,
    );
    final products = page.products.where(_isDisplayableProduct).toList();
    products.sort(_sortProducts);
    return products;
  }

  Future<List<Product>> _loadFirestoreProducts({
    required String countryCode,
    required int limit,
  }) async {
    final snapshot = await _db
        .collection('products')
        .where('visibleToUsers', isEqualTo: true)
        .limit(limit.clamp(1, 80).toInt())
        .get();
    final country = countryCode.toLowerCase();

    final products = snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((p) => _isDisplayableProduct(p, country: country))
        .toList();

    products.sort(_sortProducts);
    return products;
  }

  bool _isDisplayableProduct(Product p, {String? country}) {
    if (p.image.isEmpty) return false;
    if (p.newPrice <= 0) return false;
    if (p.isOnline) return true;
    final target = (country ?? 'es').toLowerCase();
    return p.country.toLowerCase() == target;
  }

  Future<List<Product>> _searchBackend(
    String query, {
    String countryCode = 'es',
  }) async {
    try {
      final response = await ApiService.instance.post(
        '/api/products/search',
        body: {'query': query, 'country': countryCode},
      );

      if (response is List) {
        return response.map<Product>((item) {
          final data = Map<String, dynamic>.from(item);
          return Product.fromMap(data, data['id']?.toString() ?? '');
        }).toList();
      }

      if (response is Map && response['products'] is List) {
        final items = List<Map<String, dynamic>>.from(response['products']);

        return items.map<Product>((item) {
          return Product.fromMap(item, item['id']?.toString() ?? '');
        }).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  List<Product> _mergeProducts(List<Product> products) {
    final map = <String, Product>{};

    for (final product in products) {
      final key = product.id.isNotEmpty
          ? product.id
          : '${product.name}_${product.store}_${product.newPrice}';

      map[key] = product;
    }

    return map.values.toList();
  }

  /// Returns products in the same category, excluding the current product.
  Future<List<Product>> getSimilarProducts({
    required String category,
    required String excludeId,
    int limit = 8,
  }) async {
    try {
      _similarProductsCache ??= await getProductsOnce(limit: 200);
      final all = _similarProductsCache!;
      final q = category.toLowerCase().trim();
      return all
          .where((p) {
            if (p.id == excludeId) return false;
            if (p.image.isEmpty || p.newPrice <= 0) return false;
            if (q.isEmpty || q == 'general') return p.id != excludeId;
            final hay = '${p.category} ${p.categoryGroup} ${p.name}'
                .toLowerCase();
            return hay.contains(q) ||
                q.contains(p.category.toLowerCase().trim());
          })
          .take(limit)
          .toList();
    } catch (_) {
      _similarProductsCache = null;
      return [];
    }
  }

  int _sortProducts(Product a, Product b) {
    if (a.featured && !b.featured) return -1;
    if (!a.featured && b.featured) return 1;

    if (a.isHot && !b.isHot) return -1;
    if (!a.isHot && b.isHot) return 1;

    if (a.discount != b.discount) {
      return b.discount.compareTo(a.discount);
    }

    return a.newPrice.compareTo(b.newPrice);
  }
}
