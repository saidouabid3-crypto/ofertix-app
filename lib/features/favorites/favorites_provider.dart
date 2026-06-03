import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/product.dart';

import 'favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository = FavoritesRepository();

  List<Product> favorites = [];

  bool isLoading = true;

  StreamSubscription? _sub;

  Future<void> load({required Set<String> ids}) async {
    isLoading = true;

    notifyListeners();

    _sub?.cancel();

    _sub = _repository.getFavorites(ids: ids).listen((data) {
      favorites = data;

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
