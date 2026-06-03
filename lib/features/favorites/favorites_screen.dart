import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import '../../widgets/product_grid_card.dart';

import '../product_details/product_details_screen.dart';

import 'favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  final Set<String> favoriteIds;

  final void Function(String) onFavorite;

  const FavoritesScreen({
    super.key,

    required this.favoriteIds,

    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesProvider()..load(ids: favoriteIds),

      child: Consumer<FavoritesProvider>(
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

              title: const Text('Favorites'),
            ),

            body: provider.favorites.isEmpty
                ? const Center(
                    child: Text(
                      'No favorite products',

                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: provider.favorites.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,

                          mainAxisSpacing: 16,

                          crossAxisSpacing: 16,

                          childAspectRatio: 0.68,
                        ),

                    itemBuilder: (context, index) {
                      final product = provider.favorites[index];

                      return ProductGridCard(
                        product: product,

                        isFavorite: favoriteIds.contains(product.id),

                        onFavorite: () => onFavorite(product.id),

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
