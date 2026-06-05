import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_product_quality_model.dart';
import 'admin_provider.dart';

class AdminProductQualityScreen extends StatefulWidget {
  const AdminProductQualityScreen({super.key});

  @override
  State<AdminProductQualityScreen> createState() => _AdminProductQualityScreenState();
}

class _AdminProductQualityScreenState extends State<AdminProductQualityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProductQuality();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingProductQuality && provider.productQualityItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.productQualityError != null && provider.productQualityItems.isEmpty) {
      return _ErrorRetry(msg: provider.productQualityError!, onRetry: provider.loadProductQuality);
    }

    if (provider.productQualityItems.isEmpty) {
      return _EmptyState('admin.noData'.tr());
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadProductQuality,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.productQualityItems.length,
        itemBuilder: (context, i) => _ProductCard(
          item: provider.productQualityItems[i],
          onAction: (action, reason) async {
            final ok = await provider.actOnProduct(
              provider.productQualityItems[i].id,
              action,
              reason: reason,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'admin.actionSuccess'.tr() : 'admin.actionFailed'.tr()),
                backgroundColor: ok ? AppColors.green : AppColors.red,
              ));
            }
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onAction});

  final AdminProductQualityItemModel item;
  final void Function(String action, String? reason) onAction;

  @override
  Widget build(BuildContext context) {
    final issueColors = {
      'missing_image': Colors.amber,
      'missing_url': AppColors.orange,
      'needs_review': AppColors.red,
      'hidden': AppColors.gray,
    };
    final issueColor = issueColors[item.issue] ?? AppColors.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: issueColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl?.startsWith('http') == true
                    ? Image.network(item.imageUrl!, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? 'admin.noData'.tr(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.store?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(item.store!, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                    ],
                    if (item.price != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${item.price!.toStringAsFixed(2)} ${item.countryCode ?? ''}',
                        style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.issue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: issueColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    (item.issue ?? '').replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: issueColor, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Btn(label: 'admin.hide'.tr(), color: AppColors.gray, icon: Icons.visibility_off_rounded,
                onTap: () => _promptReason(context, 'hide')),
            if (item.status == 'hidden')
              _Btn(label: 'admin.restore'.tr(), color: AppColors.green, icon: Icons.restore_rounded,
                  onTap: () => onAction('restore', null)),
            _Btn(label: 'admin.markReview'.tr(), color: Colors.amber, icon: Icons.rate_review_rounded,
                onTap: () => _promptReason(context, 'mark_review')),
          ]),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image_not_supported_rounded, color: AppColors.gray),
      );

  Future<void> _promptReason(BuildContext context, String action) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.reason'.tr(), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin.reason'.tr(),
            hintStyle: const TextStyle(color: AppColors.gray),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onAction(action, ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_rounded, color: AppColors.green, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.gray)),
        ]),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 40),
          const SizedBox(height: 12),
          Text('admin.loadError'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('admin.retry'.tr()),
          ),
        ]),
      );
}
