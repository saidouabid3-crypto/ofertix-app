import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class SearchProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  bool isLoading = false;
  List<Product> results = [];

  Future<void> search(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) return;

    isLoading = true;
    results = [];
    notifyListeners();

    try {
      results = await _repository.searchProducts(cleanQuery, countryCode: 'es');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    results = [];
    notifyListeners();
  }
}
