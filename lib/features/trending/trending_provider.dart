import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'trending_repository.dart';

class TrendingProvider extends ChangeNotifier {
  final TrendingRepository _repository = TrendingRepository();

  List<Product> products = [];
  bool isLoading = true;

  StreamSubscription? _sub;

  Future<void> initialize({String countryCode = 'es'}) async {
    _sub?.cancel();

    _sub = _repository.getTrending(countryCode: countryCode).listen((data) {
      products = data;
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
