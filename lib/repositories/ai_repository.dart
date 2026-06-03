import '../services/ai_service.dart';
import '../models/product.dart';

class AiRepository {
  static final AiRepository instance = AiRepository();

  final AiService _aiService = AiService();

  Future<dynamic> search({
    required String message,
    String country = 'ES',
  }) async {
    return await _aiService.search(message: message, country: country);
  }

  Future<List<Product>> searchProducts({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
  }) {
    return _aiService.searchProducts(
      query: query,
      countryCode: countryCode,
      currency: currency,
    );
  }

  Future<List<Product>> getRecommendations({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
  }) {
    return _aiService.recommendations(
      query: query,
      countryCode: countryCode,
      currency: currency,
    );
  }
}
