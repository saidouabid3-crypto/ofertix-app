import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_log_entry_model.dart';
import 'admin_provider.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdminLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingLogs && provider.adminLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.logsError != null && provider.adminLogs.isEmpty) {
      return _ErrorRetry(msg: provider.logsError!, onRetry: provider.loadAdminLogs);
    }

    if (provider.adminLogs.isEmpty) {
      return _EmptyState('admin.noData'.tr());
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadAdminLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.adminLogs.length,
        itemBuilder: (context, i) => _LogCard(log: provider.adminLogs[i]),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final AdminLogEntryModel log;

  @override
  Widget build(BuildContext context) {
    final actionColors = <String, Color>{
      'reel_approved': AppColors.green,
      'reel_rejected': AppColors.red,
      'reel_hidden': AppColors.gray,
      'marketplace_approved': AppColors.green,
      'marketplace_rejected': AppColors.red,
      'marketplace_hidden': AppColors.gray,
      'report_resolved': AppColors.green,
      'report_dismissed': AppColors.gray,
      'user_ban': AppColors.red,
      'user_unban': AppColors.green,
      'user_verify': AppColors.orange,
      'seller_verify': Colors.blue,
      'product_hide': AppColors.gray,
      'product_restore': AppColors.green,
    };
    final actionIcons = <String, IconData>{
      'reel_approved': Icons.check_circle_rounded,
      'reel_rejected': Icons.cancel_rounded,
      'reel_hidden': Icons.visibility_off_rounded,
      'marketplace_approved': Icons.check_circle_rounded,
      'marketplace_rejected': Icons.cancel_rounded,
      'marketplace_hidden': Icons.visibility_off_rounded,
      'report_resolved': Icons.task_alt_rounded,
      'report_dismissed': Icons.do_not_disturb_rounded,
      'user_ban': Icons.block_rounded,
      'user_unban': Icons.check_circle_rounded,
      'user_verify': Icons.verified_rounded,
      'seller_verify': Icons.store_rounded,
      'product_hide': Icons.visibility_off_rounded,
      'product_restore': Icons.restore_rounded,
    };
    final color = actionColors[log.action] ?? AppColors.orange;
    final icon = actionIcons[log.action] ?? Icons.history_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      log.action.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      log.targetType.isNotEmpty ? '· ${log.targetType}' : '',
                      style: const TextStyle(color: AppColors.gray, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  log.adminEmail.isNotEmpty ? log.adminEmail : log.adminUid,
                  style: const TextStyle(color: AppColors.gray, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((log.beforeStatus != null || log.afterStatus != null)) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    if (log.beforeStatus != null) ...[
                      _StatusPill(log.beforeStatus!, AppColors.gray),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.gray, size: 12),
                    ],
                    if (log.afterStatus != null) _StatusPill(log.afterStatus!, color),
                  ]),
                ],
                if (log.reason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(log.reason!, style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (log.createdAt?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(log.createdAt!, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.history_rounded, color: AppColors.gray, size: 48),
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
