import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';

enum _WatchlistStatus { loading, loaded, empty, error }

/// Self-contained watchlist screen backed by [WatchlistService].
///
/// The [productIds] and [onToggleWatch] parameters are kept for backward
/// compatibility with existing call sites but are no longer used — the screen
/// loads the real watchlist directly from Firestore via [WatchlistService].
class WatchlistScreen extends StatefulWidget {
  final Set<String> productIds;
  final void Function(String) onToggleWatch;

  const WatchlistScreen({
    super.key,
    this.productIds = const {},
    this.onToggleWatch = _noop,
  });

  // Backward-compat no-op default for the toggle callback.
  static void _noop(String _) {}

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  _WatchlistStatus _status = _WatchlistStatus.loading;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _WatchlistStatus.loading);
    try {
      final items = await WatchlistService.instance.getWatchlistOnce();
      if (!mounted) return;
      setState(() {
        _products = items;
        _status = items.isEmpty
            ? _WatchlistStatus.empty
            : _WatchlistStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _WatchlistStatus.error);
    }
  }

  Future<void> _remove(Product product) async {
    await WatchlistService.instance.removeWatch(product.id);
    if (!mounted) return;
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      if (_products.isEmpty) _status = _WatchlistStatus.empty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('product.watchlist.removed'.tr()),
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
    // Reload in case the user removed the product from watchlist inside
    // the Product Details screen.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'auto.watchlist_watchlist_screen.watchlist'.tr(),
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
      case _WatchlistStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        );

      case _WatchlistStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.gray, size: 42),
              const SizedBox(height: 12),
              Text(
                'watchlist.error'.tr(),
                style: const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.orange),
                label: Text(
                  'common.retry'.tr(),
                  style: const TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        );

      case _WatchlistStatus.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_rounded,
                color: AppColors.gray,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'auto.watchlist_watchlist_screen.no_products_in_watchlist'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
            ],
          ),
        );

      case _WatchlistStatus.loaded:
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _load,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = _products[index];
              return Dismissible(
                key: ValueKey('watchlist-${product.id}'),
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
                  onTap: () => _openProduct(product),
                ),
              );
            },
          ),
        );
    }
  }
}
