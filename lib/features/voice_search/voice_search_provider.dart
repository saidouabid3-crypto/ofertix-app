import 'package:flutter/material.dart';

import 'voice_search_repository.dart';

class VoiceSearchProvider extends ChangeNotifier {
  final VoiceSearchRepository _repository = VoiceSearchRepository();

  bool isListening = false;

  String recognizedText = '';

  Future<void> startListening() async {
    isListening = true;

    notifyListeners();

    try {
      recognizedText = await _repository.recognize();
    } finally {
      isListening = false;

      notifyListeners();
    }
  }
}
