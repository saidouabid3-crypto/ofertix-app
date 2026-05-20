import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import '../models/product.dart';
import '../core/theme/app_theme.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final Position? userPosition;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.userPosition,
  });

  bool get hasDiscount =>
      product.discount > 0 && product.oldPrice > product.newPrice;

  String getDistance() {
    if (product.isOnline ||
        userPosition == null ||
        product.lat == 0 ||
        product.lng == 0) {
      return '🌐 Online';
    }

    final distance = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      product.lat,
      product.lng,
    );

    if (distance < 1000) {
      return '📍 ${distance.toStringAsFixed(0)}m';
    }

    return '📍 ${(distance / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE
                Stack(
                  children: [
                    Hero(
                      tag: product.id,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          height: 135,
                          width: double.infinity,
                          fit: BoxFit.cover,

                          placeholder: (_, __) => Container(
                            height: 135,
                            color: AppColors.card2,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.orange,
                                strokeWidth: 2,
                              ),
                            ),
                          ),

                          errorWidget: (_, __, ___) => Container(
                            height: 135,
                            color: AppColors.card2,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// DISCOUNT
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _Badge(
                          text: '-${product.discount}%',
                          color: AppColors.green,
                        ),
                      ),

                    /// DISTANCE
                    Positioned(
                      top: 10,
                      right: 50,
                      child: _Badge(
                        text: getDistance(),
                        color: AppColors.orange,
                      ),
                    ),

                    /// FAVORITE
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.red : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '🧠 AI PICK',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          product.store.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Spacer(),

                        Row(
                          children: [
                            Text(
                              '${product.newPrice.toStringAsFixed(2)}€',
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'HOT',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '${product.oldPrice.toStringAsFixed(2)}€',
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
