import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'admin_import_intelligence_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_moderation_marketplace_screen.dart';
import 'admin_moderation_reels_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_product_duplicates_screen.dart';
import 'admin_product_quality_screen.dart';
import 'admin_provider.dart';
import 'admin_reports_screen.dart';
import 'admin_system_health_screen.dart';
import 'admin_users_screen.dart';

class AdminCommandCenterScreen extends StatelessWidget {
  const AdminCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..checkAdminAccess(),
      child: const _AdminBody(),
    );
  }
}

class _AdminBody extends StatefulWidget {
  const _AdminBody();

  @override
  State<_AdminBody> createState() => _AdminBodyState();
}

class _AdminBodyState extends State<_AdminBody> {
  int _index = 0;

  static const _labels = [
    'admin.overview',
    'admin.reels',
    'admin.sellItems',
    'admin.reports',
    'admin.users',
    'admin.productQuality',
    'admin.duplicateReview',
    'admin.imports',
    'admin.systemHealth',
    'admin.logs',
  ];

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.play_circle_rounded,
    Icons.storefront_rounded,
    Icons.flag_rounded,
    Icons.people_alt_rounded,
    Icons.star_rate_rounded,
    Icons.content_copy_rounded,
    Icons.inventory_2_rounded,
    Icons.monitor_heart_rounded,
    Icons.history_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isCheckingAccess) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    if (!provider.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('admin.title'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.orange, size: 64),
                const SizedBox(height: 20),
                Text(
                  'admin.accessDenied'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'admin.noPermission'.tr(),
                  style: const TextStyle(color: AppColors.gray),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = [
      const AdminOverviewScreen(),
      const AdminModerationReelsScreen(),
      const AdminModerationMarketplaceScreen(),
      const AdminReportsScreen(),
      const AdminUsersScreen(),
      const AdminProductQualityScreen(),
      const AdminProductDuplicatesScreen(),
      const AdminImportIntelligenceScreen(),
      const AdminSystemHealthScreen(),
      const AdminLogsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'admin.title'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text('LIVE', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
      body: Row(
        children: [
          // Side nav
          Container(
            width: 64,
            color: AppColors.card,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _labels.length,
              itemBuilder: (context, i) {
                final selected = _index == i;
                return Tooltip(
                  message: _labels[i].tr(),
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.orange.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(color: AppColors.orange.withValues(alpha: 0.4), width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        _icons[i],
                        color: selected ? AppColors.orange : AppColors.gray,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content
          Expanded(
            child: ChangeNotifierProvider.value(
              value: provider,
              child: IndexedStack(
                index: _index,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
