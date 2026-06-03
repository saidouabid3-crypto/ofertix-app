import 'package:flutter/material.dart';

import 'visual_search_repository.dart';

class VisualSearchProvider extends ChangeNotifier {
  final VisualSearchRepository _repository = VisualSearchRepository();

  bool isLoading = false;

  String selectedImage = '';

  List<dynamic> results = [];

  Future<void> search(String imagePath) async {
    if (imagePath.isEmpty) return;

    isLoading = true;

    selectedImage = imagePath;

    results = [];

    notifyListeners();

    try {
      final response = await _repository.searchImage(imagePath);

      if (response is List) {
        results = response;
      }
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
