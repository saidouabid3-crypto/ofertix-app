import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.home_outlined,
    Icons.qr_code_scanner_rounded,
    Icons.dynamic_feed_outlined,
    Icons.sell_outlined,
    Icons.auto_awesome_outlined,
  ];

  static const _activeIcons = [
    Icons.home,
    Icons.qr_code_scanner_rounded,
    Icons.dynamic_feed_rounded,
    Icons.sell,
    Icons.auto_awesome_rounded,
  ];

  static const _labelKeys = [
    'common.home',
    'common.scan',
    'common.feed',
    'common.sell',
    'common.ai',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.card.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);
    final border = isDark ? Colors.white10 : const Color(0xFFE6EAEE);
    final inactive = isDark ? AppColors.gray : const Color(0xFF7C848E);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(5, (i) {
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.orange.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          selected ? _activeIcons[i] : _icons[i],
                          color: selected ? AppColors.orange : inactive,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelKeys[i].tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.orange : inactive,
                          fontSize: 9.5,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
