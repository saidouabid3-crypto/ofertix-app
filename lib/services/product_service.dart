import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService instance = ProductService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getProducts({String countryCode = 'es'}) {
    final country = countryCode.toLowerCase();

    return _db.collection('products').snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((p) {
            if (p.image.isEmpty) return false;
            if (p.newPrice <= 0) return false;
            if (p.isOnline) return true;
            return p.country.toLowerCase() == country;
          })
          .toList();

      products.sort(_sortProducts);
      return products;
    });
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
    final snapshot = await _db.collection('products').limit(limit).get();
    final country = countryCode.toLowerCase();

    final products = snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((p) {
          if (p.image.isEmpty) return false;
          if (p.newPrice <= 0) return false;
          if (p.isOnline) return true;
          return p.country.toLowerCase() == country;
        })
        .toList();

    products.sort(_sortProducts);
    return products;
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

  Future<List<Product>> _searchBackend(
    String query, {
    String countryCode = 'es',
  }) async {
    try {
      final response = await ApiService.instance.post(
        '/api/products/search',
        body: {
          'query': query,
          'country': countryCode,
        },
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
