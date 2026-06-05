import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../services/favorite_service.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';

enum _FavStatus { loading, loaded, empty, error }

/// Self-contained favorites screen backed by [FavoriteService].
///
/// Reads directly from the `favorites` Firestore collection (filtered by the
/// current user's UID) instead of relying on a pre-populated ID set.
/// Mirrors the same pattern used by [WatchlistScreen].
class FavoritesScreen extends StatefulWidget {
  // Legacy params kept for backward compatibility with any existing call sites
  // that pass favoriteIds/onFavorite — they are no longer used.
  final Set<String> favoriteIds;
  final void Function(String) onFavorite;

  const FavoritesScreen({
    super.key,
    this.favoriteIds = const {},
    this.onFavorite = _noop,
  });

  static void _noop(String _) {}

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _FavStatus _status = _FavStatus.loading;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _FavStatus.loading);
    try {
      final items = await FavoriteService.instance.getFavoritesOnce();
      if (!mounted) return;
      setState(() {
        _products = items;
        _status =
            items.isEmpty ? _FavStatus.empty : _FavStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _FavStatus.error);
    }
  }

  Future<void> _remove(Product product) async {
    await FavoriteService.instance.removeFavorite(product.id);
    if (!mounted) return;
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      if (_products.isEmpty) _status = _FavStatus.empty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('product.favorite.removed'.tr()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'auto.favorites_favorites_screen.favorites'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_status) {
      case _FavStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        );

      case _FavStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.gray, size: 42),
              const SizedBox(height: 12),
              Text(
                'common.error'.tr(),
                style: const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.orange),
                label: Text(
                  'common.retry'.tr(),
                  style: const TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        );

      case _FavStatus.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.gray,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'auto.favorites_favorites_screen.no_favorite_products_yet'
                    .tr(),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
            ],
          ),
        );

      case _FavStatus.loaded:
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _load,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = _products[index];
              return Dismissible(
                key: ValueKey('fav-${product.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _remove(product),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.red,
                    size: 28,
                  ),
                ),
                child: ProductGridCard(
                  product: product,
                  isFavorite: true,
                  onTap: () => _openProduct(product),
                ),
              );
            },
          ),
        );
    }
  }
}
