import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_item_detail_screen.dart';
import 'marketplace_listing_form_screen.dart';

// ─── Mis Anuncios — premium compact seller control center ────────────────────

class MarketplaceMyListingsScreen extends StatefulWidget {
  const MarketplaceMyListingsScreen({super.key});

  @override
  State<MarketplaceMyListingsScreen> createState() =>
      _MarketplaceMyListingsScreenState();

  @visibleForTesting
  static bool matchesFilter(MarketplaceItem item, String filter) =>
      _MarketplaceMyListingsScreenState._matchesFilterStatic(item, filter);
}

class _MarketplaceMyListingsScreenState
    extends State<MarketplaceMyListingsScreen> {
  List<MarketplaceItem> _items = [];
  bool _loading = true;
  bool _hasError = false;
  String _filter = 'all';

  static const _filterKeys = [
    'all',
    'pending',
    'approved',
    'rejected',
    'hidden',
    'archived',
    'sold',
  ];

  static bool _matchesFilterStatic(MarketplaceItem item, String filter) {
    if (item.status == 'deleted') return false;
    if (filter == 'all') return true;
    if (filter == 'approved') {
      return {'approved', 'active', 'published'}.contains(item.status);
    }
    return item.status == filter;
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      if (_items.isEmpty) { _loading = true; }
    });
    try {
      final items = await MarketplaceService.instance.fetchMyItems();
      if (mounted) {
        setState(() { _items = items; _loading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _hasError = true; });
      }
    }
  }

  List<MarketplaceItem> get _displayed =>
      _items.where((i) => _matchesFilterStatic(i, _filter)).toList();

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _edit(MarketplaceItem item) async {
    final updated = await Navigator.push<MarketplaceItem>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceListingFormScreen(existingItem: item),
      ),
    );
    if (updated != null && mounted) await _load();
  }

  Future<void> _archive(MarketplaceItem item) async {
    final ok = await _confirm(
      title: 'sell16.archiveTitle'.tr(),
      message: 'sell16.archiveMessage'.tr(),
      confirmLabel: 'sell16.archive'.tr(),
    );
    if (!ok) { return; }
    try {
      await MarketplaceService.instance.archiveMyItem(item.id);
      if (mounted) { await _load(); }
    } catch (_) {
      if (mounted) { _snack('sell16.archiveFailed'.tr()); }
    }
  }

  Future<void> _markSold(MarketplaceItem item) async {
    final ok = await _confirm(
      title: 'sell16.markSoldTitle'.tr(),
      message: 'sell16.markSoldMessage'.tr(),
      confirmLabel: 'sell16.markSold'.tr(),
    );
    if (!ok) { return; }
    try {
      await MarketplaceService.instance.markMyItemSold(item.id);
      if (mounted) { await _load(); }
    } catch (_) {
      if (mounted) { _snack('sell16.markSoldFailed'.tr()); }
    }
  }

  Future<void> _delete(MarketplaceItem item) async {
    final ok = await _confirm(
      title: 'sell16.deleteTitle'.tr(),
      message: 'sell16.deleteMessage'.tr(),
      confirmLabel: 'sell16.delete'.tr(),
      destructive: true,
    );
    if (!ok) { return; }

    // Optimistic remove
    final backup = List<MarketplaceItem>.from(_items);
    setState(() => _items = _items.where((i) => i.id != item.id).toList());

    try {
      await MarketplaceService.instance.deleteMyItem(item.id);
      if (mounted) _snack('sell16.deleteSuccess'.tr());
    } catch (_) {
      // Rollback on failure
      if (mounted) {
        setState(() => _items = backup);
        _snack('sell16.deleteFailed'.tr());
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(message, style: const TextStyle(fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.red)
                : TextButton.styleFrom(foregroundColor: AppColors.orange),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF050D11) : AppColors.lightBackground;
    final textColor = isDark ? AppColors.text : AppColors.lightText;

    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(context, isDark, textColor),
        body: Center(child: Text('profile.loginRequired'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, isDark, textColor),
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? _LoadingSkeleton(isDark: isDark)
            : _hasError
                ? _ErrorState(onRetry: _load)
                : _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final displayed = _displayed;
    return CustomScrollView(
      slivers: [
        // Summary strip
        SliverToBoxAdapter(
          child: _SummaryStrip(items: _items, isDark: isDark),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: _FilterRow(
              filters: _filterKeys,
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
          ),
        ),

        // Content
        if (displayed.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: Icons.storefront_outlined,
              title: _items.isEmpty
                  ? 'marketplace.myListingsEmpty'.tr()
                  : 'sell16.filterEmpty'.tr(),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              14,
              2,
              14,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            sliver: SliverList.separated(
              itemCount: displayed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = displayed[i];
                return _MyListingCard(
                  item: item,
                  isDark: isDark,
                  onOpen: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketplaceItemDetailScreen(
                          item: item,
                          showOwnerStatus: true,
                        ),
                      ),
                    );
                    if (mounted) await _load();
                  },
                  onEdit: item.canEdit ? () => _edit(item) : null,
                  onMarkSold: item.canMarkSold ? () => _markSold(item) : null,
                  onArchive:
                      (!item.isArchived && !item.isSold)
                          ? () => _archive(item)
                          : null,
                  onDelete: () => _delete(item),
                );
              },
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark, Color textColor) {
    final iconColor = isDark ? AppColors.text : AppColors.lightText;
    final bg = isDark ? const Color(0xFF050D11) : AppColors.lightBackground;
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'marketplace.myListings'.tr(),
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: AppColors.orange, size: 26),
          tooltip: 'sell16.createTitle'.tr(),
          onPressed: () async {
            final result = await Navigator.push<MarketplaceItem>(
              context,
              MaterialPageRoute(
                builder: (_) => const MarketplaceListingFormScreen(),
              ),
            );
            if (result != null && mounted) await _load();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Summary strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<MarketplaceItem> items;
  final bool isDark;

  const _SummaryStrip({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox(height: 12);
    final activeCount = items.where((i) {
      return {'approved', 'active', 'published'}.contains(i.status);
    }).length;
    final totalCount = items.where((i) => i.status != 'deleted').length;

    final cardBg = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.lightBorder;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final textColor = isDark ? AppColors.text : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.green,
            value: activeCount,
            label: 'sell16.myListingsSummaryActive'.tr(),
            cardBg: cardBg,
            border: border,
            muted: muted,
            textColor: textColor,
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.list_alt_rounded,
            iconColor: AppColors.orange,
            value: totalCount,
            label: 'sell16.myListingsSummaryTotal'.tr(),
            cardBg: cardBg,
            border: border,
            muted: muted,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final Color cardBg;
  final Color border;
  final Color muted;
  final Color textColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.cardBg,
    required this.border,
    required this.muted,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

// ─── Filter row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveFill = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final inactiveBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.lightBorder;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = selected == f;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.orange : inactiveFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.orange : inactiveBorder,
                ),
              ),
              child: Text(
                'sell16.filter.$f'.tr(),
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : (isDark ? AppColors.gray : AppColors.lightGray),
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Compact listing management card ─────────────────────────────────────────

class _MyListingCard extends StatelessWidget {
  final MarketplaceItem item;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkSold;
  final VoidCallback? onArchive;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.item,
    required this.isDark,
    required this.onOpen,
    required this.onEdit,
    required this.onMarkSold,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.lightBorder;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: item.hasImage
                            ? CachedNetworkImage(
                                imageUrl: item.mainImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const _ImageFallback(),
                                errorWidget: (_, __, ___) =>
                                    const _ImageFallback(broken: true),
                              )
                            : const _ImageFallback(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.trim().isNotEmpty
                                ? item.title.trim()
                                : 'marketplace.listingUnavailable'.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _StatusChip(status: item.status),
                              const Spacer(),
                              if (item.createdAt != null)
                                Text(
                                  DateFormat.MMMd().format(item.createdAt!),
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rejection reason banner
                if (item.rejectionReason.trim().isNotEmpty &&
                    item.status == 'rejected')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'sell16.rejectionReason'.tr(
                          namedArgs: {'reason': item.rejectionReason.trim()},
                        ),
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Action row
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onEdit != null)
                      _InlineAction(
                        label: 'sell16.edit'.tr(),
                        onTap: onEdit!,
                        color: text,
                      ),
                    if (onEdit != null &&
                        (onMarkSold != null || onArchive != null))
                      _actionDivider(isDark),
                    if (onMarkSold != null)
                      _InlineAction(
                        label: 'sell16.markSold'.tr(),
                        onTap: onMarkSold!,
                        color: AppColors.orange,
                      ),
                    if (onMarkSold != null && onArchive != null)
                      _actionDivider(isDark),
                    if (onArchive != null)
                      _InlineAction(
                        label: 'sell16.archive'.tr(),
                        onTap: onArchive!,
                        color: muted,
                      ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'view') onOpen();
                        if (v == 'delete') onDelete();
                      },
                      color: isDark ? const Color(0xFF0E1D28) : Colors.white,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: muted,
                        size: 18,
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 15, color: text),
                            const SizedBox(width: 8),
                            Text(
                              'sell16.view'.tr(),
                              style: TextStyle(fontSize: 13, color: text),
                            ),
                          ]),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 15, color: AppColors.red),
                            const SizedBox(width: 8),
                            Text(
                              'sell16.delete'.tr(),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.red),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionDivider(bool isDark) => Container(
    width: 1,
    height: 12,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
  );
}

// ─── Inline compact action button ────────────────────────────────────────────

class _InlineAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _InlineAction({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

// ─── Status chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final n = status.toLowerCase();
    final (color, bgAlpha) = switch (n) {
      'approved' || 'active' || 'published' => (AppColors.green, 0.13),
      'sold' => (AppColors.green, 0.13),
      'rejected' => (AppColors.red, 0.11),
      'hidden' || 'archived' => (AppColors.gray, 0.18),
      _ => (AppColors.orange, 0.13),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        'sell16.status.$n'.tr(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── Image fallback ───────────────────────────────────────────────────────────

class _ImageFallback extends StatelessWidget {
  final bool broken;

  const _ImageFallback({this.broken = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF13262E) : AppColors.lightCard2,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_rounded : Icons.shopping_bag_rounded,
          color: AppColors.orange.withValues(alpha: 0.65),
          size: 26,
        ),
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatefulWidget {
  final bool isDark;

  const _LoadingSkeleton({required this.isDark});

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lo = widget.isDark
        ? const Color(0xFF0D1A20)
        : const Color(0xFFECF2F6);
    final hi = widget.isDark
        ? const Color(0xFF152535)
        : const Color(0xFFD8E4EC);
    final cardBg = widget.isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final border = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.lightBorder;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pulse = Color.lerp(lo, hi, _ctrl.value)!;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => Container(
            height: 110,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: pulse,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 11,
                        decoration: BoxDecoration(
                          color: pulse,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FractionallySizedBox(
                        widthFactor: 0.58,
                        child: Container(
                          height: 11,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 0.38,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FractionallySizedBox(
                        widthFactor: 0.26,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: pulse,
                            borderRadius: BorderRadius.circular(6),
                          ),
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
    );
  }
}

// ─── Error + Empty states ─────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 46, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(
            'marketplace.listingUnavailable'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
