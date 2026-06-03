import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/coupon_model.dart';

class CouponTicketCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback? onWorks;
  final VoidCallback? onFails;
  final VoidCallback? onCopy;

  const CouponTicketCard({
    super.key,
    required this.coupon,
    this.onWorks,
    this.onFails,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.white : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  coupon.store,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${coupon.trustScore}% trust',
                style: TextStyle(color: muted, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            coupon.title,
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (coupon.discountLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              coupon.discountLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onFails,
                  child: Text('auto_sweep.widgets_coupon_ticket_card.no_funciona'.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onWorks,
                  child: Text('auto_sweep.widgets_coupon_ticket_card.funciona'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
