import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_conversation_screen.dart';
import 'marketplace_listing_form_screen.dart';
import 'marketplace_profile_navigation.dart';

// ─── Batch 16D: Marketplace Trust + Contact + Detail Polish ─────────────────

class MarketplaceItemDetailScreen extends StatefulWidget {
  final MarketplaceItem item;
  final bool showOwnerStatus;

  const MarketplaceItemDetailScreen({
    super.key,
    required this.item,
    this.showOwnerStatus = false,
  });

  /// Builds deduplicated gallery URL list: coverImage first, then images[].
  /// Only includes valid HTTPS URLs. Excludes duplicates.
  static List<String> buildGalleryUrls(MarketplaceItem item) {
    final seen = <String>{};
    final result = <String>[];

    void add(String url) {
      final clean = url.trim();
      if (clean.isNotEmpty && clean.startsWith('http') && seen.add(clean)) {
        result.add(clean);
      }
    }

    add(item.coverImage);
    for (final u in item.images) {
      add(u);
    }
    if (result.isEmpty) add(item.mainImage);
    return result;
  }

  @override
  State<MarketplaceItemDetailScreen> createState() =>
      _MarketplaceItemDetailScreenState();
}

class _MarketplaceItemDetailScreenState
    extends State<MarketplaceItemDetailScreen> {
  late MarketplaceItem _item;
  int _galleryIndex = 0;
  late final PageController _pageCtrl;
  late final List<String> _galleryUrls;
  bool _contacting = false;
  bool _saved = false;
  bool _savePending = false;
  List<MarketplaceItem> _similarItems = const [];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _galleryUrls = MarketplaceItemDetailScreen.buildGalleryUrls(_item);
    _pageCtrl = PageController();
    if (kDebugMode) {
      debugPrint(
        '[Marketplace16C] detail_images item=${_item.id} '
        'cover=${_item.coverImage.isNotEmpty} '
        'image=${_item.images.isNotEmpty} '
        'images_count=${_item.images.length} '
        'final_count=${_galleryUrls.length}',
      );
    }
    _loadSavedState();
    _loadSimilarItems();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSimilarItems() async {
    try {
      final items = await MarketplaceService.instance.fetchSimilarItems(
        _item.id,
      );
      final safe =
          items.where((i) => i.isPublicMarketplaceVisible).toList(growable: false);
      if (!mounted) return;
      setState(() => _similarItems = safe);
    } catch (_) {
      // Best-effort — hide the section rather than show an error.
    }
  }

  Future<void> _loadSavedState() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final saved = await MarketplaceService.instance.isListingSaved(_item.id);
      if (!mounted) return;
      setState(() => _saved = saved);
    } catch (_) {
      // Best-effort — leave save state unknown rather than guessing.
    }
  }

  Future<void> _toggleSaved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }
    if (uid == _item.sellerId || _savePending) return;
    setState(() => _savePending = true);
    try {
      final nowSaved = _saved
          ? await MarketplaceService.instance.unsaveListing(_item.id)
          : await MarketplaceService.instance.saveListing(_item.id);
      if (!mounted) return;
      setState(() {
        _saved = nowSaved;
        _savePending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (_saved ? 'mkt.profile.saved' : 'mkt.profile.removeSaved').tr(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savePending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('mkt.profile.saveFailed'.tr())));
    }
  }

  // ─── Edit / Archive ────────────────────────────────────────────────────────

  Future<void> _edit() async {
    final updated = await Navigator.push<MarketplaceItem>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceListingFormScreen(existingItem: _item),
      ),
    );
    if (updated == null || !mounted) return;
    final newUrls = MarketplaceItemDetailScreen.buildGalleryUrls(updated);
    setState(() {
      _item = updated;
      _galleryUrls
        ..clear()
        ..addAll(newUrls);
      _galleryIndex = 0;
    });
    _pageCtrl.jumpToPage(0);
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('sell16.archiveTitle'.tr()),
        content: Text('sell16.archiveMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('sell16.archive'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final archived = await MarketplaceService.instance.archiveMyItem(
        _item.id,
      );
      if (!mounted) return;
      setState(() => _item = archived);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sell16.archiveFailed'.tr())));
    }
  }

  // ─── Contact seller ────────────────────────────────────────────────────────

  Future<void> _contact() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (kDebugMode) {
      debugPrint(
        '[Marketplace16D] contact_tap item=${_item.id} seller=${_item.sellerId} auth=${uid != null ? 'yes' : 'no'}',
      );
    }
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.loginRequired'.tr())),
      );
      return;
    }
    if (uid == _item.sellerId || _contacting) return;
    setState(() => _contacting = true);
    try {
      final conversation = await MarketplaceService.instance
          .startConversationForListing(_item);
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E] contact_open_conversation id=${conversation.id}',
        );
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketplaceConversationScreen(
            conversation: conversation,
            initialItem: _item,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.serviceUnavailable'.tr())),
      );
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  // ─── Report ────────────────────────────────────────────────────────────────

  Future<void> _report() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (kDebugMode) debugPrint('[Marketplace16D] report_tap item=${_item.id}');

    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }
    // Owner cannot report their own listing
    if (uid == _item.sellerId) return;

    // Reason picker dialog
    const reasons = [
      'scam',
      'wrongCategory',
      'prohibited',
      'offensive',
      'other',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('mkt.detail.reportTitle'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('mkt.detail.reportReason.$r'.tr()),
                  onTap: () => Navigator.pop(ctx, r),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    if (kDebugMode) {
      debugPrint(
        '[Marketplace16D] report_submit item=${_item.id} reason=$reason status=sending',
      );
    }
    try {
      await MarketplaceService.instance.reportItem(_item.id, uid, reason);
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16D] report_submit item=${_item.id} reason=$reason status=success',
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('mkt.detail.reportSent'.tr())));
    } catch (_) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16D] report_submit item=${_item.id} reason=$reason status=failed',
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('mkt.detail.reportFailed'.tr())));
    }
  }

  // ─── Open in Maps ──────────────────────────────────────────────────────────

  Future<void> _openMaps() async {
    final city = _item.city.trim().isNotEmpty ? _item.city.trim() : null;
    if (city == null) return;
    final uri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(city)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Fullscreen gallery ────────────────────────────────────────────────────

  void _openFullscreen(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullscreenGallery(urls: _galleryUrls, initialIndex: startIndex),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        actions: [
          if (!widget.showOwnerStatus)
            IconButton(
              icon: Icon(
                _saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: _saved ? AppColors.orange : muted,
              ),
              tooltip: 'mkt.profile.saveListing'.tr(),
              onPressed: _savePending ? null : _toggleSaved,
            ),
          if (!widget.showOwnerStatus)
            IconButton(
              icon: Icon(Icons.flag_outlined, color: muted),
              tooltip: 'mkt.detail.report'.tr(),
              onPressed: _report,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          // ── Gallery ──────────────────────────────────────────────────────
          _ImageGallery(
            urls: _galleryUrls,
            currentIndex: _galleryIndex,
            pageController: _pageCtrl,
            onPageChanged: (i) {
              if (kDebugMode) {
                debugPrint(
                  '[Marketplace16C] gallery_page item=${_item.id} index=$i/${_galleryUrls.length}',
                );
              }
              setState(() => _galleryIndex = i);
            },
            onTap: () =>
                _galleryUrls.isNotEmpty ? _openFullscreen(_galleryIndex) : null,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + price ─────────────────────────────────────────
                Text(
                  _item.title,
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _item.formattedPrice,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Metadata chips ────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_item.city.isNotEmpty)
                      _InfoChip(
                        icon: Icons.location_on_rounded,
                        label: _item.city,
                        color: AppColors.green,
                      ),
                    _InfoChip(
                      icon: Icons.layers_rounded,
                      label: 'sell16.condition.${_item.conditionKey}'.tr(),
                      color: AppColors.orange,
                    ),
                    _InfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: 'sell16.delivery.${_item.deliveryMethodKey}'.tr(),
                      color: AppColors.orange,
                    ),
                    if (_item.categoryKey.isNotEmpty)
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: 'sell16.category.${_item.categoryKey}'.tr(),
                        color: isDark ? AppColors.gray : AppColors.lightGray,
                      ),
                    if (widget.showOwnerStatus)
                      _InfoChip(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'sell16.status.${_item.status}'.tr(),
                        color: _statusColor(_item.status),
                      ),
                  ],
                ),

                // ── Rejection reason (owner only) ─────────────────────────
                if (widget.showOwnerStatus &&
                    _item.rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Card(
                    color: AppColors.red.withValues(alpha: .08),
                    border: AppColors.red.withValues(alpha: .3),
                    child: Text(
                      'sell16.rejectionReason'.tr(
                        namedArgs: {'reason': _item.rejectionReason},
                      ),
                      style: TextStyle(color: text, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Description ───────────────────────────────────────────
                if (_item.description.trim().isNotEmpty) ...[
                  _SectionLabel(
                    label: 'mkt.detail.description'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _Card(
                    color: card,
                    border: border,
                    child: _ExpandableText(
                      text: _item.description.trim(),
                      color: text,
                      muted: muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Seller card (public view only) ────────────────────────
                if (!widget.showOwnerStatus) ...[
                  _SectionLabel(
                    label: 'mkt.detail.seller'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _SellerCard(
                    item: _item,
                    card: card,
                    border: border,
                    text: text,
                    muted: muted,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Location ──────────────────────────────────────────────
                if (_item.city.isNotEmpty ||
                    _item.approximateLocationLabel.isNotEmpty) ...[
                  _SectionLabel(
                    label: 'mkt.detail.location'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _LocationCard(
                    item: _item,
                    card: card,
                    border: border,
                    text: text,
                    muted: muted,
                    onOpenMaps: _openMaps,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Safety tips (public only) ─────────────────────────────
                if (!widget.showOwnerStatus) ...[
                  _SafetyCard(isDark: isDark),
                  const SizedBox(height: 16),
                ],

                // ── Similar listings ──────────────────────────────────────
                if (_similarItems.isNotEmpty) ...[
                  _SectionLabel(
                    label: 'mkt.detail.similarListings'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _SimilarListingsStrip(
                    items: _similarItems,
                    onOpen: _openSimilarItem,
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(height: MediaQuery.of(context).padding.bottom + 72),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark, text, muted),
    );
  }

  Widget? _buildBottomBar(bool isDark, Color text, Color muted) {
    final isOwner =
        widget.showOwnerStatus ||
        FirebaseAuth.instance.currentUser?.uid == _item.sellerId;
    final bg = isDark ? AppColors.card : AppColors.lightCard;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: isOwner
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _item.canEdit ? _edit : null,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text('sell16.edit'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _item.isArchived ? null : _archive,
                    icon: const Icon(Icons.archive_outlined),
                    label: Text('sell16.archive'.tr()),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                InkWell(
                  onTap: _openSellerProfile,
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.orange.withValues(alpha: .15),
                    backgroundImage: _item.sellerAvatarUrl.startsWith('http')
                        ? NetworkImage(_item.sellerAvatarUrl)
                        : null,
                    child: _item.sellerAvatarUrl.startsWith('http')
                        ? null
                        : Icon(Icons.person_rounded, color: muted, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _contacting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(
                      _contacting
                          ? 'mkt.messages.starting'.tr()
                          : 'mkt.detail.contactSeller'.tr(),
                    ),
                    onPressed: _contacting ? null : _contact,
                  ),
                ),
              ],
            ),
    );
  }

  void _openSellerProfile() {
    openMarketplacePublicProfile(
      context: context,
      source: 'detail_bottom_bar',
      userId: _item.sellerId,
    );
  }

  Future<void> _openSimilarItem(MarketplaceItem item) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceItemDetailScreen(item: item),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'approved' || 'active' || 'published' => AppColors.green,
    'rejected' => AppColors.red,
    'hidden' || 'archived' => AppColors.gray,
    _ => AppColors.orange,
  };
}

// ─── Image gallery (PageView + counter + dots) ────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> urls;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onTap;

  const _ImageGallery({
    required this.urls,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = urls.isNotEmpty;
    final n = urls.length;

    return Stack(
      children: [
        // Main gallery or placeholder
        AspectRatio(
          aspectRatio: 1.05,
          child: hasImages
              ? PageView.builder(
                  controller: pageController,
                  itemCount: n,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: onTap,
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: AppColors.orange.withValues(alpha: .06),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                    ),
                  ),
                )
              : const _ImagePlaceholder(),
        ),

        // Counter badge (top right) — forced LTR so Arabic shows "1 / 4" not "4 / 1"
        if (n > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 48,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  '${currentIndex + 1} / $n',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

        // Dot indicators (bottom center)
        if (n > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(n, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.orange
                        : Colors.white.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─── Fullscreen gallery ───────────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullscreenGallery({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.urls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            '${_current + 1} / $n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.initialIndex),
        itemCount: n,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.orange,
                  strokeWidth: 1.5,
                ),
              ),
              errorWidget: (_, __, ___) => const _ImagePlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Expandable description ───────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;
  final Color color;
  final Color muted;

  const _ExpandableText({
    required this.text,
    required this.color,
    required this.muted,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _collapseThreshold = 280;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > _collapseThreshold;
    final display = isLong && !_expanded
        ? '${widget.text.substring(0, _collapseThreshold)}…'
        : widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display,
          style: TextStyle(color: widget.color, fontSize: 14, height: 1.55),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? 'mkt.detail.showLess'.tr()
                  : 'mkt.detail.showMore'.tr(),
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Seller card ──────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final MarketplaceItem item;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;

  const _SellerCard({
    required this.item,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    void openProfile() {
      final available = item.sellerId.trim().isNotEmpty;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E-A] detail_profile_tap '
          'seller=${item.sellerId} available=$available',
        );
      }
      openMarketplacePublicProfile(
        context: context,
        source: 'detail',
        userId: item.sellerId,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openProfile,
      child: _Card(
        color: card,
        border: border,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.orange.withValues(alpha: .15),
              backgroundImage: item.sellerAvatarUrl.startsWith('http')
                  ? NetworkImage(item.sellerAvatarUrl)
                  : null,
              child: item.sellerAvatarUrl.startsWith('http')
                  ? null
                  : Icon(Icons.person_rounded, color: muted, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.sellerName.trim().isNotEmpty
                              ? item.sellerName.trim()
                              : 'mkt.detail.unknownSeller'.tr(),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.sellerVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.orange,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (item.sellerUsername.trim().isNotEmpty)
                    Text(
                      '@${item.sellerUsername.trim()}',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.sellerVerified)
                    Text(
                      'mkt.detail.verifiedSeller'.tr(),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (item.sellerId.isNotEmpty) ...[
              InkWell(
                onTap: openProfile,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Text(
                    'mkt.detail.viewProfile'.tr(),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: muted, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Location card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final MarketplaceItem item;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final VoidCallback onOpenMaps;

  const _LocationCard({
    required this.item,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.approximateLocationLabel.trim().isNotEmpty
        ? item.approximateLocationLabel.trim()
        : item.city.trim();

    return _Card(
      color: card,
      border: border,
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
          ),
          if (item.city.trim().isNotEmpty)
            TextButton(
              onPressed: onOpenMaps,
              child: Text(
                'mkt.detail.openMaps'.tr(),
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Safety tips card ─────────────────────────────────────────────────────────

class _SafetyCard extends StatelessWidget {
  final bool isDark;
  const _SafetyCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tips = [
      'mkt.detail.safetyTip1'.tr(),
      'mkt.detail.safetyTip2'.tr(),
      'mkt.detail.safetyTip3'.tr(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'mkt.detail.safetyTitle'.tr(),
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.green)),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: isDark ? AppColors.gray : AppColors.lightGray,
                        fontSize: 12,
                        height: 1.4,
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
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: isDark ? AppColors.text : AppColors.lightText,
      fontWeight: FontWeight.w900,
      fontSize: 15,
    ),
  );
}

class _Card extends StatelessWidget {
  final Color color;
  final Color border;
  final Widget child;

  const _Card({required this.color, required this.border, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    ),
    child: child,
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: .08),
    child: const Center(
      child: Icon(
        Icons.shopping_bag_rounded,
        color: AppColors.orange,
        size: 60,
      ),
    ),
  );
}

class _SimilarListingsStrip extends StatelessWidget {
  const _SimilarListingsStrip({required this.items, required this.onOpen});

  final List<MarketplaceItem> items;
  final ValueChanged<MarketplaceItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;
    final text = isDark ? AppColors.text : AppColors.lightText;

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onOpen(item),
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: item.hasImage
                        ? CachedNetworkImage(
                            imageUrl: item.mainImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          )
                        : const _ImagePlaceholder(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
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
    );
  }
}
