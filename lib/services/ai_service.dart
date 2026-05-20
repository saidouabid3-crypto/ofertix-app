import '../models/product.dart';
import 'api_service.dart';

class AiService {
  Future<List<Product>> searchProducts({
    required String message,
    String country = 'ES',
  }) async {
    final response = await ApiService.post('/api/ai-search', {
      'query': message,
      'message': message,
      'country': country,
    });

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
  }

  Future<dynamic> search({required String message, String country = 'ES'}) {
    return ApiService.post('/api/ai-search', {
      'query': message,
      'message': message,
      'country': country,
    });
  }

  Future<List<dynamic>> recommendations({
    required String query,
    String country = 'ES',
  }) async {
    final result = await ApiService.post('/api/recommendations', {
      'query': query,
      'country': country,
    });

    if (result is List) return result;

    if (result is Map && result['recommendations'] is List) {
      return List<dynamic>.from(result['recommendations']);
    }

    return [];
  }

  Future<dynamic> analyzeProduct({
    required String productName,
    required String category,
  }) {
    return ApiService.post('/api/analyze-product', {
      'productName': productName,
      'category': category,
    });
  }
}
