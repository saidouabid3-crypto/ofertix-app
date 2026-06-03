import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.10),
            surfaceTintColor: Colors.white,
            indicatorColor: AppColors.orange.withValues(alpha: 0.14),
            selectedIndex: currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: onTap,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: AppColors.orange),
                label: 'common.home'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                selectedIcon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.orange,
                ),
                label: 'common.scan'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.dynamic_feed_outlined),
                selectedIcon: const Icon(
                  Icons.dynamic_feed_rounded,
                  color: AppColors.orange,
                ),
                label: 'common.feed'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.sell_outlined),
                selectedIcon: const Icon(Icons.sell, color: AppColors.orange),
                label: 'common.sell'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.orange,
                ),
                label: 'common.ai'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
