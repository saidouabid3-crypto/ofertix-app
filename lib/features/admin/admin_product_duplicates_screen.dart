import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_duplicate_model.dart';
import 'admin_provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminProductDuplicatesScreen extends StatefulWidget {
  const AdminProductDuplicatesScreen({super.key});

  @override
  State<AdminProductDuplicatesScreen> createState() => _AdminProductDuplicatesScreenState();
}

class _AdminProductDuplicatesScreenState extends State<AdminProductDuplicatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDuplicateGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        _DuplicateScanPanel(provider: provider),
        _StatusFilterRow(
          current: provider.selectedDuplicateStatusFilter,
          onChanged: (s) {
            provider.selectedDuplicateStatusFilter = s;
            provider.loadDuplicateGroups(status: s);
          },
        ),
        Expanded(child: _buildList(provider)),
      ],
    );
  }

  Widget _buildList(AdminProvider provider) {
    if (provider.isDuplicatesLoading && provider.duplicateGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    if (provider.duplicatesError != null && provider.duplicateGroups.isEmpty) {
      return _ErrorRetry(
        msg: provider.duplicatesError!,
        onRetry: provider.loadDuplicateGroups,
      );
    }
    if (provider.duplicateGroups.isEmpty) {
      return _EmptyState('admin.noDuplicateGroups'.tr());
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadDuplicateGroups,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.duplicateGroups.length,
        itemBuilder: (context, i) => _DuplicateGroupCard(
          group: provider.duplicateGroups[i],
          provider: provider,
        ),
      ),
    );
  }
}

// ─── Scan panel ───────────────────────────────────────────────────────────────

class _DuplicateScanPanel extends StatelessWidget {
  const _DuplicateScanPanel({required this.provider});
  final AdminProvider provider;

  Future<void> _confirmApplyScan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.confirmApplyDuplicateScan'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('admin.confirmApplyDuplicateScanMessage'.tr(),
            style: const TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('admin.dismiss'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final result = await provider.applyDuplicateScan(limit: 300);
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
          Row(children: [
            Expanded(
              child: _ScanBtn(
                label: 'admin.dryRunDuplicateScan'.tr(),
                icon: Icons.document_scanner_rounded,
                color: AppColors.orange,
                disabled: provider.isDuplicateScanLoading,
                onTap: () => provider.runDuplicateDryRunScan(limit: 300),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScanBtn(
                label: 'admin.applyDuplicateScan'.tr(),
                icon: Icons.merge_rounded,
                color: AppColors.red,
                disabled: provider.isDuplicateScanLoading,
                onTap: () => _confirmApplyScan(context),
              ),
            ),
          ]),
          if (provider.isDuplicateScanLoading) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2),
              ),
            ),
          ],
          if (provider.duplicateScanError != null) ...[
            const SizedBox(height: 6),
            Text('admin.scanFailed'.tr(), style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          if (provider.lastDuplicateScanSummary != null) ...[
            const SizedBox(height: 10),
            _DuplicateScanSummaryCard(summary: provider.lastDuplicateScanSummary!),
          ],
        ],
      ),
    );
  }
}

class _ScanBtn extends StatelessWidget {
  const _ScanBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
      );
}

// ─── Scan summary card ────────────────────────────────────────────────────────

class _DuplicateScanSummaryCard extends StatelessWidget {
  const _DuplicateScanSummaryCard({required this.summary});
  final AdminDuplicateScanSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final label = summary.dryRun ? 'admin.dryRunDuplicateScan'.tr() : 'admin.applyDuplicateScan'.tr();
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
            const Icon(Icons.summarize_rounded, color: AppColors.orange, size: 13),
            const SizedBox(width: 6),
            Text('${'admin.duplicateScanSummary'.tr()} · $label',
                style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _stat('admin.scanned'.tr(), summary.scanned, Colors.white),
            _stat('admin.groupsFound'.tr(), summary.groupsFound, AppColors.orange),
            _stat('admin.candidateProducts'.tr(), summary.candidateProducts, Colors.amber),
            _stat('admin.wouldUpdate'.tr(), summary.wouldUpdate, Colors.blue),
            if (!summary.dryRun) _stat('admin.updated'.tr(), summary.updated, AppColors.green),
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

// ─── Status filter row ────────────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('candidate', 'admin.candidate'),
    ('master', 'admin.masterProduct'),
    ('duplicate', 'admin.duplicateProduct'),
    ('dismissed', 'admin.dismissed'),
    ('all', 'admin.filterAll'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
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
                  border: Border.all(
                      color: selected ? AppColors.orange : AppColors.gray.withValues(alpha: 0.3)),
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

// ─── Duplicate group card ─────────────────────────────────────────────────────

class _DuplicateGroupCard extends StatelessWidget {
  const _DuplicateGroupCard({required this.group, required this.provider});
  final AdminDuplicateGroupModel group;
  final AdminProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.content_copy_rounded, color: AppColors.orange, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${'admin.duplicateGroup'.tr()} · ${group.groupId}',
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${group.highestScore}pt',
                    style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          // ── Reason chips ──
          if (group.reasonSummary?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (group.reasonSummary ?? '').split(', ').where((r) => r.isNotEmpty).map(_reasonChip).toList(),
              ),
            ),
          // ── Product rows ──
          ...group.products.map((p) => _DuplicateProductRow(
                product: p,
                group: group,
                provider: provider,
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _reasonChip(String reason) {
    final label = _reasonLabel(reason);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  String _reasonLabel(String r) => switch (r) {
        'same_affiliate_url' => 'admin.sameAffiliateUrl'.tr(),
        'same_product_url' => 'admin.sameProductUrl'.tr(),
        'same_primary_url' => 'admin.samePrimaryUrl'.tr(),
        'same_main_image' => 'admin.sameMainImage'.tr(),
        'same_title_store_price' => 'admin.sameTitleStorePrice'.tr(),
        'same_title_similar_price' => 'admin.sameTitleSimilarPrice'.tr(),
        _ => r.replaceAll('_', ' '),
      };
}

// ─── Duplicate product row ────────────────────────────────────────────────────

class _DuplicateProductRow extends StatelessWidget {
  const _DuplicateProductRow({required this.product, required this.group, required this.provider});
  final AdminDuplicateProductModel product;
  final AdminDuplicateGroupModel group;
  final AdminProvider provider;

  Color _statusColor() => switch (product.duplicateStatus) {
        'master' => AppColors.green,
        'duplicate' => AppColors.gray,
        'dismissed' => Colors.purple,
        _ => AppColors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Thumb(url: product.imageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  product.name ?? 'admin.noData'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.store?.isNotEmpty == true)
                  Text(product.store!, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
                if (product.price != null)
                  Text(
                    '${product.price!.toStringAsFixed(2)} ${product.currency ?? ''}',
                    style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
              ]),
            ),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (product.qualityScore != null) _ScoreBadge(score: product.qualityScore!),
              const SizedBox(height: 4),
              if (product.duplicateStatus != null)
                _Chip(label: product.duplicateStatus!, color: statusColor),
            ]),
          ]),
          // ── Link + image info ──
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              product.primaryUrl?.startsWith('http') == true
                  ? Icons.link_rounded
                  : Icons.link_off_rounded,
              size: 11,
              color: product.primaryUrl?.startsWith('http') == true ? AppColors.green : AppColors.red,
            ),
            const SizedBox(width: 4),
            if (product.hasAffiliateUrl)
              const Text('affiliate', style: TextStyle(color: AppColors.green, fontSize: 10)),
            if (!product.hasAffiliateUrl && product.hasProductUrl)
              const Text('product url', style: TextStyle(color: Colors.blue, fontSize: 10)),
            if (product.galleryCount > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.photo_library_rounded, size: 11, color: AppColors.gray),
              const SizedBox(width: 2),
              Text('${product.galleryCount}',
                  style: const TextStyle(color: AppColors.gray, fontSize: 10)),
            ],
            if (product.trustStatus != null) ...[
              const SizedBox(width: 8),
              _Chip(label: product.trustStatus!, color: _trustColor(product.trustStatus)),
            ],
          ]),
          // ── Actions ──
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _ActionBtn(
              label: 'admin.markAsMaster'.tr(),
              color: AppColors.green,
              icon: Icons.verified_rounded,
              onTap: () => _confirmAction(
                context,
                title: 'admin.confirmMarkMaster'.tr(),
                message: 'admin.confirmMarkMasterMessage'.tr(),
                onConfirm: (note) => provider.markDuplicateMaster(group.groupId, product.id, note: note),
              ),
            ),
            _ActionBtn(
              label: 'admin.hideAsDuplicate'.tr(),
              color: AppColors.red,
              icon: Icons.visibility_off_rounded,
              onTap: () => _confirmHide(context),
            ),
            _ActionBtn(
              label: 'admin.dismissDuplicate'.tr(),
              color: Colors.purple,
              icon: Icons.do_not_disturb_rounded,
              onTap: () => _confirmAction(
                context,
                title: 'admin.confirmDismissDuplicate'.tr(),
                message: 'admin.confirmDismissDuplicateMessage'.tr(),
                onConfirm: (note) => provider.dismissDuplicate(product.id, note: note),
              ),
            ),
            if (product.status == 'hidden')
              _ActionBtn(
                label: 'admin.restoreDuplicate'.tr(),
                color: AppColors.orange,
                icon: Icons.restore_rounded,
                onTap: () async {
                  final ok = await provider.restoreDuplicate(product.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'admin.duplicateActionSuccess'.tr() : 'admin.duplicateActionFailed'.tr()),
                      backgroundColor: ok ? AppColors.green : AppColors.red,
                    ));
                  }
                },
              ),
          ]),
        ],
      ),
    );
  }

  Color _trustColor(String? status) => switch (status) {
        'trusted' => AppColors.green,
        'ok' => Colors.blue,
        'needs_review' => Colors.amber,
        'quarantined' => AppColors.red,
        _ => AppColors.gray,
      };

  Future<void> _confirmHide(BuildContext context) async {
    // Need master product id — use first product in group that is not this one
    final others = group.products.where((p) => p.id != product.id).toList();
    final master = others.firstWhere(
      (p) => p.duplicateStatus == 'master',
      orElse: () => others.isNotEmpty ? others.first : product,
    );

    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.confirmHideDuplicate'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('admin.confirmHideDuplicateMessage'.tr(),
              style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'admin.actionNote'.tr(),
              hintStyle: const TextStyle(color: AppColors.gray),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.hideDuplicate(
        product.id,
        master.id,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'admin.duplicateActionSuccess'.tr() : 'admin.duplicateActionFailed'.tr()),
          backgroundColor: ok ? AppColors.green : AppColors.red,
        ));
      }
    }
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function(String? note) onConfirm,
  }) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'admin.actionNote'.tr(),
              hintStyle: const TextStyle(color: AppColors.gray),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
            ),
          ),
        ]),
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
      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
      final ok = await onConfirm(note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'admin.duplicateActionSuccess'.tr() : 'admin.duplicateActionFailed'.tr()),
          backgroundColor: ok ? AppColors.green : AppColors.red,
        ));
      }
    }
  }
}

// ─── Shared micro-widgets ─────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final valid = url?.startsWith('http') == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: valid
          ? Image.network(url!, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image_not_supported_rounded, color: AppColors.gray, size: 18),
      );
}

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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color.withValues(alpha: 0.15),
          border: Border.all(color: _color.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text('$score', style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 11)),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 48),
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
          Text('admin.loadDuplicatesFailed'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
