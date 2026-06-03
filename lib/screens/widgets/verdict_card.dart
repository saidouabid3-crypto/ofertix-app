import 'package:flutter/material.dart';
import '../../models/global_deal_model.dart';

class VerdictCard extends StatelessWidget {
  final VerdictCardData data;
  const VerdictCard({super.key, required this.data});
  Color get color => data.color == 'GREEN'
      ? const Color(0xFF16A34A)
      : data.color == 'RED'
      ? const Color(0xFFDC2626)
      : const Color(0xFFF59E0B);
  IconData get icon => data.command == 'BUY_NOW'
      ? Icons.shopping_bag_rounded
      : data.command == 'AVOID'
      ? Icons.block_rounded
      : data.command == 'WAIT'
      ? Icons.schedule_rounded
      : Icons.verified_user_rounded;
  @override
  Widget build(BuildContext context) {
    final score = data.score.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .14), Colors.white],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: .16),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              Chip(label: Text('$score/100'), side: BorderSide.none),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
          const SizedBox(height: 16),
          Text(
            data.oneLine,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            data.explanation,
            style: TextStyle(
              color: Colors.black.withValues(alpha: .64),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(data.command.replaceAll('_', ' ')),
              _pill('Risk ${data.riskLevel}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}
