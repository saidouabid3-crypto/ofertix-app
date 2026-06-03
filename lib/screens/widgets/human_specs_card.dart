import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/global_deal_model.dart';

class HumanSpecsCard extends StatelessWidget {
  final HumanSpecsCardData data;
  const HumanSpecsCard({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final items = data.items.isEmpty
        ? [
            const HumanSpecItem(
              spec: 'Specs',
              humanMeaning: 'Add product specs for a better explanation.',
              importance: 'MEDIUM',
            ),
          ]
        : data.items;
    return Container(
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
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF6FF),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('auto_sweep.screens_widgets_human_specs_card.human_specs'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('auto_sweep.screens_widgets_human_specs_card.technical_jargon_converted_to_real_life'.tr(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.summary.isNotEmpty)
            Text(
              data.summary,
              style: TextStyle(
                color: Colors.black.withValues(alpha: .64),
                height: 1.45,
              ),
            ),
          const SizedBox(height: 12),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: i.importance == 'HIGH'
                        ? const Color(0xFF16A34A)
                        : i.importance == 'LOW'
                        ? Colors.black45
                        : const Color(0xFFF59E0B),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(
                          context,
                        ).style.copyWith(height: 1.35),
                        children: [
                          TextSpan(
                            text: '${i.spec}: ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          TextSpan(text: i.humanMeaning),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
