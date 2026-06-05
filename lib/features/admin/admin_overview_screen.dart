import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'admin_provider.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingOverview && provider.overview == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.overviewError != null && provider.overview == null) {
      return _ErrorState(
        message: provider.overviewError!,
        onRetry: provider.loadOverview,
      );
    }

    final ov = provider.overview;

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadOverview,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionTitle('admin.overview'.tr()),
          const SizedBox(height: 16),
          _buildGrid([
            _MetricCard(label: 'admin.totalUsers'.tr(), value: ov?.totalUsers ?? 0, icon: Icons.people_alt_rounded, color: AppColors.orange),
            _MetricCard(label: 'admin.totalReels'.tr(), value: ov?.totalReels ?? 0, icon: Icons.play_circle_rounded, color: Colors.purple),
            _MetricCard(label: 'admin.pendingReels'.tr(), value: ov?.pendingReels ?? 0, icon: Icons.hourglass_top_rounded, color: Colors.amber, warn: (ov?.pendingReels ?? 0) > 0),
            _MetricCard(label: 'admin.reportedReels'.tr(), value: ov?.reportedReels ?? 0, icon: Icons.flag_rounded, color: AppColors.red, warn: (ov?.reportedReels ?? 0) > 0),
            _MetricCard(label: 'admin.totalSellItems'.tr(), value: ov?.totalSellItems ?? 0, icon: Icons.storefront_rounded, color: AppColors.green),
            _MetricCard(label: 'admin.pendingSellItems'.tr(), value: ov?.pendingSellItems ?? 0, icon: Icons.pending_rounded, color: Colors.amber, warn: (ov?.pendingSellItems ?? 0) > 0),
            _MetricCard(label: 'admin.reportedSellItems'.tr(), value: ov?.reportedSellItems ?? 0, icon: Icons.report_rounded, color: AppColors.red, warn: (ov?.reportedSellItems ?? 0) > 0),
            _MetricCard(label: 'admin.openReports'.tr(), value: ov?.openReports ?? 0, icon: Icons.inbox_rounded, color: AppColors.red, warn: (ov?.openReports ?? 0) > 0),
            _MetricCard(label: 'admin.systemErrors'.tr(), value: ov?.systemErrors ?? 0, icon: Icons.error_outline_rounded, color: AppColors.red, warn: (ov?.systemErrors ?? 0) > 0),
            _MetricCard(label: 'admin.aiErrors'.tr(), value: ov?.aiErrors ?? 0, icon: Icons.psychology_rounded, color: Colors.orange),
          ]),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: cards,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.warn = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: warn ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (warn) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.gray, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.gray, size: 48),
            const SizedBox(height: 16),
            Text('admin.loadError'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('admin.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
