import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/theme/app_theme.dart';
import '../models/ai_deal_brain_result.dart';

/// Passive AI verdict badge for product cards.
///
/// Renders only when a real [AiDealBrainResult] is supplied.
/// Returns [SizedBox.shrink] when result is null — callers do not
/// need to guard against null.
///
/// No AI calls are made here. Connect this to AiService.cardVerdict
/// results cached externally.
class ProductAIBadge extends StatelessWidget {
  final AiDealBrainResult? result;

  const ProductAIBadge({super.key, this.result});

  static const Map<String, String> _verdictKeys = {
    'buy_now': 'ai.badge.buyNow',
    'wait': 'ai.badge.wait',
    'avoid': 'ai.badge.avoid',
    'fake_discount': 'ai.badge.fakeDiscount',
    'hidden_gem': 'ai.badge.hiddenGem',
    'watch_price': 'ai.badge.watchPrice',
    'better_alternative': 'ai.badge.betterAlternative',
  };

  static const Map<String, Color> _verdictColors = {
    'buy_now': AppColors.green,
    'hidden_gem': AppColors.green,
    'wait': AppColors.orange,
    'watch_price': AppColors.orange,
    'better_alternative': AppColors.orange,
    'avoid': Color(0xFFE53E3E),
    'fake_discount': Color(0xFFE53E3E),
  };

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const SizedBox.shrink();

    final key = _verdictKeys[r.verdict] ?? 'ai.badge.watchPrice';
    final color = _verdictColors[r.verdict] ?? AppColors.orange;
    final label = key.tr();
    final score = r.score;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_alt_rounded, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            score > 0 ? '$label · $score' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
