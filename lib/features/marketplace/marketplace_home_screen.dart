import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/country_service.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_item_detail_screen.dart';
import 'marketplace_listing_form_screen.dart';
import 'marketplace_messages_screen.dart';
import 'marketplace_my_listings_screen.dart';

// ─── Batch 16B: Marketplace Home Pro ─────────────────────────────────────────

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Data state
  List<MarketplaceItem> _allItems = [];
  bool _loading = false;
  bool _hasError = false;
  bool _isQuotaError = false;

  // Filter state
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // Category keys — backend-supported (matches sell16.category.* keys)
  static const _categoryKeys = [
    'all',
    'electronics',
    'fashion',
    'home',
    'sports',
    'beauty',
    'toys',
    'books',
    'automotive',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _fetch(reason: 'initial');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _fetch({String reason = 'refresh'}) async {
    if (kDebugMode) {
      debugPrint('[Marketplace16B] fetch_start reason=$reason');
    }
    final t0 = DateTime.now();

    final country = await CountryService.instance.getCurrentCountry();
    final normalized =
        country.trim().isEmpty ? 'global' : country.trim().toLowerCase();

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final items = await MarketplaceService.instance.fetchItems(
        limit: 40,
        countryCode: normalized,
      );
      final ms = DateTime.now().difference(t0).inMilliseconds;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16B] fetch_done count=${items.length} duration_ms=$ms',
        );
        debugPrint('[Marketplace16B] raw_count=${items.length}');
        debugPrint('[Marketplace16B] parsed_count=${items.length}');
        debugPrint('[Marketplace16B] displayed_count=${_displayed(items).length}');
      }
      if (mounted) {
        setState(() {
          _allItems = items;
          _loading = false;
          _hasError = false;
          _isQuotaError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Marketplace16B] fetch_error $e');
      final isQuota = e is AppException &&
          (e.toString().contains('FIRESTORE_QUOTA') ||
              e.toString().contains('temporarily'));
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _isQuotaError = isQuota;
          // Keep _allItems — stale data stays visible when refresh fails
        });
      }
    }
  }

  // ─── Filtering (local — backend has no search/query param) ───────────────

  List<MarketplaceItem> _displayed([List<MarketplaceItem>? src]) {
    var items = src ?? _allItems;
    if (_selectedCategory != 'all') {
      items = items
          .where((i) => i.categoryKey == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) {
        final q = _searchQuery;
        return i.title.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q) ||
            i.city.toLowerCase().contains(q);
      }).toList();
    }
    return items;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final q = value.trim().toLowerCase();
      setState(() => _searchQuery = q);
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16B] search query=$q mode=local results=${_displayed().length}',
        );
      }
    });
  }

  void _onCategorySelected(String key) {
    setState(() => _selectedCategory = key);
    if (kDebugMode) {
      debugPrint(
        '[Marketplace16B] category=$key mode=local results=${_displayed().length}',
      );
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _openSell() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.loginRequired'.tr())),
      );
      return;
    }
    final result = await Navigator.push<MarketplaceItem>(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceListingFormScreen()),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('sell.sentForReview'.tr()),
        backgroundColor: AppColors.green,
      ),
    );
    _fetch(reason: 'refresh');
  }

  void _openMyListings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MarketplaceMyListingsScreen()),
  );

  void _openMessages() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MarketplaceMessagesScreen()),
  );

  void _openDetail(MarketplaceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceItemDetailScreen(item: item),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final displayed = _displayed();

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () => _fetch(reason: 'refresh'),
        child: CustomScrollView(
          slivers: [
            // ── Safe-area top spacer ──────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + 10,
              ),
            ),

            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _Header(isDark: isDark),
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                  isDark: isDark,
                ),
              ),
            ),

            // ── Category chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categoryKeys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final key = _categoryKeys[i];
                    final selected = _selectedCategory == key;
                    return _CategoryChip(
                      label: key == 'all'
                          ? 'mkt.category.all'.tr()
                          : 'sell16.category.$key'.tr(),
                      selected: selected,
                      onTap: () => _onCategorySelected(key),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Quick actions ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickActionRow(
                  isDark: isDark,
                  onSell: _openSell,
                  onMyListings: _openMyListings,
                  onMessages: _openMessages,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Ad / sponsored reserved slot ───────────────────────────────
            const SliverToBoxAdapter(child: _AdSlot()),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Section title ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  'marketplace.availableListings'.tr(),
                  style: TextStyle(
                    color: isDark ? AppColors.text : AppColors.lightText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // ── Quota / error banner (non-blocking — shown above grid) ────
            if (_hasError && _allItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _ErrorBanner(
                    isQuota: _isQuotaError,
                    onRetry: () => _fetch(reason: 'refresh'),
                  ),
                ),
              ),

            // ── Loading spinner (first load only) ─────────────────────────
            if (_loading && _allItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              )

            // ── Hard error (no cached data) ────────────────────────────────
            else if (_hasError && _allItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: _isQuotaError
                      ? 'mkt.serviceUnavailable'.tr()
                      : 'marketplace.listingUnavailable'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: () => _fetch(reason: 'refresh'),
                ),
              )

            // ── Empty list (search/category filtered) ─────────────────────
            else if (!_loading && displayed.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'mkt.noResults'.tr(),
                ),
              )

            // ── Listing grid ───────────────────────────────────────────────
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _ListingCard(item: displayed[i], onTap: _openDetail),
                    childCount: displayed.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'marketplace.title'.tr(),
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'marketplace.subtitle'.tr(),
              style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.card : AppColors.lightCard;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;
    final hint = isDark ? AppColors.gray : AppColors.lightGray;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppColors.text : AppColors.lightText,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'mkt.searchHint'.tr(),
          hintStyle: TextStyle(color: hint, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: hint, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) => v.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: hint, size: 18),
                    onPressed: onClear,
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.card
                  : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.orange : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.gray
                    : AppColors.lightGray),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// ─── Quick action row ─────────────────────────────────────────────────────────

class _QuickActionRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onSell;
  final VoidCallback onMyListings;
  final VoidCallback onMessages;

  const _QuickActionRow({
    required this.isDark,
    required this.onSell,
    required this.onMyListings,
    required this.onMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_business_rounded,
            label: 'marketplace.sell'.tr(),
            onTap: onSell,
            isDark: isDark,
            accent: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.list_alt_rounded,
            label: 'marketplace.myListings'.tr(),
            onTap: onMyListings,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'marketplace.messages'.tr(),
            onTap: onMessages,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool accent;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;
    final text = isDark ? AppColors.text : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.orange.withValues(alpha: 0.12)
              : card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent
                ? AppColors.orange.withValues(alpha: 0.35)
                : border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.orange,
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ad / sponsored reserved slot ────────────────────────────────────────────

class _AdSlot extends StatelessWidget {
  const _AdSlot();

  @override
  Widget build(BuildContext context) {
    // Reserved monetization slot — hidden until a real ad provider is wired.
    // Structure is AdMob-native-ready: replace this Container with a
    // NativeAdWidget or BannerAd when the provider is configured.
    return const SizedBox.shrink();
  }
}

// ─── Error banner (non-blocking, shown above stale grid) ─────────────────────

class _ErrorBanner extends StatelessWidget {
  final bool isQuota;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.isQuota, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isQuota
                  ? 'mkt.serviceUnavailable'.tr()
                  : 'marketplace.listingUnavailable'.tr(),
              style: const TextStyle(
                  color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'common.retry'.tr(),
              style: const TextStyle(
                  color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error state ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.orange),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: text, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'marketplace.sellFirst'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Listing card ─────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final MarketplaceItem item;
  final ValueChanged<MarketplaceItem> onTap;

  const _ListingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: _ListingImage(url: item.mainImage),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.green),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.city.isEmpty ? item.countryCode : item.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _DeliveryBadge(method: item.deliveryMethodKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final String url;
  const _ListingImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.orange.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.shopping_bag_rounded,
              color: AppColors.orange, size: 36),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.orange.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.broken_image_rounded,
              color: AppColors.orange, size: 28),
        ),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.orange.withValues(alpha: 0.04),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  final String method;
  const _DeliveryBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method == 'shipping' || method == 'both') {
      return Row(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 10, color: AppColors.orange.withValues(alpha: 0.7)),
          const SizedBox(width: 2),
          Text(
            'sell16.delivery.$method'.tr(),
            style: TextStyle(
              color: AppColors.orange.withValues(alpha: 0.8),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
