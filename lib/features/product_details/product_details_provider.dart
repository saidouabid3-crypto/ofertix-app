import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'product_details_repository.dart';

class ProductDetailsProvider extends ChangeNotifier {
  final ProductDetailsRepository _repository = ProductDetailsRepository();

  bool isOpening = false;

  Future<void> openProduct(Product product) async {
    isOpening = true;
    notifyListeners();

    await _repository.openAffiliate(product);

    isOpening = false;
    notifyListeners();
  }

  Future<void> trackPrice(Product product) async {
    await _repository.trackPrice(product);
  }
}
