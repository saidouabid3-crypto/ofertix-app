import '../../repositories/ai_repository.dart';

class AIAssistantRepository {
  final AiRepository _repository = AiRepository();

  Future<dynamic> search({required String message, String country = 'ES'}) {
    return _repository.search(message: message, country: country);
  }
}
