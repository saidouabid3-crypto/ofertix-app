import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../core/theme/app_theme.dart';
import '../models/ai_deal_brain_result.dart';
import '../models/product.dart';
import '../services/card_verdict_cache.dart';
import '../services/favorite_service.dart';
import 'product_ai_badge.dart';

class ProductGridCard extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback onTap;
  final Position? userPosition;

  const ProductGridCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onFavorite,
    required this.onTap,
    this.userPosition,
  });

  @override
  State<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<ProductGridCard> {
  final FavoriteService favoriteService = FavoriteService.instance;

  bool isFavorite = false;
  bool favoriteLoading = false;
  AiDealBrainResult? _aiResult;

  // Visibility-based activation state.
  bool _visibilityTriggered = false;
  Timer? _debounceTimer;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
    loadFavorite();
    // Show badge instantly if result is already in cache — no network needed.
    final cached = CardVerdictCache.instance.cached(product.id);
    if (cached != null) {
      _aiResult = cached;
      _visibilityTriggered = true;
    }
  }

  @override
  void didUpdateWidget(covariant ProductGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      isFavorite = widget.isFavorite;
      loadFavorite();
      _aiResult = null;
      _visibilityTriggered = false;
      _debounceTimer?.cancel();
      // Restore from cache immediately if the new product is already cached.
      final cached = CardVerdictCache.instance.cached(product.id);
      if (cached != null) {
        _aiResult = cached;
        _visibilityTriggered = true;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Called when the card enters the viewport at ≥35 % visibility.
  /// Debounced so fast scrolling does not fire a network request.
  void _onVisible() {
    if (_visibilityTriggered) return;
    if (CardVerdictCache.instance.isDisabled) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _visibilityTriggered = true;
      _loadAiBadge();
    });
  }

  Future<void> _loadAiBadge() async {
    final cached = CardVerdictCache.instance.cached(product.id);
    if (cached != null) {
      if (mounted) setState(() => _aiResult = cached);
      return;
    }
    final result = await CardVerdictCache.instance.getOrFetch(product);
    if (!mounted) return;
    if (result != null) setState(() => _aiResult = result);
  }

  Future<void> loadFavorite() async {
    final saved = await favoriteService.isFavorite(product.id);
    if (!mounted) return;
    setState(() => isFavorite = saved);
  }

  Future<void> toggleFavorite() async {
    if (favoriteLoading) return;

    setState(() => favoriteLoading = true);

    final saved = await favoriteService.toggleFavorite(product);

    if (!mounted) return;

    setState(() {
      isFavorite = saved;
      favoriteLoading = false;
    });

    widget.onFavorite?.call();
  }

  bool get hasDiscount =>
      product.discount > 0 && product.oldPrice > product.newPrice;

  String get sourceLabel {
    if (product.isOnline) return product.isGlobal ? 'Global' : 'Online';
    return 'Local';
  }

  String get storeLabel {
    final value = product.store.trim();
    if (value.isEmpty) return 'OFERTIX';
    return value.toUpperCase();
  }

  String get verdictLabel {
    switch (product.aiVerdict) {
      case 'buy_now':
        return 'BUY NOW';
      case 'safe_deal':
        return 'SAFE';
      case 'risky':
        return 'RISKY';
      case 'avoid':
        return 'AVOID';
      default:
        return product.aiVerdictLabel.toUpperCase();
    }
  }

  Color get verdictColor {
    switch (product.aiVerdict) {
      case 'buy_now':
        return AppColors.green;
      case 'safe_deal':
        return AppColors.primary;
      case 'risky':
      case 'avoid':
        return AppColors.redOrange;
      default:
        return AppColors.orange;
    }
  }

  String? get distanceLabel {
    if (product.isOnline) return null;
    if (widget.userPosition == null) return null;
    if (product.lat == 0.0 || product.lng == 0.0) return null;

    final meters = Geolocator.distanceBetween(
      widget.userPosition!.latitude,
      widget.userPosition!.longitude,
      product.lat,
      product.lng,
    );

    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final distance = distanceLabel;

    return VisibilityDetector(
      key: ValueKey('ai-badge-${product.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.35) _onVisible();
      },
      child: GestureDetector(
          onTap: widget.onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth <= 155;
              final imageHeight = compact ? 116.0 : 124.0;

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: product.image,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFFF3F5F7),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.orange,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF3F5F7),
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Color(0xFF9AA1AA),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),

                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.02),
                                    Colors.black.withValues(alpha: 0.14),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (hasDiscount)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _Badge(
                                text: '-${product.discount}%',
                                background: AppColors.orange,
                                foreground: Colors.white,
                              ),
                            ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: toggleFavorite,
                              child: Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: favoriteLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(9),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFavorite
                                            ? AppColors.red
                                            : Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _DarkSourcePill(text: sourceLabel),
                          ),

                          if (_aiResult != null)
                            Positioned(
                              right: 7,
                              bottom: 7,
                              child: ProductAIBadge(result: _aiResult),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 9 : 10,
                          8,
                          compact ? 9 : 10,
                          9,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.isHot ||
                                product.isTrending ||
                                distance != null)
                              Row(
                                children: [
                                  if (product.isHot || product.isTrending)
                                    const _SoftPill(
                                      text: 'HOT',
                                      icon: Icons.local_fire_department_rounded,
                                      color: AppColors.green,
                                    ),
                                  if (distance != null) ...[
                                    const SizedBox(width: 5),
                                    _SoftPill(
                                      text: distance,
                                      icon: Icons.near_me_rounded,
                                      color: AppColors.orange,
                                    ),
                                  ],
                                ],
                              ),

                            if (product.isHot ||
                                product.isTrending ||
                                distance != null)
                              const SizedBox(height: 6),

                            Row(
                              children: [
                                _SoftPill(
                                  text: verdictLabel,
                                  icon: Icons.auto_awesome_rounded,
                                  color: verdictColor,
                                ),
                                if (product.rating > 0) ...[
                                  const SizedBox(width: 5),
                                  _SoftPill(
                                    text: product.rating.toStringAsFixed(1),
                                    icon: Icons.star_rounded,
                                    color: AppColors.orange,
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1E2022),
                                fontSize: compact ? 12.1 : 12.6,
                                height: 1.10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              storeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7B838C),
                                fontSize: 9.3,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              product.reviewCount > 0 || product.soldCount > 0
                                  ? '${product.reviewLabel} reviews · ${product.soldLabel} sold'
                                  : product.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9AA1AA),
                                fontSize: 8.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const Spacer(),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${product.newPrice.toStringAsFixed(2)}€',
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: AppColors.orange,
                                        fontSize: compact ? 19 : 20,
                                        height: 1,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '${product.oldPrice.toStringAsFixed(2)}€',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF9AA1AA),
                                        fontSize: 9.5,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        .animate()
        .fade(duration: 160.ms)
        .slideY(begin: 0.02, end: 0, duration: 160.ms, curve: Curves.easeOut),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DarkSourcePill extends StatelessWidget {
  final String text;

  const _DarkSourcePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_rounded, color: AppColors.orange, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SoftPill({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 76),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9.2,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
