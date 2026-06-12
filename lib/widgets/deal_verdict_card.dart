import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/deal_verdict.dart';

class DealVerdictCard extends StatefulWidget {
  const DealVerdictCard({
    super.key,
    this.verdict,
    this.isLoading = false,
  });

  final DealVerdict? verdict;
  final bool isLoading;

  @override
  State<DealVerdictCard> createState() => _DealVerdictCardState();
}

class _DealVerdictCardState extends State<DealVerdictCard> {
  bool _showAllReasons = false;

  static const int _maxVisible = 3;

  Color _verdictColor(String v) => switch (v) {
    'buy_now' => AppColors.green,
    'avoid' => AppColors.red,
    'wait' => const Color(0xFFF59E0B),
    _ => const Color(0xFF38BDF8),
  };

  IconData _verdictIcon(String v) => switch (v) {
    'buy_now' => Icons.check_circle_rounded,
    'avoid' => Icons.shield_rounded,
    'wait' => Icons.schedule_rounded,
    _ => Icons.storefront_rounded,
  };

  String _verdictLabelKey(String v) => switch (v) {
    'buy_now' => 'dealVerdict.buyNow',
    'avoid' => 'dealVerdict.avoid',
    'wait' => 'dealVerdict.wait',
    _ => 'dealVerdict.checkStore',
  };

  String _riskKey(String r) => switch (r) {
    'low' => 'dealVerdict.lowRisk',
    'high' => 'dealVerdict.highRisk',
    'critical' => 'dealVerdict.criticalRisk',
    _ => 'dealVerdict.mediumRisk',
  };

  Color _riskColor(String r) => switch (r) {
    'low' => AppColors.green,
    'high' => AppColors.red,
    'critical' => const Color(0xFFDC2626),
    _ => AppColors.orange,
  };

  String _reasonText(DealVerdictReason reason) {
    const supported = {
      'trusted_product', 'high_quality', 'confirmed_price',
      'reasonable_discount', 'estimated_price', 'final_price_in_store',
      'very_high_discount', 'discount_price_mismatch', 'missing_price',
      'missing_link', 'duplicate_candidate', 'single_image_only',
      'unknown_category', 'shipping_uncertain', 'price_check_missing',
      'price_check_old', 'price_history_unavailable',
    };
    if (supported.contains(reason.code)) {
      return 'dealVerdict.reason.${reason.code}'.tr();
    }
    return reason.message;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildSkeleton();
    final verdict = widget.verdict;
    if (verdict == null) return const SizedBox.shrink();
    return _buildCard(verdict);
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'dealVerdict.loading'.tr(),
            style: const TextStyle(color: AppColors.gray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(DealVerdict verdict) {
    final color = _verdictColor(verdict.verdict);
    final riskColor = _riskColor(verdict.riskLevel);
    final allReasons = verdict.reasons;
    final hasMore = allReasons.length > _maxVisible;
    final visibleReasons = _showAllReasons
        ? allReasons
        : allReasons.take(_maxVisible).toList();
    final summary = verdict.summary.isNotEmpty ? verdict.summary : null;

    // Prefer backend action hints; fall back to localized hint for check_store
    final actionHint = verdict.actionHints.isNotEmpty
        ? verdict.actionHints.first
        : (verdict.verdict == 'check_store'
            ? 'dealVerdict.openStoreHint'.tr()
            : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Icon(_verdictIcon(verdict.verdict), color: color, size: 21),
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
              _pill(
                '${'dealVerdict.confidence'.tr()} ${verdict.confidence}%',
                color,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Verdict + Risk chips ──────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(_verdictLabelKey(verdict.verdict).tr(), color),
              _pill(_riskKey(verdict.riskLevel).tr(), riskColor),
            ],
          ),

          // ── Summary (from backend, not static key) ────────────────
          if (summary != null) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],

          // ── Reasons ──────────────────────────────────────────────
          if (allReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'dealVerdict.reasons'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final reason in visibleReasons)
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
            if (hasMore)
              GestureDetector(
                onTap: () =>
                    setState(() => _showAllReasons = !_showAllReasons),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _showAllReasons
                        ? 'dealVerdict.showLess'.tr()
                        : 'dealVerdict.showMore'.tr(),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],

          // ── Warnings strip ────────────────────────────────────────
          if (verdict.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < verdict.warnings.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < verdict.warnings.length - 1 ? 6 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.orange,
                            size: 15,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              verdict.warnings[i],
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
              ),
            ),
          ] else if (verdict.signals['finalPriceInStore'] == true) ...[
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
                    size: 15,
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

          // ── Action hint ───────────────────────────────────────────
          if (actionHint != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.7),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    actionHint,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
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
