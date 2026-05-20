class VoiceSearchService {
  Future<String> recognize() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return '';
  }

  Future<String> listen() async {
    return recognize();
  }
}
