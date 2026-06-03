import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'deals_repository.dart';

class DealsProvider extends ChangeNotifier {
  final DealsRepository _repository = DealsRepository();

  List<Product> deals = [];
  bool isLoading = true;

  StreamSubscription? _sub;

  Future<void> initialize({String countryCode = 'es'}) async {
    _sub?.cancel();

    _sub = _repository.getDeals(countryCode: countryCode).listen((data) {
      deals = data;
      isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
