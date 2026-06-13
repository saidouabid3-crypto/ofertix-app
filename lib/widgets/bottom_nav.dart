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
    final outerBg = isDark ? AppColors.background : Colors.white;
    final pillBg = isDark ? AppColors.card2 : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.10);

    return ColoredBox(
      color: outerBg,
      child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
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
                              ? AppColors.orange.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          selected ? _activeIcons[i] : _icons[i],
                          color: selected
                              ? AppColors.orange
                              : isDark ? AppColors.gray : const Color(0xFF7C848E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelKeys[i].tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.orange
                              : isDark ? AppColors.gray : const Color(0xFF7C848E),
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
    ),
    );
  }
}
