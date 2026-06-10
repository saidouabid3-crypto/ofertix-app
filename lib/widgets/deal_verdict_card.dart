import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/deal_verdict.dart';

class DealVerdictCard extends StatelessWidget {
  const DealVerdictCard({super.key, required this.verdict});

  final DealVerdict verdict;

  Color get _color => switch (verdict.verdict) {
    'buy_now' => AppColors.green,
    'avoid' => AppColors.red,
    'wait' => AppColors.orange,
    _ => const Color(0xFF38BDF8),
  };

  IconData get _icon => switch (verdict.verdict) {
    'buy_now' => Icons.thumb_up_alt_rounded,
    'avoid' => Icons.report_gmailerrorred_rounded,
    'wait' => Icons.schedule_rounded,
    _ => Icons.storefront_rounded,
  };

  String get _verdictKey => switch (verdict.verdict) {
    'buy_now' => 'dealVerdict.buyNow',
    'avoid' => 'dealVerdict.avoid',
    'wait' => 'dealVerdict.wait',
    _ => 'dealVerdict.checkStore',
  };

  String get _riskKey => switch (verdict.riskLevel) {
    'low' => 'dealVerdict.lowRisk',
    'high' => 'dealVerdict.highRisk',
    'critical' => 'dealVerdict.criticalRisk',
    _ => 'dealVerdict.mediumRisk',
  };

  String get _summaryKey => switch (verdict.verdict) {
    'buy_now' => 'dealVerdict.summaryBuyNow',
    'avoid' => 'dealVerdict.summaryAvoid',
    'wait' => 'dealVerdict.summaryWait',
    _ => 'dealVerdict.summaryCheckStore',
  };

  String _reasonText(DealVerdictReason reason) {
    const supported = {
      'trusted_product',
      'high_quality',
      'confirmed_price',
      'reasonable_discount',
      'estimated_price',
      'final_price_in_store',
      'very_high_discount',
      'discount_price_mismatch',
      'missing_price',
      'missing_link',
      'duplicate_candidate',
      'single_image_only',
      'unknown_category',
      'shipping_uncertain',
      'price_check_missing',
      'price_check_old',
      'price_history_unavailable',
    };
    if (supported.contains(reason.code)) {
      return 'dealVerdict.reason.${reason.code}'.tr();
    }
    return reason.message;
  }

  @override
  Widget build(BuildContext context) {
    final topReasons = verdict.reasons.take(3).toList();
    final mustConfirm =
        verdict.signals['finalPriceInStore'] == true ||
        verdict.warnings.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'dealVerdict.title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _pill('${verdict.confidence}%', _color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(_verdictKey.tr(), _color),
              _pill(_riskKey.tr(), AppColors.gray),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _summaryKey.tr(),
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (topReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'dealVerdict.why'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final reason in topReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      reason.type == 'positive'
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: reason.type == 'positive'
                          ? AppColors.green
                          : AppColors.orange,
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _reasonText(reason),
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (mustConfirm) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    color: AppColors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'dealVerdict.finalPriceWarning'.tr(),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
