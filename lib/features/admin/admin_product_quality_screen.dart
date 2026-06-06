import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_product_quality_model.dart';
import 'admin_provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminProductQualityScreen extends StatefulWidget {
  const AdminProductQualityScreen({super.key});

  @override
  State<AdminProductQualityScreen> createState() => _AdminProductQualityScreenState();
}

class _AdminProductQualityScreenState extends State<AdminProductQualityScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProductQuality();
    });
  }

  List<AdminProductQualityItemModel> _applyFilter(List<AdminProductQualityItemModel> items) {
    switch (_filter) {
      case 'quarantined':
        return items.where((i) => i.trustStatus == 'quarantined').toList();
      case 'needs_review':
        return items.where((i) => i.trustStatus == 'needs_review' || i.issue == 'needs_review').toList();
      case 'missing_image':
        return items.where((i) => i.qualityFlags.contains('missing_image') || i.issue == 'missing_image').toList();
      case 'missing_link':
        return items.where((i) => i.qualityFlags.contains('missing_link') || i.issue == 'missing_url').toList();
      case 'single_image':
        return items.where((i) => i.qualityFlags.contains('single_image_only')).toList();
      case 'duplicates':
        return items.where((i) => i.qualityFlags.contains('duplicate_candidate')).toList();
      case 'trusted':
        return items.where((i) => i.trustStatus == 'trusted').toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final filtered = _applyFilter(provider.productQualityItems);

    return Column(
      children: [
        _ScanPanel(provider: provider),
        _FilterRow(
          current: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: _buildList(provider, filtered),
        ),
      ],
    );
  }

  Widget _buildList(AdminProvider provider, List<AdminProductQualityItemModel> items) {
    if (provider.isLoadingProductQuality && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    if (provider.productQualityError != null && items.isEmpty) {
      return _ErrorRetry(msg: provider.productQualityError!, onRetry: provider.loadProductQuality);
    }
    if (items.isEmpty) {
      return _EmptyState('admin.noData'.tr());
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadProductQuality,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, i) => _ProductCard(
          item: items[i],
          onAction: (action, reason) async {
            final ok = await provider.actOnProduct(items[i].id, action, reason: reason);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'admin.actionSuccess'.tr() : 'admin.actionFailed'.tr()),
                backgroundColor: ok ? AppColors.green : AppColors.red,
              ));
            }
          },
        ),
      ),
    );
  }
}

// ─── Scan panel ───────────────────────────────────────────────────────────────

class _ScanPanel extends StatelessWidget {
  const _ScanPanel({required this.provider});
  final AdminProvider provider;

  Future<void> _confirmApplyScan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.confirmApplyScan'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('admin.confirmApplyScanMessage'.tr(), style: const TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final result = await provider.applyProductQualityScan(limit: 100);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result != null ? 'admin.scanCompleted'.tr() : 'admin.scanFailed'.tr()),
          backgroundColor: result != null ? AppColors.green : AppColors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.orange.withValues(alpha: 0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Btn(
                  label: 'admin.dryRunScan'.tr(),
                  color: AppColors.orange,
                  icon: Icons.analytics_rounded,
                  onTap: provider.isScanLoading ? null : () => provider.runDryRunScan(limit: 100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Btn(
                  label: 'admin.applyScan'.tr(),
                  color: AppColors.red,
                  icon: Icons.published_with_changes_rounded,
                  onTap: provider.isScanLoading ? null : () => _confirmApplyScan(context),
                ),
              ),
            ],
          ),
          if (provider.isScanLoading) ...[
            const SizedBox(height: 8),
            const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))),
          ],
          if (provider.scanError != null) ...[
            const SizedBox(height: 6),
            Text('admin.scanFailed'.tr(), style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          if (provider.lastScanSummary != null) ...[
            const SizedBox(height: 10),
            _ScanSummaryCard(summary: provider.lastScanSummary!),
          ],
        ],
      ),
    );
  }
}

// ─── Scan summary card ───────────────────────────────────────────────────────

class _ScanSummaryCard extends StatelessWidget {
  const _ScanSummaryCard({required this.summary});
  final ProductTrustScanSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final label = summary.dryRun ? 'admin.dryRunScan'.tr() : 'admin.applyScan'.tr();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.summarize_rounded, color: AppColors.orange, size: 14),
            const SizedBox(width: 6),
            Text('${'admin.scanSummary'.tr()} · $label',
                style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _stat('admin.scanned'.tr(), summary.scanned, Colors.white),
            _stat('admin.wouldUpdate'.tr(), summary.wouldUpdate, AppColors.orange),
            if (!summary.dryRun) _stat('admin.updated'.tr(), summary.updated, AppColors.green),
            _stat('admin.missingImage'.tr(), summary.missingImage, Colors.amber),
            _stat('admin.missingLink'.tr(), summary.missingLink, AppColors.orange),
            _stat('admin.missingPrice'.tr(), summary.missingPrice, AppColors.red),
            _stat('admin.singleImageOnly'.tr(), summary.singleImageOnly, Colors.amber.shade700),
            _stat('admin.duplicates'.tr(), summary.duplicates, Colors.purple),
            _stat('admin.quarantined'.tr(), summary.quarantined, AppColors.red),
            _stat('admin.needsReview'.tr(), summary.needsReview, Colors.amber),
            _stat('admin.trusted'.tr(), summary.trusted, AppColors.green),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(text: '$value ', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            TextSpan(text: label, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
          ]),
        ),
      );
}

// ─── Filter row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('all', 'admin.filterAll'),
    ('quarantined', 'admin.filterQuarantined'),
    ('needs_review', 'admin.filterNeedsReview'),
    ('missing_image', 'admin.filterMissingImage'),
    ('missing_link', 'admin.filterMissingLink'),
    ('single_image', 'admin.filterSingleImage'),
    ('duplicates', 'admin.filterDuplicates'),
    ('trusted', 'admin.filterTrusted'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (value, key) = _filters[i];
          final selected = current == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.orange : AppColors.gray.withValues(alpha: 0.3)),
              ),
              child: Text(
                key.tr(),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.gray,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onAction});
  final AdminProductQualityItemModel item;
  final void Function(String action, String? reason) onAction;

  Color _trustColor() {
    switch (item.trustStatus) {
      case 'trusted':
        return AppColors.green;
      case 'ok':
        return Colors.blue;
      case 'needs_review':
        return Colors.amber;
      case 'quarantined':
        return AppColors.red;
      case 'hidden':
        return AppColors.gray;
      default:
        // Fall back to legacy issue color
        return switch (item.issue) {
          'missing_image' => Colors.amber,
          'missing_url' => AppColors.orange,
          'needs_review' => Colors.amber,
          'hidden' => AppColors.gray,
          _ => AppColors.gray,
        };
    }
  }

  Color _priceConfColor() => switch (item.priceConfidence) {
        'confirmed' => AppColors.green,
        'approximate' => Colors.amber,
        'needs_review' => AppColors.orange,
        'missing' => AppColors.red,
        _ => AppColors.gray,
      };

  String _priceConfLabel() => switch (item.priceConfidence) {
        'confirmed' => 'admin.priceConfirmed'.tr(),
        'approximate' => 'admin.priceApproximate'.tr(),
        'needs_review' => 'admin.priceNeedsReview'.tr(),
        'missing' => 'admin.priceMissing'.tr(),
        _ => '',
      };

  static const _invalidCurrencies = {'global', 'unknown', 'null', 'none', 'n/a', 'na', '', 'undefined', 'mixed'};

  List<Widget> _priceRow() {
    final price = item.price;
    final countryCode = item.countryCode ?? '';
    final isBadCurrency = _invalidCurrencies.contains(countryCode.toLowerCase());

    // Missing or zero price
    if (price == null || price <= 0) {
      return [
        const SizedBox(height: 2),
        Text(
          'admin.priceMissing'.tr(),
          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 11),
        ),
      ];
    }

    // Valid price but bad/missing currency
    final currencyDisplay = isBadCurrency ? '' : ' $countryCode';
    return [
      const SizedBox(height: 2),
      Row(children: [
        Text(
          '${price.toStringAsFixed(2)}$currencyDisplay',
          style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        if (isBadCurrency) ...[
          const SizedBox(width: 4),
          Text(
            'admin.missingCurrency'.tr(),
            style: const TextStyle(color: AppColors.red, fontSize: 10),
          ),
        ],
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _trustColor();
    final media = item.mediaQuality;
    final link = item.linkHealth;
    final score = item.qualityScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: media?.mainImage ?? item.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    item.name ?? 'admin.noData'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.store?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(item.store!, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
                  ],
                  ..._priceRow(),
                ]),
              ),
              const SizedBox(width: 8),
              // Quality score badge
              if (score != null)
                _ScoreBadge(score: score),
            ],
          ),
          const SizedBox(height: 10),

          // ── Trust status + price confidence ──
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (item.trustStatus != null)
              _TrustChip(label: item.trustStatus!, color: _trustColor()),
            if (item.priceConfidence != null && item.priceConfidence!.isNotEmpty)
              _TrustChip(label: _priceConfLabel(), color: _priceConfColor()),
          ]),

          // ── Media quality info ──
          if (media != null) ...[
            const SizedBox(height: 8),
            _MediaRow(media: media),
          ],

          // ── Link health info ──
          if (link != null) ...[
            const SizedBox(height: 6),
            _LinkRow(link: link),
          ],

          // ── Quality flags ──
          if (item.qualityFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: item.qualityFlags.map(_flagChip).toList()),
          ],

          const SizedBox(height: 12),

          // ── Action buttons ──
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Btn(label: 'admin.refreshQuality'.tr(), color: Colors.blue, icon: Icons.refresh_rounded,
                onTap: () => onAction('refresh', null)),
            _Btn(label: 'admin.markSafe'.tr(), color: AppColors.green, icon: Icons.verified_rounded,
                onTap: () => onAction('mark_safe', null)),
            _Btn(label: 'admin.markReview'.tr(), color: Colors.amber, icon: Icons.rate_review_rounded,
                onTap: () => _promptReason(context, 'mark_review')),
            _Btn(label: 'admin.hide'.tr(), color: AppColors.gray, icon: Icons.visibility_off_rounded,
                onTap: () => _promptReason(context, 'hide')),
            if (item.status == 'hidden')
              _Btn(label: 'admin.restore'.tr(), color: AppColors.orange, icon: Icons.restore_rounded,
                  onTap: () => onAction('restore', null)),
          ]),
        ],
      ),
    );
  }

  Widget _flagChip(String flag) {
    final color = _flagColor(flag);
    final label = _flagLabel(flag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Color _flagColor(String flag) {
    if (flag == 'missing_image' || flag == 'no_gallery') return AppColors.red;
    if (flag == 'missing_link' || flag == 'invalid_link') return AppColors.red;
    if (flag == 'missing_price' || flag == 'suspicious_price') return AppColors.orange;
    if (flag == 'single_image_only') return Colors.amber;
    if (flag == 'duplicate_images' || flag == 'duplicate_candidate') return Colors.purple;
    return AppColors.gray;
  }

  String _flagLabel(String flag) => switch (flag) {
        'missing_image' => 'admin.missingImage'.tr(),
        'no_gallery' => 'admin.noGallery'.tr(),
        'single_image_only' => 'admin.singleImageOnly'.tr(),
        'duplicate_images' => 'admin.duplicateImages'.tr(),
        'missing_link' => 'admin.missingLink'.tr(),
        'invalid_link' => 'admin.invalidLink'.tr(),
        'missing_price' => 'admin.missingPrice'.tr(),
        'suspicious_price' => 'admin.priceNeedsReview'.tr(),
        'duplicate_candidate' => 'admin.duplicates'.tr(),
        _ => flag.replaceAll('_', ' ').toUpperCase(),
      };

  Future<void> _promptReason(BuildContext context, String action) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.reason'.tr(), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin.reason'.tr(),
            hintStyle: const TextStyle(color: AppColors.gray),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onAction(action, ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final valid = url?.startsWith('http') == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: valid
          ? Image.network(url!, width: 56, height: 56, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image_not_supported_rounded, color: AppColors.gray, size: 20),
      );
}

// ─── Score badge ──────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  Color get _color {
    if (score >= 85) return AppColors.green;
    if (score >= 65) return Colors.blue;
    if (score >= 35) return Colors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color.withValues(alpha: 0.15),
          border: Border.all(color: _color.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          '$score',
          style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      );
}

// ─── Trust chip ───────────────────────────────────────────────────────────────

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

// ─── Media row ────────────────────────────────────────────────────────────────

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.media});
  final ProductMediaQualityModel media;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.photo_library_rounded, size: 12, color: AppColors.gray),
      const SizedBox(width: 4),
      Text(
        '${media.validImageCount} img',
        style: TextStyle(
          color: media.validImageCount == 0 ? AppColors.red : (media.hasMultipleImages ? AppColors.green : Colors.amber),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (media.duplicateImageCount > 0) ...[
        const SizedBox(width: 6),
        Text('·  ${media.duplicateImageCount} dup', style: const TextStyle(color: Colors.purple, fontSize: 11)),
      ],
      if (!media.hasMultipleImages && media.validImageCount == 1) ...[
        const SizedBox(width: 6),
        Text('admin.singleImageOnly'.tr(), style: const TextStyle(color: Colors.amber, fontSize: 10)),
      ],
      if (media.validImageCount == 0) ...[
        const SizedBox(width: 6),
        Text('admin.noGallery'.tr(), style: const TextStyle(color: AppColors.red, fontSize: 10)),
      ],
    ]);
  }
}

// ─── Link row ─────────────────────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});
  final ProductLinkHealthModel link;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        link.isValidHttpUrl ? Icons.link_rounded : Icons.link_off_rounded,
        size: 12,
        color: link.isValidHttpUrl ? AppColors.green : AppColors.red,
      ),
      const SizedBox(width: 4),
      if (link.hasAffiliateUrl)
        Text('admin.hasAffiliateLink'.tr(), style: const TextStyle(color: AppColors.green, fontSize: 10)),
      if (!link.hasAffiliateUrl && link.hasProductUrl)
        Text('admin.hasProductLink'.tr(), style: const TextStyle(color: Colors.blue, fontSize: 10)),
      if (!link.isValidHttpUrl)
        Text('  ·  ${'admin.invalidLink'.tr()}', style: const TextStyle(color: AppColors.red, fontSize: 10)),
    ]);
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_rounded, color: AppColors.green, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.gray)),
        ]),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 40),
          const SizedBox(height: 12),
          Text('admin.loadError'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('admin.retry'.tr()),
          ),
        ]),
      );
}
