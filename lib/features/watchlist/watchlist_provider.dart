import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'watchlist_repository.dart';

class WatchlistProvider extends ChangeNotifier {
  final WatchlistRepository _repository = WatchlistRepository();

  List<Product> products = [];
  bool isLoading = true;

  StreamSubscription? _sub;

  Future<void> load({required Set<String> ids}) async {
    isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _repository.getWatchlist(ids: ids).listen((data) {
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
