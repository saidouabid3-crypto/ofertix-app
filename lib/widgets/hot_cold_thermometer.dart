import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class HotColdThermometer extends StatelessWidget {
  final int hotScore;
  final int hotVotes;
  final int coldVotes;
  final VoidCallback? onHot;
  final VoidCallback? onCold;
  final String? userVote;

  const HotColdThermometer({
    super.key,
    required this.hotScore,
    required this.hotVotes,
    required this.coldVotes,
    this.onHot,
    this.onCold,
    this.userVote,
  });

  @override
  Widget build(BuildContext context) {
    final score = hotScore.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('auto_sweep.widgets_hot_cold_thermometer.cold'.tr(),
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$score° 🔥',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 9,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  text: 'Cold $coldVotes',
                  selected: userVote == 'cold',
                  onTap: onCold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VoteButton(
                  text: 'Hot $hotVotes',
                  selected: userVote == 'hot',
                  onTap: onHot,
                  hot: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String text;
  final bool selected;
  final bool hot;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.text,
    required this.selected,
    required this.onTap,
    this.hot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = hot ? AppColors.primary : Colors.lightBlueAccent;

    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? color
              : Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
