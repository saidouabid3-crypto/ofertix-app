import '../../models/product.dart';

import '../../repositories/ai_repository.dart';

class AIAssistantRepository {
  AIAssistantRepository._();

  static final AIAssistantRepository instance = AIAssistantRepository._();

  final AiRepository _repository = AiRepository.instance;

  Future<List<Product>> search({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
  }) {
    return _repository.searchProducts(
      query: query,
      countryCode: countryCode,
      currency: currency,
    );
  }

  Future<List<Product>> recommendations({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
  }) {
    return _repository.getRecommendations(
      query: query,
      countryCode: countryCode,
      currency: currency,
    );
  }
}
