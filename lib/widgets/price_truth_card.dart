import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/price_truth_result.dart';

class PriceTruthCard extends StatelessWidget {
  final PriceTruthResult result;

  const PriceTruthCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(result.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.orange, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'priceTruth.title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: result.status, color: color),
            ],
          ),

          const SizedBox(height: 14),

          // Confidence bar
          Row(
            children: [
              Text(
                'priceTruth.confidence'.tr(),
                style: const TextStyle(color: AppColors.gray, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: result.confidence / 100,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.confidence}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Best / average price rows (only when history exists)
          if (result.bestPrice != null || result.averagePrice != null) ...[
            const SizedBox(height: 14),
            if (result.bestPrice != null)
              _PriceRow(
                label: 'priceTruth.bestPrice'.tr(),
                price: result.bestPrice!,
                currency: result.currency,
              ),
            if (result.averagePrice != null) ...[
              const SizedBox(height: 6),
              _PriceRow(
                label: 'priceTruth.averagePrice'.tr(),
                price: result.averagePrice!,
                currency: result.currency,
              ),
            ],
          ],

          // Discount chip
          if (result.discountPercent != null &&
              result.discountPercent! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '−${result.discountPercent!.round()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          // Honest message
          const SizedBox(height: 12),
          Text(
            _message(),
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _message() {
    if (result.suspiciousReasons.contains('nearAverage')) {
      return 'priceTruth.reason.nearAverage'.tr();
    }
    if (result.suspiciousReasons.contains('oldPriceInflated')) {
      return 'priceTruth.reason.oldPriceInflated'.tr();
    }
    if (result.suspiciousReasons.contains('noHistory') ||
        result.status == PriceTruthStatus.noHistory) {
      return result.historyPoints == 0
          ? 'priceTruth.notEnoughHistory'.tr()
          : 'priceTruth.discountUnverified'.tr();
    }
    if (result.status == PriceTruthStatus.realDeal) {
      return 'priceTruth.reason.nearLowest'.tr();
    }
    if (result.discountPercent != null && result.discountPercent! > 0) {
      return 'priceTruth.discountUnverified'.tr();
    }
    return 'priceTruth.reason.noDiscount'.tr();
  }

  static Color _statusColor(PriceTruthStatus s) {
    switch (s) {
      case PriceTruthStatus.realDeal:
        return AppColors.green;
      case PriceTruthStatus.suspicious:
        return AppColors.red;
      case PriceTruthStatus.normal:
        return AppColors.orange;
      case PriceTruthStatus.noHistory:
      case PriceTruthStatus.unknown:
        return AppColors.gray;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final PriceTruthStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  String get _key {
    switch (status) {
      case PriceTruthStatus.realDeal:
        return 'priceTruth.realDeal';
      case PriceTruthStatus.suspicious:
        return 'priceTruth.suspicious';
      case PriceTruthStatus.normal:
        return 'priceTruth.normal';
      case PriceTruthStatus.noHistory:
        return 'priceTruth.noHistory';
      case PriceTruthStatus.unknown:
        return 'priceTruth.unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _key.tr(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double price;
  final String currency;

  const _PriceRow({
    required this.label,
    required this.price,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.gray, fontSize: 13),
        ),
        Text(
          '${price.toStringAsFixed(2)} $currency',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
