import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'scan_repository.dart';

class ScanProvider extends ChangeNotifier {
  final ScanRepository _repository = ScanRepository();

  bool isLoading = false;
  bool hasScanned = false;

  String lastCode = '';
  List<Product> results = [];

  Future<void> scanCode(String code) async {
    final cleanCode = code.trim();

    if (cleanCode.isEmpty || hasScanned) return;

    hasScanned = true;
    isLoading = true;
    lastCode = cleanCode;
    results = [];
    notifyListeners();

    try {
      final data = await _repository.findByCode(cleanCode);

      if (data is List<Product>) {
        results = data;
      } else if (data is List) {
        results = data.whereType<Product>().toList();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void resetScanner() {
    hasScanned = false;
    lastCode = '';
    results = [];
    notifyListeners();
  }
}
