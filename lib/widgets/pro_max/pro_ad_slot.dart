import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ad_revenue_service.dart';

class ProAdSlot extends StatefulWidget {
  final String slot;
  final String title;
  final String subtitle;
  final double height;
  final VoidCallback? onTap;

  const ProAdSlot({
    super.key,
    required this.slot,
    this.title = 'Sponsored space',
    this.subtitle = 'Ready for Google Ads / AdMob',
    this.height = 86,
    this.onTap,
  });

  @override
  State<ProAdSlot> createState() => _ProAdSlotState();
}

class _ProAdSlotState extends State<ProAdSlot> {
  bool _tracked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tracked) return;
    _tracked = true;
    AdRevenueService.instance.trackImpression(widget.slot);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.white : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return GestureDetector(
      onTap: () {
        AdRevenueService.instance.trackClick(widget.slot);
        widget.onTap?.call();
      },
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.card.withValues(alpha: .72)
              : AppColors.lightCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.ads_click_rounded,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
