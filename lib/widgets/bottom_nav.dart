import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navColor = isDark ? const Color(0xFF121212) : Colors.white;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: navColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(context, Icons.home_rounded, "Home", 0, inactiveColor),
            navItem(
              context,
              Icons.local_fire_department_rounded,
              "Deals",
              1,
              inactiveColor,
            ),
            navItem(
              context,
              Icons.qr_code_scanner_rounded,
              "Scan",
              2,
              inactiveColor,
            ),
            navItem(
              context,
              Icons.favorite_rounded,
              "Watchlist",
              3,
              inactiveColor,
            ),
            navItem(context, Icons.person_rounded, "Profile", 4, inactiveColor),
          ],
        ),
      ),
    );
  }

  Widget navItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    Color inactiveColor,
  ) {
    final active = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppColors.orange : inactiveColor,
              size: 25,
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.orange : inactiveColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
