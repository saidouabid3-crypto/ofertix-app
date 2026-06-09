import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'admin_provider.dart';

class AdminPublicCatalogScreen extends StatefulWidget {
  const AdminPublicCatalogScreen({super.key});

  @override
  State<AdminPublicCatalogScreen> createState() =>
      _AdminPublicCatalogScreenState();
}

class _AdminPublicCatalogScreenState extends State<AdminPublicCatalogScreen> {
  static const _dangerousKeys = {
    'publicFilteringEnabled',
    'strictMode',
    'hideNeedsReview',
    'hideMissingPrice',
    'hideMissingLink',
    'hideMissingImage',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadCatalogPreview();
      provider.loadCatalogHealth();
    });
  }

  Future<void> _refreshAll(AdminProvider provider) async {
    await Future.wait([
      provider.loadCatalogPreview(),
      provider.loadCatalogHealth(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final preview = provider.catalogPreview;
    final config = preview?.config;

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => _refreshAll(provider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('admin.publicCatalog.title'.tr()),
          Text(
            'admin.publicCatalog.subtitle'.tr(),
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: 'admin.publicCatalog.refreshPreview'.tr(),
            icon: Icons.refresh_rounded,
            loading: provider.isLoadingCatalogPreview,
            onTap: provider.loadCatalogPreview,
          ),
          const SizedBox(height: 16),
          _CatalogHealthCard(
            provider: provider,
            onApply: () => _confirmSourceTrustApply(provider),
          ),
          const SizedBox(height: 20),
          if (provider.isLoadingCatalogPreview && preview == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            )
          else if (provider.catalogPreviewError != null && preview == null)
            _ErrorBox(msg: provider.catalogPreviewError!)
          else if (preview != null && config != null) ...[
            _SectionTitle('admin.publicCatalog.publicFiltering'.tr()),
            _ConfigToggle(
              label: 'admin.publicCatalog.publicFiltering'.tr(),
              value: config.publicFilteringEnabled,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'publicFilteringEnabled',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.smartRanking'.tr(),
              value: config.smartRankingEnabled,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'smartRankingEnabled',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.strictMode'.tr(),
              value: config.strictMode,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) =>
                  _updateToggle(provider, key: 'strictMode', value: value),
            ),
            if (!config.publicFilteringEnabled) ...[
              const SizedBox(height: 4),
              _NoticeBox(
                message: 'admin.publicCatalog.filteringOffNotice'.tr(),
                icon: Icons.info_outline_rounded,
                color: AppColors.orange,
              ),
            ],
            const SizedBox(height: 20),
            _SectionTitle('admin.publicCatalog.visibilityRules'.tr()),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideHiddenDuplicates'.tr(),
              value: config.hideHiddenDuplicates,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'hideHiddenDuplicates',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideRejected'.tr(),
              value: config.hideRejected,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) =>
                  _updateToggle(provider, key: 'hideRejected', value: value),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideQuarantined'.tr(),
              value: config.hideQuarantined,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) =>
                  _updateToggle(provider, key: 'hideQuarantined', value: value),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hidePublicInvisible'.tr(),
              value: config.hideExplicitPublicInvisible,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'hideExplicitPublicInvisible',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideMissingLink'.tr(),
              value: config.hideMissingLink,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) =>
                  _updateToggle(provider, key: 'hideMissingLink', value: value),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideMissingImage'.tr(),
              value: config.hideMissingImage,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'hideMissingImage',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideMissingPrice'.tr(),
              value: config.hideMissingPrice,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'hideMissingPrice',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.hideNeedsReview'.tr(),
              value: config.hideNeedsReview,
              dangerous: true,
              enabled: config.strictMode,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) =>
                  _updateToggle(provider, key: 'hideNeedsReview', value: value),
            ),
            if (!config.strictMode) ...[
              const SizedBox(height: 4),
              _NoticeBox(
                message: 'admin.publicCatalog.strictNeededForNeedsReview'.tr(),
                icon: Icons.lock_outline_rounded,
                color: AppColors.gray,
              ),
            ],
            const SizedBox(height: 20),
            _SectionTitle('admin.publicCatalog.demoteRules'.tr()),
            _ConfigToggle(
              label: 'admin.publicCatalog.demoteNeedsReview'.tr(),
              value: config.demoteNeedsReview,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'demoteNeedsReview',
                value: value,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.demoteLimitedInfo'.tr(),
              value: config.demoteLimitedInfo,
              loading: provider.isCatalogConfigActing,
              onToggle: (value) => _updateToggle(
                provider,
                key: 'demoteLimitedInfo',
                value: value,
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('admin.publicCatalog.previewOnly'.tr()),
            _MetricRow(
              label: 'admin.publicCatalog.visibleProducts'.tr(),
              value: preview.visibleCount,
              color: AppColors.green,
              icon: Icons.visibility_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.hiddenIfEnabled'.tr(),
              value: preview.hiddenCount,
              color: AppColors.redOrange,
              icon: Icons.visibility_off_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.trustedProducts'.tr(),
              value: preview.trustedCount,
              color: AppColors.green,
              icon: Icons.verified_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.needsReview'.tr(),
              value: preview.needsReviewCount,
              color: AppColors.orange,
              icon: Icons.pending_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.priceReview'.tr(),
              value: preview.priceReviewCount,
              color: AppColors.orange,
              icon: Icons.warning_amber_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.missingPrice'.tr(),
              value: preview.missingPriceCount,
              color: AppColors.gray,
              icon: Icons.money_off_csred_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.missingLink'.tr(),
              value: preview.missingLinkCount,
              color: AppColors.gray,
              icon: Icons.link_off_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.missingImage'.tr(),
              value: preview.missingImageCount,
              color: AppColors.gray,
              icon: Icons.image_not_supported_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.hiddenDuplicates'.tr(),
              value: preview.hiddenDuplicateCount,
              color: AppColors.gray,
              icon: Icons.content_copy_rounded,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.quarantined'.tr(),
              value: preview.quarantinedCount,
              color: AppColors.orange,
              icon: Icons.shield_outlined,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.rejected'.tr(),
              value: preview.rejectedCount,
              color: AppColors.redOrange,
              icon: Icons.cancel_outlined,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.publicInvisible'.tr(),
              value: preview.publicInvisibleCount,
              color: AppColors.gray,
              icon: Icons.visibility_off_outlined,
            ),
            _MetricRow(
              label: 'admin.publicCatalog.strictHiddenNeedsReview'.tr(),
              value: preview.strictHiddenNeedsReviewCount,
              color: AppColors.redOrange,
              icon: Icons.gpp_bad_outlined,
            ),
            if (preview.hiddenByReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionTitle('admin.publicCatalog.reasonBreakdown'.tr()),
              ...preview.hiddenByReason.entries.map(
                (entry) => _MetricRow(
                  label: _reasonLabel(entry.key),
                  value: entry.value,
                  color: AppColors.redOrange,
                  icon: Icons.block_rounded,
                ),
              ),
            ],
            if (preview.visibleSamples.isNotEmpty ||
                preview.hiddenSamples.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionTitle('admin.publicCatalog.previewSamples'.tr()),
              if (preview.visibleSamples.isNotEmpty) ...[
                _SampleHeading(
                  label: 'admin.publicCatalog.visibleSamples'.tr(),
                  color: AppColors.green,
                ),
                ...preview.visibleSamples.map(
                  (sample) => _SampleCard(
                    sample: sample,
                    visible: true,
                    reasonLabel: _reasonLabel,
                  ),
                ),
              ],
              if (preview.hiddenSamples.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SampleHeading(
                  label: 'admin.publicCatalog.hiddenSamples'.tr(),
                  color: AppColors.redOrange,
                ),
                ...preview.hiddenSamples.map(
                  (sample) => _SampleCard(
                    sample: sample,
                    visible: false,
                    reasonLabel: _reasonLabel,
                  ),
                ),
              ],
            ],
            if (provider.catalogConfigError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ErrorBox(msg: provider.catalogConfigError!),
              ),
            const SizedBox(height: 20),
            if (preview.generatedAt != null)
              Text(
                '${'admin.publicCatalog.generatedAt'.tr()}: '
                '${preview.generatedAt}',
                style: const TextStyle(color: AppColors.gray, fontSize: 10),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _updateToggle(
    AdminProvider provider, {
    required String key,
    required bool value,
  }) async {
    if (value && _dangerousKeys.contains(key)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            'admin.publicCatalog.dangerousToggleTitle'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'admin.publicCatalog.dangerousToggleMessage'.tr(),
            style: const TextStyle(color: AppColors.gray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(color: AppColors.gray),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'admin.confirmAction'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await provider.updateCatalogConfig({key: value});
  }

  Future<void> _confirmSourceTrustApply(AdminProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'admin.catalogHealth.applyTitle'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'admin.catalogHealth.applyMessage'.tr(),
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: AppColors.gray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'admin.catalogHealth.apply'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.recalibrateSourceTrust(dryRun: false);
    }
  }

  String _reasonLabel(String reason) {
    const keys = {
      'missing_link': 'admin.publicCatalog.reasonMissingLink',
      'missing_image': 'admin.publicCatalog.reasonMissingImage',
      'missing_price': 'admin.publicCatalog.reasonMissingPrice',
      'hidden_duplicate': 'admin.publicCatalog.reasonHiddenDuplicate',
      'quarantined': 'admin.publicCatalog.reasonQuarantined',
      'rejected': 'admin.publicCatalog.reasonRejected',
      'public_invisible': 'admin.publicCatalog.reasonPublicInvisible',
      'explicit_public_invisible': 'admin.publicCatalog.reasonPublicInvisible',
      'needs_review_hidden_strict':
          'admin.publicCatalog.reasonNeedsReviewStrict',
    };
    final key = keys[reason];
    return key == null ? reason : key.tr();
  }
}

class _CatalogHealthCard extends StatelessWidget {
  final AdminProvider provider;
  final VoidCallback onApply;

  const _CatalogHealthCard({required this.provider, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final health = provider.catalogHealth?.summary;
    final actionResult = provider.lastSourceTrustRecalibration;
    final updated = actionResult?['updatedSources'] ?? 0;
    final recalibrated = actionResult?['recalibratedSources'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.catalogHealth.title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'admin.catalogHealth.subtitle'.tr(),
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (provider.isLoadingCatalogHealth && health == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppColors.orange,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (provider.catalogHealthError != null && health == null)
            _ErrorBox(msg: provider.catalogHealthError!)
          else if (health != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HealthMetric(
                  label: 'admin.catalogHealth.totalProducts'.tr(),
                  value: '${health.totalProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.trusted'.tr(),
                  value: '${health.trustedProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.needsReview'.tr(),
                  value: '${health.needsReviewProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.missingPrice'.tr(),
                  value: '${health.missingPriceProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.missingImage'.tr(),
                  value: '${health.missingImageProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.missingLink'.tr(),
                  value: '${health.missingLinkProducts}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.weakSources'.tr(),
                  value: '${health.weakSourcesCount}',
                ),
                _HealthMetric(
                  label: 'admin.catalogHealth.averageTrust'.tr(),
                  value: health.averageTrustScore.toStringAsFixed(1),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: provider.isLoadingCatalogHealth
                    ? null
                    : provider.loadCatalogHealth,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('admin.catalogHealth.refresh'.tr()),
              ),
              OutlinedButton.icon(
                onPressed: provider.isRecalibratingSourceTrust
                    ? null
                    : () => provider.recalibrateSourceTrust(dryRun: true),
                icon: const Icon(Icons.science_outlined, size: 16),
                label: Text('admin.catalogHealth.dryRun'.tr()),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: provider.isRecalibratingSourceTrust ? null : onApply,
                icon: provider.isRecalibratingSourceTrust
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.tune_rounded, size: 16),
                label: Text('admin.catalogHealth.apply'.tr()),
              ),
            ],
          ),
          if (actionResult != null) ...[
            const SizedBox(height: 10),
            Text(
              actionResult['dryRun'] == true
                  ? '${'admin.catalogHealth.dryRunComplete'.tr()}: '
                        '$recalibrated'
                  : '${'admin.catalogHealth.updated'.tr()}: $updated',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (provider.sourceTrustRecalibrationError != null) ...[
            const SizedBox(height: 10),
            _ErrorBox(msg: provider.sourceTrustRecalibrationError!),
          ],
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HealthMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 105, maxWidth: 155),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConfigToggle extends StatelessWidget {
  final String label;
  final bool value;
  final bool dangerous;
  final bool enabled;
  final bool loading;
  final ValueChanged<bool> onToggle;

  const _ConfigToggle({
    required this.label,
    required this.value,
    this.dangerous = false,
    this.enabled = true,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dangerous && value
                ? AppColors.redOrange.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              dangerous ? Icons.warning_amber_rounded : Icons.tune_rounded,
              color: dangerous ? AppColors.orange : AppColors.gray,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.orange,
                ),
              )
            else
              Switch(
                value: value,
                activeThumbColor: dangerous
                    ? AppColors.redOrange
                    : AppColors.green,
                onChanged: interactive ? onToggle : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _NoticeBox({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _SampleHeading extends StatelessWidget {
  final String label;
  final Color color;

  const _SampleHeading({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

class _SampleCard extends StatelessWidget {
  final Map<String, dynamic> sample;
  final bool visible;
  final String Function(String) reasonLabel;

  const _SampleCard({
    required this.sample,
    required this.visible,
    required this.reasonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name = (sample['name']?.toString().trim().isNotEmpty ?? false)
        ? sample['name'].toString()
        : sample['id']?.toString() ?? '-';
    final store = sample['store']?.toString() ?? '';
    final reason = sample['hiddenReason']?.toString() ?? '';
    final rank = sample['publicRankScore'] ?? sample['rankScore'];
    final statuses = <String>{
      if ((sample['trustStatus']?.toString() ?? '').isNotEmpty)
        sample['trustStatus'].toString(),
      if ((sample['admissionStatus']?.toString() ?? '').isNotEmpty)
        sample['admissionStatus'].toString(),
      if ((sample['priceConfidence']?.toString() ?? '').isNotEmpty)
        sample['priceConfidence'].toString(),
      if (sample['qualityFlags'] is List)
        ...(sample['qualityFlags'] as List)
            .take(3)
            .map((flag) => flag.toString()),
    }.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (store.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              store,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.gray, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusChip(
                text: visible
                    ? '${'admin.publicCatalog.rank'.tr()}: ${rank ?? '-'}'
                    : reasonLabel(reason),
                color: visible ? AppColors.green : AppColors.redOrange,
              ),
              ...statuses.map(
                (status) => _StatusChip(text: status, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.orange,
        side: BorderSide(color: AppColors.orange.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            )
          : Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  final String msg;

  const _ErrorBox({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.redOrange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.redOrange.withValues(alpha: 0.3)),
    ),
    child: Text(
      msg,
      style: const TextStyle(color: AppColors.redOrange, fontSize: 12),
    ),
  );
}
