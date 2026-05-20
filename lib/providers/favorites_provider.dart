import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> favoriteIds = {};

  bool isFavorite(String id) => favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
    } else {
      favoriteIds.add(id);
    }

    notifyListeners();
  }
}
