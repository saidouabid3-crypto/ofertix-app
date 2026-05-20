import 'package:flutter/material.dart';

class AiProvider extends ChangeNotifier {
  bool isAiEnabled = true;
  bool isLoading = false;
  String lastQuery = '';

  void setAiEnabled(bool value) {
    isAiEnabled = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setLastQuery(String value) {
    lastQuery = value;
    notifyListeners();
  }
}
