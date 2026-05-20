import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/product.dart';

import 'home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();

  List<Product> products = [];

  List<Product> hotProducts = [];

  List<Product> featuredProducts = [];

  bool isLoading = true;

  StreamSubscription? _productsSub;

  StreamSubscription? _hotSub;

  StreamSubscription? _featuredSub;

  Future<void> initialize({String countryCode = 'es'}) async {
    isLoading = true;

    notifyListeners();

    _productsSub = _repository.getProducts(countryCode: countryCode).listen((
      data,
    ) {
      products = data;

      notifyListeners();
    });

    _hotSub = _repository.getHotProducts(countryCode: countryCode).listen((
      data,
    ) {
      hotProducts = data;

      notifyListeners();
    });

    _featuredSub = _repository
        .getFeaturedProducts(countryCode: countryCode)
        .listen((data) {
          featuredProducts = data;

          isLoading = false;

          notifyListeners();
        });
  }

  @override
  void dispose() {
    _productsSub?.cancel();

    _hotSub?.cancel();

    _featuredSub?.cancel();

    super.dispose();
  }
}
