import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';
import 'watchlist_provider.dart';

class WatchlistScreen extends StatelessWidget {
  final Set<String> productIds;
  final void Function(String) onToggleWatch;

  const WatchlistScreen({
    super.key,
    required this.productIds,
    required this.onToggleWatch,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WatchlistProvider()..load(ids: productIds),
      child: Consumer<WatchlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Watchlist'),
            ),
            body: provider.products.isEmpty
                ? const Center(
                    child: Text(
                      'No products in watchlist',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                    itemBuilder: (context, index) {
                      final product = provider.products[index];

                      return ProductGridCard(
                        product: product,
                        isFavorite: productIds.contains(product.id),
                        onFavorite: () => onToggleWatch(product.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
