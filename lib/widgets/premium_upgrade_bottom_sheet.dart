import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/theme/app_theme.dart';

class PremiumUpgradeBottomSheet extends StatelessWidget {
  final String message;
  final int? dailyLimit;
  final int? used;
  final String? resetsAt;

  const PremiumUpgradeBottomSheet({
    super.key,
    required this.message,
    this.dailyLimit,
    this.used,
    this.resetsAt,
  });

  static Future<void> show(
    BuildContext context, {
    String? message,
    int? dailyLimit,
    int? used,
    String? resetsAt,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumUpgradeBottomSheet(
        message: message ??
            'You have used your free AI searches for today. Upgrade to Ofertix Premium.',
        dailyLimit: dailyLimit,
        used: used,
        resetsAt: resetsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Ofertix Premium',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          if (dailyLimit != null) ...[
            const SizedBox(height: 12),
            Text(
              '${used ?? dailyLimit} / $dailyLimit AI queries today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (resetsAt != null && resetsAt!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Resets: $resetsAt',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('profile.upgradePremium'.tr()),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.maybeLater'.tr()),
          ),
        ],
      ),
    );
  }
}
