import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_report_model.dart';
import 'admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingReports && provider.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.reportsError != null && provider.reports.isEmpty) {
      return _ErrorRetry(msg: provider.reportsError!, onRetry: provider.loadReports);
    }

    if (provider.reports.isEmpty) {
      return _EmptyState('admin.noData'.tr());
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.reports.length,
        itemBuilder: (context, i) => _ReportCard(
          report: provider.reports[i],
          onAction: (action, note) async {
            final ok = await provider.actOnReport(provider.reports[i].id, action, note: note);
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onAction});

  final AdminReportModel report;
  final void Function(String action, String? note) onAction;

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      'reel_report': Colors.purple,
      'marketplace_report': AppColors.orange,
      'product_report': Colors.blue,
    };
    final typeColor = typeColors[report.reportType] ?? AppColors.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(report.reportType.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              _StatusChip(report.status),
            ],
          ),
          const SizedBox(height: 12),
          if (report.targetTitle?.isNotEmpty == true) ...[
            Text(
              report.targetTitle!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          Row(children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.gray, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                report.reporterName ?? report.reporterId ?? '—',
                style: const TextStyle(color: AppColors.gray, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          if (report.reason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(report.reason!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
          if (report.adminNote?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.sticky_note_2_rounded, color: AppColors.orange, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(report.adminNote!, style: const TextStyle(color: AppColors.orange, fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
          if (report.status == 'open') ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Btn(label: 'admin.resolve'.tr(), color: AppColors.green, icon: Icons.check_circle_rounded,
                  onTap: () => onAction('resolve', null)),
              _Btn(label: 'admin.dismiss'.tr(), color: AppColors.gray, icon: Icons.cancel_rounded,
                  onTap: () => onAction('dismiss', null)),
              _Btn(label: 'admin.note'.tr(), color: AppColors.orange, icon: Icons.edit_note_rounded,
                  onTap: () => _promptNote(context)),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _promptNote(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.note'.tr(), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin.note'.tr(),
            hintStyle: const TextStyle(color: AppColors.gray),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
          ),
          maxLines: 3,
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
    if (confirmed == true && context.mounted && ctrl.text.trim().isNotEmpty) {
      onAction('note', ctrl.text.trim());
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = {'open': AppColors.red, 'reviewed': Colors.amber, 'resolved': AppColors.green, 'dismissed': AppColors.gray};
    final c = colors[status] ?? AppColors.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text('admin.$status'.tr(), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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
          const Icon(Icons.inbox_rounded, color: AppColors.gray, size: 48),
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
