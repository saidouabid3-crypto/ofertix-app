import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  bool isLoading = false;
  List<dynamic> products = [];

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setProducts(List<dynamic> value) {
    products = value;
    notifyListeners();
  }

  void clear() {
    products = [];
    notifyListeners();
  }
}
