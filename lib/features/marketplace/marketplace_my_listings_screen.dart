import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_item_detail_screen.dart';
import 'marketplace_listing_form_screen.dart';

class MarketplaceMyListingsScreen extends StatefulWidget {
  const MarketplaceMyListingsScreen({super.key});

  @override
  State<MarketplaceMyListingsScreen> createState() =>
      _MarketplaceMyListingsScreenState();
}

class _MarketplaceMyListingsScreenState
    extends State<MarketplaceMyListingsScreen> {
  late Future<List<MarketplaceItem>> _future;
  String _filter = 'all';

  static const _filters = [
    'all',
    'pending',
    'approved',
    'rejected',
    'hidden',
    'archived',
    'sold',
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MarketplaceItem>> _load() =>
      MarketplaceService.instance.fetchMyItems();

  Future<void> _reload() async {
    final next = _load();
    if (mounted) {
      setState(() {
        _future = next;
      });
    }
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _edit(MarketplaceItem item) async {
    final updated = await Navigator.push<MarketplaceItem>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceListingFormScreen(existingItem: item),
      ),
    );
    if (updated != null && mounted) await _reload();
  }

  Future<void> _archive(MarketplaceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sell16.archiveTitle'.tr()),
        content: Text('sell16.archiveMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('sell16.archive'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MarketplaceService.instance.archiveMyItem(item.id);
      if (mounted) await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sell16.archiveFailed'.tr())));
    }
  }

  Future<void> _markSold(MarketplaceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sell16.markSoldTitle'.tr()),
        content: Text('sell16.markSoldMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('sell16.markSold'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MarketplaceService.instance.markMyItemSold(item.id);
      if (mounted) await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sell16.markSoldFailed'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _appBar(text, bg),
        body: Center(child: Text('profile.loginRequired'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(text, bg),
      body: FutureBuilder<List<MarketplaceItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off_rounded,
              title: 'marketplace.listingUnavailable'.tr(),
              actionLabel: 'common.retry'.tr(),
              onAction: _reload,
            );
          }
          final allItems = snapshot.data ?? const <MarketplaceItem>[];
          final items = allItems.where(_matchesFilter).toList();
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: _reload,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: _filters.map((filter) {
                        final selected = _filter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text('sell16.filter.$filter'.tr()),
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.storefront_outlined,
                      title: allItems.isEmpty
                          ? 'marketplace.myListingsEmpty'.tr()
                          : 'sell16.filterEmpty'.tr(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _MyListingCard(
                        item: items[index],
                        onOpen: () async {
                          await Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MarketplaceItemDetailScreen(
                                item: items[index],
                                showOwnerStatus: true,
                              ),
                            ),
                          );
                          if (mounted) await _reload();
                        },
                        onEdit: items[index].canEdit
                            ? () => _edit(items[index])
                            : null,
                        onMarkSold: items[index].canMarkSold
                            ? () => _markSold(items[index])
                            : null,
                        onArchive:
                            items[index].isArchived || items[index].isSold
                            ? null
                            : () => _archive(items[index]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesFilter(MarketplaceItem item) {
    if (_filter == 'all') return true;
    if (_filter == 'approved') {
      return {'approved', 'active', 'published'}.contains(item.status);
    }
    return item.status == _filter;
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
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkSold;
  final VoidCallback? onArchive;

  const _MyListingCard({
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onMarkSold,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;
    return Card(
      color: card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: item.hasImage
                          ? Image.network(
                              item.mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _Placeholder(),
                            )
                          : const _Placeholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusChip(status: item.status),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ListingActionButton(
                    onPressed: onEdit,
                    icon: Icons.edit_outlined,
                    label: 'sell16.edit'.tr(),
                  ),
                  _ListingActionButton(
                    onPressed: onMarkSold,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'sell16.markSold'.tr(),
                  ),
                  _ListingActionButton(
                    onPressed: onArchive,
                    icon: Icons.archive_outlined,
                    label: 'sell16.archive'.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'approved' || 'active' || 'published' => AppColors.green,
      'sold' => AppColors.green,
      'rejected' => AppColors.red,
      'hidden' || 'archived' => AppColors.gray,
      _ => AppColors.orange,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: color.withValues(alpha: .14),
        side: BorderSide(color: color.withValues(alpha: .4)),
        label: Text(
          'sell16.status.$normalized'.tr(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ListingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _ListingActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 128),
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: .1),
    child: const Icon(Icons.shopping_bag_rounded, color: AppColors.orange),
  );
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
