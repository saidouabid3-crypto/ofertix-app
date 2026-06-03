import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/global_deal_model.dart';

class GlobalAlternativeCard extends StatelessWidget {
  final GlobalAlternativeCardData data;
  const GlobalAlternativeCard({super.key, required this.data});
  Future<void> _openUrl() async {
    final uri = Uri.tryParse(data.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = data.url.trim().isNotEmpty;
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
                backgroundColor: Color(0xFFECFDF3),
                child: Icon(Icons.public_rounded, color: Color(0xFF16A34A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('auto_sweep.screens_widgets_global_alternative_card.global_alternative'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('auto_sweep.screens_widgets_global_alternative_card.a_smarter_option_for_your_country'.tr(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title.isEmpty
                ? 'No stronger alternative found yet'
                : data.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            data.whyBetter.isEmpty
                ? 'Compare with local stores before buying internationally.'
                : data.whyBetter,
            style: TextStyle(
              color: Colors.black.withValues(alpha: .64),
              height: 1.45,
            ),
          ),
          if (data.shippingAdvantage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              data.shippingAdvantage,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EDF2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.store.isEmpty ? 'Alternative' : data.store,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.estimatedTotalCost.amount > 0
                            ? data.estimatedTotalCost.format()
                            : 'Check price',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: hasUrl ? _openUrl : null,
                child: Text('auto_sweep.screens_widgets_global_alternative_card.view_deal'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
