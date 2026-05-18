import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

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

  String _getDistanceString() {
    if (product.isOnline ||
        userPosition == null ||
        product.lat == 0.0 ||
        product.lng == 0.0) {
      return "🌐 Online";
    }
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      product.lat,
      product.lng,
    );
    if (distanceInMeters < 1000) {
      return "📍 ${distanceInMeters.toStringAsFixed(0)}m";
    } else {
      return "📍 ${(distanceInMeters / 1000).toStringAsFixed(1)}km";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.card : Colors.white;
    final imageFallbackColor = isDark
        ? AppColors.card2
        : const Color(0xFFF1F1F1);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final distanceText = _getDistanceString();

    return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: Hero(
                        tag: product.id,
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 105,
                            color: imageFallbackColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.orange,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 105,
                            color: imageFallbackColor,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '-${product.discount}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      top: 8,
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: product.isOnline
                              ? AppColors.orange.withValues(alpha: 0.85)
                              : Colors.blueAccent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          distanceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? AppColors.red
                                : (isDark ? Colors.white70 : Colors.black45),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🧠 AI PICK',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.store.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.newPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            '${product.oldPrice.toStringAsFixed(2)}€',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
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
