import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/watchlist_service.dart';

/// Global in-memory cache of watchlist product IDs.
///
/// Cards read [isWatching] from this provider instead of making individual
/// Firestore calls, keeping scroll performance smooth.
/// Call [ensureLoaded] once (e.g. from AppShell) to populate the cache.
class WatchlistProvider extends ChangeNotifier {
  final Set<String> _ids = {};
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;

  bool isWatching(String id) => _ids.contains(id);

  /// Loads watchlist product IDs from Firestore once per session.
  /// Safe to call multiple times — subsequent calls are no-ops until [reset].
  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final items = await WatchlistService.instance.getWatchlistOnce();
      _ids
        ..clear()
        ..addAll(items.map((p) => p.id));
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Fail silently; cards fall back to showing unsaved state.
    } finally {
      _loading = false;
    }
  }

  /// Reload from Firestore (e.g. after returning from WatchlistScreen).
  Future<void> refresh() async {
    _loaded = false;
    await ensureLoaded();
  }

  /// Optimistic toggle used by [ProductGridCard].
  /// Returns the new watching state.
  Future<bool> toggleWatch(Product product) async {
    final wasWatching = _ids.contains(product.id);
    // Optimistic update.
    if (wasWatching) {
      _ids.remove(product.id);
    } else {
      _ids.add(product.id);
    }
    notifyListeners();

    try {
      final nowWatching = await WatchlistService.instance.toggleWatch(product);
      if (nowWatching != !wasWatching) {
        // Server disagrees — sync back.
        if (nowWatching) {
          _ids.add(product.id);
        } else {
          _ids.remove(product.id);
        }
        notifyListeners();
      }
      return nowWatching;
    } catch (_) {
      // Rollback optimistic change.
      if (wasWatching) {
        _ids.add(product.id);
      } else {
        _ids.remove(product.id);
      }
      notifyListeners();
      return wasWatching;
    }
  }

  void markWatching(String id) {
    _ids.add(id);
    notifyListeners();
  }

  void markNotWatching(String id) {
    _ids.remove(id);
    notifyListeners();
  }
}
