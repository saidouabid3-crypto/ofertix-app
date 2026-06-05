import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'admin_provider.dart';

class AdminSystemHealthScreen extends StatefulWidget {
  const AdminSystemHealthScreen({super.key});

  @override
  State<AdminSystemHealthScreen> createState() => _AdminSystemHealthScreenState();
}

class _AdminSystemHealthScreenState extends State<AdminSystemHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSystemHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingHealth && provider.systemHealth == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.healthError != null && provider.systemHealth == null) {
      return _ErrorRetry(msg: provider.healthError!, onRetry: provider.loadSystemHealth);
    }

    final health = provider.systemHealth;

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadSystemHealth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('admin.systemHealth'.tr()),
          const SizedBox(height: 16),
          _Section(
            title: 'System Errors',
            icon: Icons.error_outline_rounded,
            color: AppColors.red,
            isEmpty: health?.systemErrors.isEmpty != false,
            children: health?.systemErrors.map((e) => _LogTile(
              title: e.path ?? 'Unknown path',
              subtitle: e.message ?? '',
              ts: e.createdAt,
              color: AppColors.red,
            )).toList() ?? [],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Import Logs',
            icon: Icons.sync_rounded,
            color: Colors.blue,
            isEmpty: health?.importLogs.isEmpty != false,
            children: health?.importLogs.map((e) => _LogTile(
              title: e.source ?? 'Unknown source',
              subtitle: '${e.itemsImported} imported · ${e.errors} errors · ${e.status ?? ''}',
              ts: e.createdAt,
              color: e.errors > 0 ? AppColors.red : AppColors.green,
            )).toList() ?? [],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'AI Usage / Errors',
            icon: Icons.psychology_rounded,
            color: Colors.purple,
            isEmpty: health?.aiErrors.isEmpty != false,
            children: health?.aiErrors.map((e) => _LogTile(
              title: e.subject ?? 'AI query',
              subtitle: e.uid != null ? 'uid: ${e.uid}' : '',
              ts: e.createdAt,
              color: e.blocked ? AppColors.red : AppColors.gray,
            )).toList() ?? [],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Failed Scrapings',
            icon: Icons.link_off_rounded,
            color: Colors.amber,
            isEmpty: health?.failedScrapings.isEmpty != false,
            children: health?.failedScrapings.map((e) => _LogTile(
              title: e.source ?? e.url ?? 'Unknown',
              subtitle: e.error ?? '',
              ts: e.createdAt,
              color: Colors.amber,
            )).toList() ?? [],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.isEmpty,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('${children.length}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('admin.noData'.tr(), style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          )
        else
          ...children,
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.title, required this.subtitle, this.ts, required this.color});

  final String title;
  final String subtitle;
  final String? ts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.gray, fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (ts != null) ...[
            const SizedBox(height: 4),
            Text(ts!, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
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
