import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

import '../widgets/product_card.dart';

import 'details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final List<Product> products;
  final Set<String> favoriteIds;
  final void Function(String) onFavorite;

  const WatchlistScreen({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.onFavorite,
  });

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);

    final textColor = isDark ? Colors.white : Colors.black;

    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    final favorites = widget.products
        .where((p) => widget.favoriteIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Text(
                    '❤️ Watchlist',

                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${favorites.length}',

                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (favorites.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        const Icon(
                          Icons.favorite_border_rounded,
                          size: 90,
                          color: AppColors.orange,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'No saved deals yet',

                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Tap ❤️ on any product to save it.',

                          textAlign: TextAlign.center,

                          style: TextStyle(color: subTextColor, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),

              if (favorites.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: favorites.length,

                    itemBuilder: (context, index) {
                      final p = favorites[index];

                      return ProductCard(
                        product: p,

                        isFavorite: true,

                        onFavorite: () {
                          widget.onFavorite(p.id);

                          setState(() {});
                        },

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsScreen(
                                product: p,
                                allProducts: favorites,
                                isFavorite: true,
                                onFavorite: () {
                                  widget.onFavorite(p.id);

                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
