import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_item_detail_screen.dart';

class MarketplaceMyListingsScreen extends StatefulWidget {
  const MarketplaceMyListingsScreen({super.key});

  @override
  State<MarketplaceMyListingsScreen> createState() =>
      _MarketplaceMyListingsScreenState();
}

class _MarketplaceMyListingsScreenState
    extends State<MarketplaceMyListingsScreen> {
  late Future<List<MarketplaceItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MarketplaceItem>> _load() =>
      MarketplaceService.instance.fetchMyItems();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _appBar(text, bg),
        body: Center(
          child: Text(
            'profile.loginRequired'.tr(),
            style: TextStyle(color: text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(text, bg),
      body: FutureBuilder<List<MarketplaceItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }
          if (snap.hasError) {
            return _MyListingsError(
              isDark: isDark,
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _EmptyMyListings(isDark: isDark);
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _MyListingCard(item: items[i], isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  AppBar _appBar(Color text, Color bg) => AppBar(
    title: Text(
      'marketplace.myListings'.tr(),
      style: TextStyle(color: text, fontWeight: FontWeight.w900),
    ),
    backgroundColor: bg,
    iconTheme: IconThemeData(color: text),
    elevation: 0,
  );
}

class _MyListingCard extends StatelessWidget {
  final MarketplaceItem item;
  final bool isDark;

  const _MyListingCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MarketplaceItemDetailScreen(item: item, showOwnerStatus: true),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: item.hasImage
                    ? Image.network(
                        item.mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.formattedPrice,
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: item.status),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        _formatDate(item.createdAt!),
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: muted),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.orange.withValues(alpha: .10),
    child: Center(
      child: Icon(
        Icons.shopping_bag_rounded,
        color: AppColors.orange,
        size: 32,
      ),
    ),
  );

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, key) = _colorAndKey(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        key.tr(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  (Color, String) _colorAndKey(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'published':
        return (AppColors.green, 'marketplace.statusApproved');
      case 'rejected':
        return (AppColors.red, 'marketplace.statusRejected');
      case 'hidden':
        return (AppColors.gray, 'marketplace.statusHidden');
      default:
        return (AppColors.orange, 'marketplace.statusPending');
    }
  }
}

class _EmptyMyListings extends StatelessWidget {
  final bool isDark;

  const _EmptyMyListings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.orange, size: 56),
            const SizedBox(height: 16),
            Text(
              'marketplace.myListingsEmpty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'marketplace.sellFirst'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyListingsError extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const _MyListingsError({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: muted, size: 48),
            const SizedBox(height: 12),
            Text(
              'marketplace.listingUnavailable'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: text, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      ),
    );
  }
}
