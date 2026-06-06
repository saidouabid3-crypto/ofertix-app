import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_import_batch_model.dart';
import '../../models/admin_source_trust_model.dart';
import 'admin_provider.dart';

class AdminImportIntelligenceScreen extends StatefulWidget {
  const AdminImportIntelligenceScreen({super.key});

  @override
  State<AdminImportIntelligenceScreen> createState() => _AdminImportIntelligenceScreenState();
}

class _AdminImportIntelligenceScreenState extends State<AdminImportIntelligenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminProvider>();
      p.loadImportBatches();
      p.loadSourceTrust();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () async {
        await provider.loadImportBatches();
        await provider.loadSourceTrust();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('admin.importBatches'.tr()),
          const SizedBox(height: 12),
          if (provider.isLoadingImportBatches && provider.importBatches.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.orange),
            ))
          else if (provider.importBatchesError != null && provider.importBatches.isEmpty)
            _ErrorRetry(
              msg: provider.importBatchesError!,
              onRetry: provider.loadImportBatches,
            )
          else if (provider.importBatches.isEmpty)
            _EmptyState('admin.noImportBatches'.tr())
          else
            ...provider.importBatches.map((b) => _ImportBatchCard(
              batch: b,
              onHide: () => _confirmBatchAction(
                context,
                provider,
                batchId: b.batchId,
                action: 'hide',
                label: 'admin.hideBatchProducts'.tr(),
                message: 'admin.hideBatchProductsMessage'.tr(),
              ),
              onReview: () => _confirmBatchAction(
                context,
                provider,
                batchId: b.batchId,
                action: 'review',
                label: 'admin.markBatchReview'.tr(),
                message: 'admin.markBatchReviewMessage'.tr(),
              ),
              onRestore: () => _confirmBatchAction(
                context,
                provider,
                batchId: b.batchId,
                action: 'restore',
                label: 'admin.restoreBatchProducts'.tr(),
                message: 'admin.restoreBatchProductsMessage'.tr(),
              ),
            )),
          const SizedBox(height: 24),
          _SectionTitle('admin.sourceTrust'.tr()),
          const SizedBox(height: 12),
          if (provider.isLoadingSourceTrust && provider.sourceTrustList.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.orange),
            ))
          else if (provider.sourceTrustError != null && provider.sourceTrustList.isEmpty)
            _ErrorRetry(
              msg: provider.sourceTrustError!,
              onRetry: provider.loadSourceTrust,
            )
          else if (provider.sourceTrustList.isEmpty)
            _EmptyState('admin.noSourceTrust'.tr())
          else
            ...provider.sourceTrustList.map((s) => _SourceTrustCard(source: s)),
        ],
      ),
    );
  }

  Future<void> _confirmBatchAction(
    BuildContext context,
    AdminProvider provider, {
    required String batchId,
    required String action,
    required String label,
    required String message,
  }) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'admin.actionNote'.tr(),
                hintStyle: const TextStyle(color: AppColors.gray),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('admin.dismiss'.tr(), style: const TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
    bool ok = false;

    switch (action) {
      case 'hide':
        ok = await provider.hideImportBatchProducts(batchId, note: note);
      case 'review':
        ok = await provider.markImportBatchReview(batchId, note: note);
      case 'restore':
        ok = await provider.restoreImportBatchProducts(batchId, note: note);
    }

    if (!context.mounted) return;
    final msg = ok ? 'admin.actionSuccess'.tr() : (provider.importActionError ?? 'admin.actionFailed'.tr());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.green : AppColors.red,
      duration: const Duration(seconds: 3),
    ));
  }
}

// ─── import batch card ────────────────────────────────────────────────────────

class _ImportBatchCard extends StatelessWidget {
  final AdminImportBatchModel batch;
  final VoidCallback onHide;
  final VoidCallback onReview;
  final VoidCallback onRestore;

  const _ImportBatchCard({
    required this.batch,
    required this.onHide,
    required this.onReview,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: batch.hasWarnings
            ? Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.source ?? batch.store ?? batch.batchId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(batch.status),
                if (batch.dryRun) ...[
                  const SizedBox(width: 6),
                  _Chip('DRY RUN', AppColors.gray),
                ],
              ],
            ),
            if (batch.startedAt != null) ...[
              const SizedBox(height: 4),
              Text(batch.startedAt!, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CounterChip('admin.imported'.tr(), batch.imported, AppColors.orange),
                _CounterChip('admin.approved'.tr(), batch.approved, AppColors.green),
                if (batch.needsReview > 0) _CounterChip('admin.needsReview'.tr(), batch.needsReview, Colors.amber),
                if (batch.quarantined > 0) _CounterChip('admin.quarantined'.tr(), batch.quarantined, AppColors.red),
                if (batch.duplicateCandidates > 0) _CounterChip('admin.duplicates'.tr(), batch.duplicateCandidates, Colors.purple),
                if (batch.missingImage > 0) _CounterChip('admin.missingImage'.tr(), batch.missingImage, AppColors.gray),
                if (batch.missingLink > 0) _CounterChip('admin.missingLink'.tr(), batch.missingLink, AppColors.gray),
                if (batch.missingPrice > 0) _CounterChip('admin.missingPrice'.tr(), batch.missingPrice, AppColors.gray),
                if (batch.failed > 0) _CounterChip('admin.failed'.tr(), batch.failed, AppColors.red),
              ],
            ),
            if (batch.sourceTrustScore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.gray, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '${'admin.sourceTrustScore'.tr()}: ${batch.sourceTrustScore}',
                    style: const TextStyle(color: AppColors.gray, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionBtn('admin.markReview'.tr(), Icons.rate_review_outlined, Colors.amber, onReview),
                const SizedBox(width: 8),
                _ActionBtn('admin.hide'.tr(), Icons.visibility_off_outlined, AppColors.red, onHide),
                const SizedBox(width: 8),
                _ActionBtn('admin.restore'.tr(), Icons.restore_outlined, AppColors.green, onRestore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── source trust card ────────────────────────────────────────────────────────

class _SourceTrustCard extends StatelessWidget {
  final AdminSourceTrustModel source;

  const _SourceTrustCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: source.isAtRisk
            ? Border.all(color: AppColors.red.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    source.displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _TrustStatusChip(source.status),
                const SizedBox(width: 6),
                _ScoreBadge(source.sourceTrustScore),
              ],
            ),
            if (source.store != null && source.store != source.displayName) ...[
              const SizedBox(height: 2),
              Text(source.store!, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CounterChip('admin.imported'.tr(), source.totalImported, AppColors.orange),
                if (source.totalQuarantined > 0) _CounterChip('admin.quarantined'.tr(), source.totalQuarantined, AppColors.red),
                if (source.totalNeedsReview > 0) _CounterChip('admin.needsReview'.tr(), source.totalNeedsReview, Colors.amber),
                if (source.totalDuplicates > 0) _CounterChip('admin.duplicates'.tr(), source.totalDuplicates, Colors.purple),
                if (source.totalMissingImage > 0) _CounterChip('admin.missingImage'.tr(), source.totalMissingImage, AppColors.gray),
                if (source.totalMissingPrice > 0) _CounterChip('admin.missingPrice'.tr(), source.totalMissingPrice, AppColors.gray),
                _CounterChip('admin.batches'.tr(), source.successfulBatches, AppColors.green),
                if (source.failedBatches > 0) _CounterChip('admin.failedBatches'.tr(), source.failedBatches, AppColors.red),
              ],
            ),
            if (source.lastImportAt != null) ...[
              const SizedBox(height: 6),
              Text(
                '${'admin.lastImport'.tr()}: ${source.lastImportAt!.substring(0, 10)}',
                style: const TextStyle(color: AppColors.gray, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── small widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState(this.msg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.gray), textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg, style: const TextStyle(color: AppColors.red, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text('admin.retry'.tr(), style: const TextStyle(color: AppColors.orange))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.green;
      case 'completed_with_warnings':
        color = Colors.amber;
      case 'running':
        color = AppColors.orange;
      case 'failed':
        color = AppColors.red;
      case 'cancelled':
        color = AppColors.gray;
      default:
        color = AppColors.gray;
    }
    return _Chip(status?.toUpperCase() ?? '—', color);
  }
}

class _TrustStatusChip extends StatelessWidget {
  final String status;
  const _TrustStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'trusted':
        color = AppColors.green;
      case 'ok':
        color = Colors.teal;
      case 'watch':
        color = Colors.amber;
      case 'risky':
        color = Colors.orange;
      case 'blocked':
        color = AppColors.red;
      default:
        color = AppColors.gray;
    }
    return _Chip(status.toUpperCase(), color);
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge(this.score);

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? AppColors.green
        : score >= 70
            ? Colors.teal
            : score >= 50
                ? Colors.amber
                : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$score',
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CounterChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
