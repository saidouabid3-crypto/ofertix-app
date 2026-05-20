import '../services/ai_service.dart';

class AiRepository {
  final AiService _aiService = AiService();

  Future<dynamic> search({
    required String message,
    String country = 'ES',
  }) async {
    return await _aiService.search(message: message, country: country);
  }
}
