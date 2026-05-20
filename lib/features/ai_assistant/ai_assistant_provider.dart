import 'package:flutter/material.dart';

import '../../models/product.dart';

import 'ai_assistant_repository.dart';

class AIAssistantProvider extends ChangeNotifier {
  final AIAssistantRepository _repository = AIAssistantRepository();

  bool isLoading = false;

  List<Product> results = [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    isLoading = true;

    results = [];

    notifyListeners();

    try {
      final response = await _repository.search(message: query);

      if (response is List) {
        results = response.map<Product>((item) {
          return Product.fromMap(
            Map<String, dynamic>.from(item),

            item['id']?.toString() ?? '',
          );
        }).toList();
      }
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
