import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class NegotiationBottomSheet extends StatelessWidget {
  final String script, sellerLanguage, targetPrice;
  const NegotiationBottomSheet({
    super.key,
    required this.script,
    required this.sellerLanguage,
    required this.targetPrice,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text('auto_sweep.screens_widgets_negotiation_bottom_sheet.ai_negotiator'.tr(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Seller language: $sellerLanguage · Target: $targetPrice',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6EDF2)),
            ),
            child: SelectableText(
              script,
              style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: script));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('auto_sweep.screens_widgets_negotiation_bottom_sheet.copied'.tr()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text('auto_sweep.screens_widgets_negotiation_bottom_sheet.copy'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: script)),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text('product.share'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
