import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/global_deal_model.dart';

class DiscountTruthCard extends StatelessWidget {
  final DiscountCurrencyCardData data;
  const DiscountTruthCard({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final risk = data.fakeDiscountRisk.clamp(0, 100);
    final riskColor = risk >= 70
        ? const Color(0xFFDC2626)
        : risk >= 35
        ? const Color(0xFFF59E0B)
        : const Color(0xFF16A34A);
    return _Shell(
      icon: Icons.currency_exchange_rounded,
      title: 'Discount & Currency Truth',
      subtitle: 'Real final price in your currency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Store price',
                  value: data.storePrice.format(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Your currency',
                  value: data.convertedProductPrice.format(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Shipping',
                  value: data.estimatedShipping.format(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Taxes',
                  value: data.estimatedTaxes.format(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Metric(
            label: 'Total landed cost',
            value: data.totalLandedCost.format(),
            large: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('auto_sweep.screens_widgets_discount_truth_card.fake_discount_risk'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$risk%',
                style: TextStyle(color: riskColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: risk / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            color: riskColor,
            backgroundColor: riskColor.withValues(alpha: .12),
          ),
          const SizedBox(height: 12),
          Text(
            data.explanation,
            style: TextStyle(
              color: Colors.black.withValues(alpha: .64),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final bool large;
  const _Metric({required this.label, required this.value, this.large = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(large ? 16 : 13),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: large ? 22 : 16,
          ),
        ),
      ],
    ),
  );
}

class _Shell extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget child;
  const _Shell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE6EDF2)),
      boxShadow: [
        BoxShadow(
          blurRadius: 24,
          offset: const Offset(0, 12),
          color: Colors.black.withValues(alpha: .05),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFF8A00).withValues(alpha: .12),
              child: Icon(icon, color: const Color(0xFFFF8A00)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
