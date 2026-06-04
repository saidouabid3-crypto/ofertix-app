import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ai_deal_brain_result.dart';
import '../../models/price_truth_result.dart';
import '../../models/product.dart';
import '../../services/affiliate_service.dart';
import '../../services/ai_service.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../services/price_truth_service.dart';
import '../../services/product_service.dart';
import '../../services/settings_service.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/price_truth_card.dart';

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
  bool _isWatching = false;
  bool _isWatchLoading = false;
  bool isLoadingAi = false;
  AiDealBrainResult? aiResult;
  String? aiErrorKey;
  int _imageIndex = 0;
  PriceTruthResult? _priceTruth;

  // New state
  bool _descriptionExpanded = false;
  List<Product> _similarProducts = [];
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAiAnalysis();
    _loadFavoriteState();
    _loadWatchState();
    _loadPriceTruth();
    _loadSimilarProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSimilarProducts() async {
    try {
      final results = await ProductService.instance.getSimilarProducts(
        category: widget.product.category,
        excludeId: widget.product.id,
      );
      if (mounted) setState(() => _similarProducts = results);
    } catch (_) {}
  }

  Future<void> _loadPriceTruth() async {
    try {
      final result = await PriceTruthService.instance.analyze(widget.product);
      if (!mounted) return;
      setState(() => _priceTruth = result);
    } catch (_) {}
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

  Future<void> _loadWatchState() async {
    final watching = await WatchlistService.instance.isWatching(
      widget.product.id,
    );
    if (!mounted) return;
    setState(() => _isWatching = watching);
  }

  Future<void> _toggleWatch() async {
    if (_isWatchLoading) return;
    setState(() => _isWatchLoading = true);
    try {
      final nowWatching = await WatchlistService.instance.toggleWatch(
        widget.product,
      );
      if (!mounted) return;
      setState(() {
        _isWatching = nowWatching;
        _isWatchLoading = false;
      });
      final isGuest = !AuthService.instance.isLoggedIn;
      final msg = isGuest && nowWatching
          ? 'watchlist.guestSaved'.tr()
          : nowWatching
              ? 'product.watchlist.added'.tr()
              : 'product.watchlist.removed'.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWatchLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.watchlist.error'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPriceAlertSheet() async {
    if (!mounted) return;
    if (!AuthService.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.loginRequired.alerts'.tr()),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PriceAlertSheet(
        product: widget.product,
        settingsService: _settingsService,
      ),
    );
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
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        aiErrorKey = e.code == 'AI_NOT_CONFIGURED'
            ? 'ai.error.notConfigured'
            : 'ai.error.unavailable';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => aiErrorKey = 'ai.error.unavailable');
    } finally {
      if (mounted) setState(() => isLoadingAi = false);
    }
  }

  /// Opens the best available offer URL via AffiliateService, then falls back
  /// to direct launch. Shows a snackbar only when there is no URL or launch fails.
  Future<void> openLink() async {
    final product = widget.product;
    final urlStr = product.affiliateUrl.trim();

    debugPrint('[ProductDetails] openLink: id=${product.id} '
        'affiliateUrl=${urlStr.isNotEmpty ? "present(${urlStr.length}ch)" : "EMPTY"}');

    if (urlStr.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.offer.noLink'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final country = await _settingsService.getCountry();
    try {
      await AffiliateService.instance.openProduct(
        url: urlStr,
        productId: product.id,
        countryCode: country,
        store: product.store,
      );
    } catch (e) {
      if (e.toString().contains('no_url')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.offer.noLink'.tr()),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
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

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isNotEmpty
        ? product.images
        : (product.image.isNotEmpty ? [product.image] : <String>[]);
    final hasDescription =
        product.description.isNotEmpty &&
        product.description != product.name &&
        product.description != product.fullTitle;
    final hasDiscount = product.discount > 0 && product.oldPrice > product.newPrice;
    final galleryH =
        (MediaQuery.sizeOf(context).height * 0.40).clamp(260.0, 380.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildStickyBar(product),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── 1. Image gallery — no text over image ──
              SliverToBoxAdapter(
                child: _buildGallery(images, galleryH, hasDiscount, product.discount),
              ),

              // ── 2. Product info + all content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(product, hasDiscount),
                      const SizedBox(height: 18),
                      _buildAiMiniCard(),
                      if (_priceTruth != null) ...[
                        const SizedBox(height: 14),
                        PriceTruthCard(result: _priceTruth!),
                      ],
                      const SizedBox(height: 18),
                      _buildBeforeBuy(),
                      if (hasDescription) ...[
                        const SizedBox(height: 18),
                        _buildDescription(product),
                      ],
                      const SizedBox(height: 18),
                      _buildSecondaryActions(product),
                      if (_similarProducts.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSimilarProducts(),
                      ],
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back button overlay (always on top of gallery)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: _iconButton(
              Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context),
            ),
          ),

          // Favorite button overlay
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: _isFavoriteLoading
                ? _iconButton(null, null,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ))
                : _iconButton(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    _toggleFavorite,
                    color: isFavorite ? AppColors.red : Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Gallery ────────────────────────────────────────────────────────────────

  Widget _buildGallery(
    List<String> images,
    double height,
    bool hasDiscount,
    int discount,
  ) {
    Widget imageWidget;
    if (images.length > 1) {
      imageWidget = PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _imageIndex = i),
        itemBuilder: (_, i) => _cachedImg(images[i]),
      );
    } else if (images.isNotEmpty) {
      imageWidget = _cachedImg(images.first);
    } else {
      imageWidget = Container(
        color: const Color(0xFF161622),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white24,
            size: 64,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          // Subtle bottom gradient to separate gallery from content below
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Image counter pill
          if (images.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_imageIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // Discount badge
          if (hasDiscount)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '-$discount% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cachedImg(String url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        color: const Color(0xFF161622),
        colorBlendMode: BlendMode.dstOver,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
            color: AppColors.orange,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFF161622),
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white24,
            size: 60,
          ),
        ),
      );

  // ─── Product Header (title, store, price) ──────────────────────────────────

  Widget _buildHeader(Product product, bool hasDiscount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.store.toUpperCase(),
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatPrice(product.newPrice),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  'product.approxPrice'.tr(),
                  style: TextStyle(
                    color: AppColors.orange.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPrice(product.oldPrice),
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      height: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${product.discount}%',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            if (product.isHot)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HOT',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        if (product.rating > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.orange, size: 16),
              const SizedBox(width: 4),
              Text(
                product.ratingLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (product.reviewCount > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '(${product.reviewLabel})',
                  style: const TextStyle(color: AppColors.gray, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ─── AI Mini Card ───────────────────────────────────────────────────────────

  Widget _buildAiMiniCard() {
    final result = aiResult;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'product.aiAnalysis'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (isLoadingAi)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                ),
            ],
          ),
          if (isLoadingAi) ...[
            const SizedBox(height: 10),
            Text(
              'ai.analysis.loading'.tr(),
              style: const TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ] else if (aiErrorKey != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    aiErrorKey!.tr(),
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _loadAiAnalysis,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'common.retry'.tr(),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (result != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _aiChip(
                  Icons.analytics_rounded,
                  'ai.verdict'.tr(),
                  'ai_deal.${result.verdict}'.tr(),
                ),
                if (result.confidence > 0)
                  _aiChip(
                    Icons.shield_rounded,
                    'ai.confidence'.tr(),
                    '${(result.confidence * 100).round()}%',
                  ),
                if (result.score > 0)
                  _aiChip(
                    Icons.local_fire_department_rounded,
                    'product.dealScore'.tr(),
                    '${result.score}%',
                  ),
              ],
            ),
            if (result.summary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                result.summary,
                style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 13,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _aiChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 13),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Before You Buy checklist ───────────────────────────────────────────────

  Widget _buildBeforeBuy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'product.beforeBuy'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _checkRow('product.beforeBuy1'.tr()),
          _checkRow('product.beforeBuy2'.tr()),
          _checkRow('product.beforeBuy3'.tr()),
        ],
      ),
    );
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.orange.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Collapsible Description ────────────────────────────────────────────────

  Widget _buildDescription(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.description'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          crossFadeState: _descriptionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          firstChild: Text(
            product.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          secondChild: Text(
            product.description,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(
            () => _descriptionExpanded = !_descriptionExpanded,
          ),
          child: Text(
            _descriptionExpanded
                ? 'product.seeLess'.tr()
                : 'product.seeMore'.tr(),
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Secondary Actions (Watchlist, Alert, Share) ───────────────────────────

  Widget _buildSecondaryActions(Product product) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  _isWatching ? AppColors.orange : AppColors.gray,
              side: BorderSide(
                color: _isWatching
                    ? AppColors.orange
                    : AppColors.gray.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _isWatchLoading ? null : _toggleWatch,
            icon: _isWatchLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.orange,
                    ),
                  )
                : Icon(
                    _isWatching
                        ? Icons.visibility_rounded
                        : Icons.visibility_outlined,
                  ),
            label: Text(
              _isWatching
                  ? 'product.watchlist.added'.tr()
                  : 'product.watchlist.add'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: BorderSide(
                color: AppColors.orange.withValues(alpha: 0.55),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _showPriceAlertSheet,
            icon: const Icon(Icons.notifications_rounded),
            label: Text(
              'product.priceAlert.create'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: IconButton(
            onPressed: _shareProduct,
            icon: const Icon(Icons.share_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ─── Similar Products ───────────────────────────────────────────────────────

  Widget _buildSimilarProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.similarProducts'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = _similarProducts[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(product: p),
                  ),
                ),
                child: Container(
                  width: 148,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: p.image,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.background,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatPrice(p.newPrice),
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Sticky Buy Bar ─────────────────────────────────────────────────────────

  Widget _buildStickyBar(Product product) {
    return SafeArea(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatPrice(product.newPrice),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  'product.approxPrice'.tr(),
                  style: TextStyle(
                    color: AppColors.orange.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                onPressed: openLink,
                icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                label: Text(
                  'common.open_offer'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared overlay icon button ────────────────────────────────────────────

  Widget _iconButton(
    IconData? icon,
    VoidCallback? onTap, {
    Color? color,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: child ??
            Icon(icon!, color: color ?? Colors.white, size: 22),
      ),
    );
  }
}

// ─── Price Alert Bottom Sheet ──────────────────────────────────────────────────

class _PriceAlertSheet extends StatefulWidget {
  final Product product;
  final SettingsService settingsService;

  const _PriceAlertSheet({
    required this.product,
    required this.settingsService,
  });

  @override
  State<_PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends State<_PriceAlertSheet> {
  late final TextEditingController _priceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final suggestion = widget.product.newPrice > 0
        ? widget.product.newPrice.toStringAsFixed(2)
        : '';
    _priceController = TextEditingController(text: suggestion);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String get _currency {
    final c = widget.product.currency.trim().toUpperCase();
    return c.isEmpty ? 'EUR' : c;
  }

  Future<void> _submit() async {
    final raw = _priceController.text
        .replaceAll('€', '')
        .replaceAll(r'$', '')
        .replaceAll(',', '.')
        .trim();
    final targetPrice = double.tryParse(raw);

    if (targetPrice == null || targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.priceAlert.invalidPrice'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final country = await widget.settingsService.getCountry();
      final currency = await widget.settingsService.getCurrency();

      final alertId = await AlertService.instance.createProductAlert(
        product: widget.product,
        targetPrice: targetPrice,
        countryCode: country,
        currency: currency,
      );

      if (!mounted) return;

      if (alertId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.priceAlert.created'.tr()),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.priceAlert.error'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.priceAlert.error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = widget.product.newPrice;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.orange,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'product.priceAlert.create'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentPrice > 0)
              Text(
                '${'product.priceAlert.currentPrice'.tr()}: '
                '${currentPrice.toStringAsFixed(2)} $_currency',
                style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'product.priceAlert.targetPrice'.tr(),
                labelStyle: const TextStyle(color: AppColors.gray),
                suffixText: _currency,
                suffixStyle: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.orange,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'product.priceAlert.priceDrop'.tr(),
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray,
                      side: BorderSide(
                        color: AppColors.gray.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text('product.priceAlert.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'product.priceAlert.setAlert'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
