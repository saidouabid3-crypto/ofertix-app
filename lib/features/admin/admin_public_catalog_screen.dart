import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_catalog_model.dart';
import 'admin_provider.dart';

class AdminPublicCatalogScreen extends StatefulWidget {
  const AdminPublicCatalogScreen({super.key});

  @override
  State<AdminPublicCatalogScreen> createState() => _AdminPublicCatalogScreenState();
}

class _AdminPublicCatalogScreenState extends State<AdminPublicCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCatalogPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final CatalogPreviewModel? preview = provider.catalogPreview;
    final config = preview?.config;

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => provider.loadCatalogPreview(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('admin.publicCatalog.title'.tr()),
          Text(
            'admin.publicCatalog.subtitle'.tr(),
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // refresh button
          _ActionButton(
            label: 'admin.publicCatalog.refreshPreview'.tr(),
            icon: Icons.refresh_rounded,
            loading: provider.isLoadingCatalogPreview,
            onTap: () => provider.loadCatalogPreview(),
          ),
          const SizedBox(height: 16),

          if (provider.isLoadingCatalogPreview && preview == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            )
          else if (provider.catalogPreviewError != null && preview == null)
            _ErrorBox(msg: provider.catalogPreviewError!)
          else if (preview != null) ...[

            // ── Config state ──────────────────────────────────────────────
            _SectionTitle('admin.publicCatalog.publicFiltering'.tr()),
            _ConfigToggle(
              label: 'admin.publicCatalog.publicFiltering'.tr(),
              value: config!.publicFilteringEnabled,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (v) => _confirmToggle(
                context,
                provider,
                key: 'publicFilteringEnabled',
                value: v,
                dangerous: v,
              ),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.smartRanking'.tr(),
              value: config.smartRankingEnabled,
              dangerous: false,
              loading: provider.isCatalogConfigActing,
              onToggle: (v) => provider.updateCatalogConfig({'smartRankingEnabled': v}),
            ),
            _ConfigToggle(
              label: 'admin.publicCatalog.strictMode'.tr(),
              value: config.strictMode,
              dangerous: true,
              loading: provider.isCatalogConfigActing,
              onToggle: (v) => _confirmToggle(
                context,
                provider,
                key: 'strictMode',
                value: v,
                dangerous: v,
              ),
            ),

            const SizedBox(height: 20),

            // ── Preview metrics ───────────────────────────────────────────
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
              label: 'admin.publicCatalog.hiddenDuplicates'.tr(),
              value: preview.hiddenDuplicateCount,
              color: AppColors.gray,
              icon: Icons.content_copy_rounded,
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

            if (preview.hiddenByReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionTitle('Hidden by reason'),
              ...preview.hiddenByReason.entries.map(
                (e) => _MetricRow(
                  label: e.key,
                  value: e.value,
                  color: AppColors.redOrange,
                  icon: Icons.block_rounded,
                ),
              ),
            ],

            if (provider.catalogConfigError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ErrorBox(msg: provider.catalogConfigError!),
              ),

            const SizedBox(height: 20),
            if (preview.generatedAt != null)
              Text(
                'Generated: ${preview.generatedAt}',
                style: const TextStyle(color: AppColors.gray, fontSize: 10),
              ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    AdminProvider provider, {
    required String key,
    required bool value,
    required bool dangerous,
  }) async {
    if (!dangerous) {
      await provider.updateCatalogConfig({key: value});
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'admin.publicCatalog.enableFilteringTitle'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'admin.publicCatalog.enableFilteringMessage'.tr(),
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: Text('admin.confirmAction'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.updateCatalogConfig({key: value});
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
  final bool loading;
  final void Function(bool) onToggle;

  const _ConfigToggle({
    required this.label,
    required this.value,
    required this.dangerous,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (dangerous && value)
                ? AppColors.redOrange.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            if (dangerous)
              const Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 16)
            else
              const Icon(Icons.tune_rounded, color: AppColors.gray, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
              )
            else
              Switch(
                value: value,
                activeThumbColor: dangerous ? AppColors.redOrange : AppColors.green,
                onChanged: loading ? null : onToggle,
              ),
          ],
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
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
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
        child: Text(msg, style: const TextStyle(color: AppColors.redOrange, fontSize: 12)),
      );
}
