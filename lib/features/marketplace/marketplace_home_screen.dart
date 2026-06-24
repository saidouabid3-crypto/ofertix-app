import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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

  @visibleForTesting
  static bool homeEligibleItem(MarketplaceItem item) {
    const publicStatuses = {'active', 'approved', 'published'};
    const blockedStatuses = {
      'archived',
      'blocked',
      'deleted',
      'hidden',
      'pending',
      'rejected',
      'review',
      'sold',
      'under_review',
    };
    final status = item.status.trim().toLowerCase();
    return item.isActive &&
        publicStatuses.contains(status) &&
        !blockedStatuses.contains(status);
  }

  @visibleForTesting
  static List<MarketplaceItem> visibleItemsForHome({
    required List<MarketplaceItem> items,
    required String selectedCategory,
    required String searchQuery,
  }) {
    var result = items.where(homeEligibleItem).toList(growable: false);
    if (selectedCategory != 'all') {
      result = result
          .where((item) => item.categoryKey == selectedCategory)
          .toList(growable: false);
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((item) {
            return item.title.toLowerCase().contains(q) ||
                item.description.toLowerCase().contains(q) ||
                item.city.toLowerCase().contains(q) ||
                item.sellerName.toLowerCase().contains(q);
          })
          .toList(growable: false);
    }
    return result;
  }

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
    if (kDebugMode) {
      debugPrint('[Marketplace16B-A] MarketplaceHomeScreen mounted');
    }
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
    final normalized = country.trim().isEmpty
        ? 'global'
        : country.trim().toLowerCase();

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
        debugPrint(
          '[Marketplace16B] displayed_count=${_displayed(items).length}',
        );
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
      final isQuota =
          e is AppException &&
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
    return MarketplaceHomeScreen.visibleItemsForHome(
      items: src ?? _allItems,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    );
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
    if (kDebugMode) {
      debugPrint('[Marketplace16B-A] quick_action_sell_open_form');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
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

  void _openMyListings() {
    if (kDebugMode) debugPrint('[Marketplace16B-A] quick_action_my_listings');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceMyListingsScreen()),
    );
  }

  void _openMessages() {
    if (kDebugMode) debugPrint('[Marketplace16B-A] quick_action_messages');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceMessagesScreen()),
    );
  }

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
    final bg = isDark ? const Color(0xFF050D11) : AppColors.lightBackground;
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
              child: SizedBox(height: MediaQuery.of(context).padding.top + 14),
            ),

            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _Header(isDark: isDark),
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                height: 44,
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
            const SliverToBoxAdapter(child: SizedBox(height: 6)),

            // ── Section title ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'marketplace.availableListings'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? AppColors.text : AppColors.lightText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (displayed.isNotEmpty)
                      _CountPill(count: displayed.length, isDark: isDark),
                  ],
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

            // ── Loading skeleton (first load only) ────────────────────────
            if (_loading && _allItems.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 110,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.63,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _SkeletonCard(),
                    childCount: 6,
                  ),
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 110,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.63,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => MarketplaceListingCard(
                      item: displayed[i],
                      onTap: _openDetail,
                    ),
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
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'marketplace.title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'marketplace.subtitle'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
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
    final fill = isDark ? const Color(0xFF0E1B22) : AppColors.lightCard;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.lightBorder;
    final hint = isDark ? AppColors.gray : AppColors.lightGray;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
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
          hintStyle: TextStyle(
            color: hint,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: hint, size: 24),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) => v.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: hint, size: 20),
                    onPressed: onClear,
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveFill = isDark
        ? const Color(0xFF101D24)
        : AppColors.lightCard2;
    final inactiveBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.lightBorder;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : inactiveFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.orange : inactiveBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppColors.gray : AppColors.lightGray),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 8.0 : 10.0;
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
            SizedBox(width: gap),
            Expanded(
              child: _ActionTile(
                icon: Icons.list_alt_rounded,
                label: 'marketplace.myListings'.tr(),
                onTap: onMyListings,
                isDark: isDark,
              ),
            ),
            SizedBox(width: gap),
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
      },
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
    final card = isDark ? const Color(0xFF101D24) : AppColors.lightCard;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.lightBorder;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final iconFill = accent
        ? Colors.white.withValues(alpha: 0.22)
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.lightCard2);
    final tileColor = accent ? AppColors.orange : card;
    final tileBorder = accent ? AppColors.orange : border;
    final iconColor = accent ? Colors.white : AppColors.orange;
    final labelColor = accent ? Colors.white : text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 88,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder),
            boxShadow: accent
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ad / sponsored reserved slot ────────────────────────────────────────────

// ignore: unused_element
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
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isQuota
                  ? 'mkt.serviceUnavailable'.tr()
                  : 'marketplace.listingUnavailable'.tr(),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
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
                color: text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
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

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceItem item;
  final ValueChanged<MarketplaceItem> onTap;

  const MarketplaceListingCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.lightBorder;
    final location = item.city.trim().isNotEmpty
        ? item.city.trim()
        : item.countryCode.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: isDark ? 18 : 22,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: _ListingImage(
                    url: item.mainImage,
                    countryCode: item.countryCode,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.trim().isEmpty
                              ? 'marketplace.listingUnavailable'.tr()
                              : item.title.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.formattedPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.green.withValues(alpha: 0.90),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            _DeliveryIcon(method: item.deliveryMethodKey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final String url;
  final String countryCode;

  const _ListingImage({required this.url, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackFill = isDark
        ? const Color(0xFF13262E)
        : AppColors.lightCard2;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isEmpty)
          _ImageFallback(fill: fallbackFill, broken: false)
        else
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => Container(
              color: fallbackFill,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: AppColors.orange.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ),
            errorWidget: (_, __, ___) =>
                _ImageFallback(fill: fallbackFill, broken: true),
          ),
        PositionedDirectional(
          start: 8,
          top: 8,
          child: _CountryBadge(countryCode: countryCode),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final Color fill;
  final bool broken;

  const _ImageFallback({required this.fill, required this.broken});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fill,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_rounded : Icons.shopping_bag_rounded,
          color: AppColors.orange.withValues(alpha: 0.82),
          size: 34,
        ),
      ),
    );
  }
}

class _CountryBadge extends StatelessWidget {
  final String countryCode;

  const _CountryBadge({required this.countryCode});

  @override
  Widget build(BuildContext context) {
    final label = countryCode.trim().toUpperCase();
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  final String method;

  const _DeliveryIcon({required this.method});

  @override
  Widget build(BuildContext context) {
    final icon = switch (method) {
      'shipping' => Icons.local_shipping_outlined,
      'both' => Icons.sync_alt_rounded,
      _ => Icons.storefront_rounded,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Icon(
        icon,
        size: 14,
        color: AppColors.orange.withValues(alpha: 0.86),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final bool isDark;

  const _CountPill({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightBorder,
        ),
      ),
      child: Text(
        NumberFormat.compact().format(count),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? AppColors.gray : AppColors.lightGray,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─── Skeleton card (loading placeholder) ─────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final lo = isDark ? const Color(0xFF0F1E28) : const Color(0xFFECF2F6);
    final hi = isDark ? const Color(0xFF162737) : const Color(0xFFD8E4EC);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : AppColors.lightBorder;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pulse = Color.lerp(lo, hi, _ctrl.value)!;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area placeholder
              Expanded(
                flex: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: pulse,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Content area placeholder
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: pulse,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FractionallySizedBox(
                        widthFactor: 0.65,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Spacer(),
                      FractionallySizedBox(
                        widthFactor: 0.50,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      FractionallySizedBox(
                        widthFactor: 0.38,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
