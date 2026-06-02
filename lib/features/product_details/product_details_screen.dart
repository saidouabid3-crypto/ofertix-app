import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ai_deal_brain_result.dart';
import '../../models/product.dart';
import '../../services/affiliate_service.dart';
import '../../services/ai_service.dart';
import '../../services/favorite_service.dart';
import '../../services/settings_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String currencySymbol;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.currencySymbol = '€',
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final AiService _aiService = AiService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  bool isFavorite = false;
  bool _isFavoriteLoading = false;
  bool isLoadingAi = false;
  AiDealBrainResult? aiResult;
  String? aiErrorKey;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAiAnalysis();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final saved = await FavoriteService.instance.isFavorite(widget.product.id);
    if (!mounted) return;
    setState(() => isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
    setState(() => _isFavoriteLoading = true);
    try {
      final nowSaved = await FavoriteService.instance.toggleFavorite(
        widget.product,
      );
      if (!mounted) return;
      setState(() {
        isFavorite = nowSaved;
        _isFavoriteLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowSaved
                ? 'product.favorite.added'.tr()
                : 'product.favorite.removed'.tr(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavoriteLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.favorite.error'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareProduct() async {
    final product = widget.product;
    final price = _formatPrice(product.newPrice);
    final buffer = StringBuffer(product.name);
    if (price.isNotEmpty) buffer.write('\n$price');
    if (product.affiliateUrl.trim().isNotEmpty) {
      buffer.write('\n${product.affiliateUrl.trim()}');
    }
    buffer.write('\n\nOfertix');
    try {
      await SharePlus.instance.share(ShareParams(text: buffer.toString()));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.share.error'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadAiAnalysis() async {
    if (isLoadingAi) return;
    setState(() {
      isLoadingAi = true;
      aiErrorKey = null;
    });
    try {
      final country = await _settingsService.getCountry();
      final currency = await _settingsService.getCurrency();
      final language = await _settingsService.getLanguage();
      final result = await _aiService.analyzeProductDealBrain(
        product: widget.product,
        countryCode: country,
        currency: currency,
        language: language,
      );
      if (!mounted) return;
      setState(() => aiResult = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => aiErrorKey = 'ai.error.notConfigured');
    } finally {
      if (mounted) setState(() => isLoadingAi = false);
    }
  }

  /// Format price using the product's own currency field.
  String _formatPrice(double price) {
    if (price <= 0) return '';
    final c = widget.product.currency.trim().toUpperCase();
    final f = price.toStringAsFixed(2);
    switch (c) {
      case 'EUR':
        return '$f€';
      case 'USD':
        return '\$$f';
      case 'GBP':
        return '£$f';
      case 'JPY':
        return '¥${price.toStringAsFixed(0)}';
      default:
        return c.isEmpty ? '$f€' : '$f $c';
    }
  }

  /// Opens affiliate URL via AffiliateService which tracks the click first.
  /// If no URL exists the button is already disabled by [hasBuyLink].
  Future<void> openLink() async {
    final product = widget.product;
    final urlStr = product.affiliateUrl.trim();
    if (urlStr.isEmpty) return;
    final country = await _settingsService.getCountry();
    try {
      await AffiliateService.instance.openProduct(
        url: urlStr,
        productId: product.id,
        countryCode: country,
        store: product.store,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.offer.openError'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDiscount =
        product.discount > 0 && product.oldPrice > product.newPrice;
    final images =
        product.images.isNotEmpty ? product.images : [product.image];
    final hasMultipleImages = images.length > 1;
    final hasDescription = product.description.isNotEmpty &&
        product.description != product.name &&
        product.description != product.fullTitle;
    final hasCategory = product.category.isNotEmpty &&
        product.category.toLowerCase() != 'general';
    final hasRating = product.rating > 0;
    final hasDealScore = product.dealScore > 0;
    final hasStats = hasRating || hasDealScore;
    final hasBuyLink = product.affiliateUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: CustomScrollView(
        slivers: [
          /// APP BAR
          SliverAppBar(
            expandedHeight: 420,

            pinned: true,

            backgroundColor: AppColors.background,

            leading: IconButton(
              onPressed: () => Navigator.pop(context),

              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,

                color: Colors.white,
              ),
            ),

            actions: [
              IconButton(
                onPressed: _isFavoriteLoading ? null : _toggleFavorite,

                icon: _isFavoriteLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,

                        color: isFavorite ? AppColors.red : Colors.white,
                      ),
              ),

              const SizedBox(width: 8),
            ],

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,

                children: [
                  // Image: carousel when multiple images, single hero otherwise
                  if (hasMultipleImages)
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, i) => _buildImage(
                        images[i],
                        heroTag: i == 0 ? product.id : null,
                      ),
                    )
                  else
                    Hero(
                      tag: product.id,
                      child: _buildImage(images.first),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,

                        end: Alignment.bottomCenter,

                        colors: [
                          Colors.transparent,

                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),

                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 110,
                      left: 20,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.green,

                          borderRadius: BorderRadius.circular(99),
                        ),

                        child: Text(
                          '-${product.discount}% OFF',

                          style: const TextStyle(
                            color: Colors.white,

                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // Carousel dots indicator
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 76,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length.clamp(0, 8),
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _imageIndex == i ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _imageIndex == i
                                  ? AppColors.orange
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Title / store overlay
                  Positioned(
                    bottom: 28,
                    left: 22,
                    right: 22,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.18),

                            borderRadius: BorderRadius.circular(999),
                          ),

                          child: const Text(
                            '🧠 AI VERIFIED DEAL',

                            style: TextStyle(
                              color: AppColors.orange,

                              fontWeight: FontWeight.w900,

                              fontSize: 11,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          product.name,

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 34,

                            fontWeight: FontWeight.w900,

                            height: 1.1,

                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          product.store.toUpperCase(),

                          style: const TextStyle(
                            color: AppColors.gray,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// PRICE ROW
                  Row(
                    children: [
                      Text(
                        _formatPrice(product.newPrice),

                        style: const TextStyle(
                          color: AppColors.orange,

                          fontSize: 42,

                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(width: 12),

                      if (hasDiscount)
                        Text(
                          _formatPrice(product.oldPrice),

                          style: const TextStyle(
                            color: AppColors.gray,

                            fontSize: 18,

                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                      const Spacer(),

                      // HOT badge only when product is actually hot
                      if (product.isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.14),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: const Text(
                            'HOT',

                            style: TextStyle(
                              color: AppColors.green,

                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Category chip (only when real category exists)
                  if (hasCategory) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppColors.gray,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  /// AI ANALYSIS CARD (real backend — preserved from Batch 2B)
                  _realAiAnalysisCard(),

                  const SizedBox(height: 26),

                  /// REAL STATS ROW (hidden when no data)
                  if (hasStats) ...[
                    Row(
                      children: [
                        if (hasRating)
                          Expanded(
                            child: _statCard(
                              product.ratingLabel,
                              'product.rating'.tr(),
                              Icons.star,
                              AppColors.orange,
                              subtitle: product.reviewCount > 0
                                  ? '(${product.reviewLabel})'
                                  : null,
                            ),
                          ),
                        if (hasRating && hasDealScore)
                          const SizedBox(width: 14),
                        if (hasDealScore)
                          Expanded(
                            child: _statCard(
                              '${product.dealScore}',
                              'product.dealScore'.tr(),
                              Icons.local_fire_department_rounded,
                              AppColors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],

                  /// DESCRIPTION (only when real text available)
                  if (hasDescription) ...[
                    Text(
                      'product.description'.tr(),

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 28,

                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      product.description,

                      style: const TextStyle(
                        color: AppColors.gray,

                        fontSize: 15,

                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 38),
                  ] else
                    const SizedBox(height: 10),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasBuyLink
                                ? AppColors.orange
                                : AppColors.card,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 18),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),

                          onPressed: hasBuyLink ? openLink : null,

                          icon: const Icon(Icons.shopping_bag_rounded),

                          label: Text(
                            hasBuyLink
                                ? 'common.open_offer'.tr()
                                : 'product.noBuyLink'.tr(),

                            style: const TextStyle(
                              fontWeight: FontWeight.w900,

                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,

                          borderRadius: BorderRadius.circular(22),
                        ),

                        child: IconButton(
                          onPressed: _shareProduct,

                          icon: const Icon(
                            Icons.share_rounded,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl, {String? heroTag}) {
    final img = Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(
        color: AppColors.card,
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white54,
          size: 80,
        ),
      ),
    );
    if (heroTag != null) {
      return Hero(tag: heroTag, child: img);
    }
    return img;
  }

  Widget _realAiAnalysisCard() {
    final result = aiResult;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_rounded,
                color: AppColors.orange,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'product.aiAnalysis'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (result != null)
                Text(
                  '${result.score}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoadingAi)
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ai.analysis.loading'.tr(),
                    style: const TextStyle(color: AppColors.gray),
                  ),
                ),
              ],
            )
          else if (aiErrorKey != null)
            Row(
              children: [
                const Icon(Icons.info_rounded, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aiErrorKey!.tr(),
                    style: const TextStyle(color: AppColors.gray, height: 1.4),
                  ),
                ),
                TextButton(
                  onPressed: _loadAiAnalysis,
                  child: Text('common.retry'.tr()),
                ),
              ],
            )
          else if (result != null) ...[
            _analysisItem(result.verdict.replaceAll('_', ' ').toUpperCase()),
            if (result.brutalTruth.isNotEmpty)
              _analysisItem(result.brutalTruth),
            if (result.summary.isNotEmpty) _analysisItem(result.summary),
            ...result.reasons.take(3).map(_analysisItem),
            ...result.risks.take(3).map(_analysisItem),
            if (result.priceAdvice.recommendation.isNotEmpty)
              _analysisItem(result.priceAdvice.recommendation),
            if (result.antiImpulseAdvice.message.isNotEmpty)
              _analysisItem(result.antiImpulseAdvice.message),
            _analysisItem(
              '${'ai.confidence'.tr()}: ${(result.confidence * 100).round()}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _analysisItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),

            child: Icon(
              Icons.check_circle_rounded,

              color: AppColors.green,

              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,

              style: const TextStyle(
                color: AppColors.gray,

                height: 1.5,

                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String value,
    String title,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 24,

              fontWeight: FontWeight.w900,
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.gray, fontSize: 10),
            ),
          ],

          const SizedBox(height: 4),

          Text(
            title,

            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
