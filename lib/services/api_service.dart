import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/products_page.dart';

class ApiService {
  static const String baseUrl = 'https://ofertix-api.onrender.com';

  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers(token: token))
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      throw Exception('GET request error: $e');
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      throw Exception('POST request error: $e');
    }
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      throw Exception('PUT request error: $e');
    }
  }

  static Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers(token: token),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      throw Exception('DELETE request error: $e');
    }
  }

  Future<ProductsPage> getProductsPage({
    required int page,
    int limit = 20,
    String countryCode = 'es',
  }) async {
    try {
      final data = await get(
        '/api/products?page=$page&limit=$limit&country=$countryCode',
      );

      return _parseProductsPage(data, limit);
    } catch (_) {
      return const ProductsPage(products: [], count: 0, hasMore: false);
    }
  }

  Future<List<Product>> searchProducts({
    required String query,
    String countryCode = 'es',
  }) async {
    final data = await post('/api/products/search', {
      'query': query,
      'country': countryCode,
    });

    return _parseProductsList(data);
  }

  Future<String?> createAffiliateLink({
    required String productId,
    required String originalUrl,
    required String store,
  }) async {
    final data = await post('/api/affiliate/create-link', {
      'productId': productId,
      'originalUrl': originalUrl,
      'store': store,
    });

    if (data is Map && data['affiliateUrl'] != null) {
      return data['affiliateUrl'].toString();
    }

    return null;
  }

  Future<void> trackClick({
    required String productId,
    required String store,
  }) async {
    await post('/api/analytics/click', {
      'productId': productId,
      'store': store,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Product>> getTrendingProducts({String countryCode = 'es'}) async {
    final data = await get('/api/products/trending?country=$countryCode');
    return _parseProductsList(data);
  }

  Future<List<Product>> getRecommendations({
    required String productId,
    String countryCode = 'es',
  }) async {
    final data = await get(
      '/api/products/recommendations?productId=$productId&country=$countryCode',
    );

    return _parseProductsList(data);
  }

  static ProductsPage _parseProductsPage(dynamic data, int limit) {
    if (data == null) {
      return const ProductsPage(products: [], count: 0, hasMore: false);
    }

    if (data is List) {
      final products = _parseProductsList(data);

      return ProductsPage(
        products: products,
        count: products.length,
        hasMore: products.length >= limit,
      );
    }

    if (data is Map) {
      final products = _parseProductsList(data['products'] ?? []);

      return ProductsPage(
        products: products,
        count: data['count'] ?? products.length,
        hasMore: data['hasMore'] ?? products.length >= limit,
      );
    }

    return const ProductsPage(products: [], count: 0, hasMore: false);
  }

  static List<Product> _parseProductsList(dynamic data) {
    if (data is! List) return [];

    return data.map<Product>((item) {
      final map = Map<String, dynamic>.from(item);

      return Product.fromMap(map, map['id']?.toString() ?? '');
    }).toList();
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;

      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    String message = body;

    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
      if (data is Map && data['error'] != null) {
        message = data['error'].toString();
      }
    } catch (_) {}

    throw Exception('API ERROR [$statusCode]: $message');
  }
}
