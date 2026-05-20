import 'package:flutter/material.dart';

class WatchlistProvider extends ChangeNotifier {
  final Set<String> productIds = {};

  bool isWatching(String id) => productIds.contains(id);

  void toggleWatch(String id) {
    if (productIds.contains(id)) {
      productIds.remove(id);
    } else {
      productIds.add(id);
    }

    notifyListeners();
  }
}
