import '../../services/voice_search_service.dart';

class VoiceSearchRepository {
  final VoiceSearchService _service = VoiceSearchService();

  Future<String> recognize() {
    return _service.recognize();
  }
}
