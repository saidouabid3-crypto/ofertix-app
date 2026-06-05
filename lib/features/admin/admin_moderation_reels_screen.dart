import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_moderation_item_model.dart';
import 'admin_provider.dart';

class AdminModerationReelsScreen extends StatefulWidget {
  const AdminModerationReelsScreen({super.key});

  @override
  State<AdminModerationReelsScreen> createState() => _AdminModerationReelsScreenState();
}

class _AdminModerationReelsScreenState extends State<AdminModerationReelsScreen> {
  static const _filters = ['approved', 'pending', 'hidden', 'rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        // Filter bar
        Container(
          height: 48,
          color: AppColors.card,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _filters.map((f) {
              final selected = provider.reelsStatusFilter == f;
              return GestureDetector(
                onTap: () => provider.loadReels(status: f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.orange : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'admin.$f'.tr(),
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.gray,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: provider.isLoadingReels
              ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
              : provider.reelsError != null
                  ? _ErrorRetry(msg: provider.reelsError!, onRetry: provider.loadReels)
                  : provider.reels.isEmpty
                      ? _EmptyState('admin.noData'.tr())
                      : RefreshIndicator(
                          color: AppColors.orange,
                          onRefresh: provider.loadReels,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.reels.length,
                            itemBuilder: (context, i) => _ReelCard(
                              item: provider.reels[i],
                              onAction: (action, reason) async {
                                final ok = await provider.moderateReel(
                                  provider.reels[i].id,
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
                        ),
        ),
      ],
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.item, required this.onAction});

  final AdminModerationItemModel item;
  final void Function(String action, String? reason) onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.thumbnailUrl?.startsWith('http') == true
                    ? Image.network(item.thumbnailUrl!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? 'admin.noData'.tr(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _IdentityRow(
                      avatarUrl: item.creatorAvatarUrl,
                      name: item.creatorName,
                      username: item.creatorUsername,
                    ),
                  ],
                ),
              ),
              _StatusChip(item.status),
            ],
          ),
          if (item.reportsCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.red, size: 14),
                const SizedBox(width: 4),
                Text('${item.reportsCount} reports', style: const TextStyle(color: AppColors.red, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _ActionRow(
            status: item.status,
            onAction: onAction,
            itemType: 'reel',
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.play_circle_outline_rounded, color: AppColors.gray),
      );
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({this.avatarUrl, this.name, this.username});

  final String? avatarUrl;
  final String? name;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.orange,
          backgroundImage: avatarUrl?.startsWith('http') == true ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl?.startsWith('http') != true
              ? const Icon(Icons.person, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name ?? username ?? '—',
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = {
      'approved': AppColors.green,
      'pending': Colors.amber,
      'rejected': AppColors.red,
      'hidden': AppColors.gray,
      'active': AppColors.green,
    };
    final c = colors[status] ?? AppColors.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        'admin.$status'.tr(),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.status, required this.onAction, this.itemType = 'reel'});

  final String status;
  final String itemType;
  final void Function(String action, String? reason) onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status != 'approved')
          _ActionBtn(label: 'admin.approve'.tr(), color: AppColors.green, icon: Icons.check_rounded, onTap: () => onAction('approve', null)),
        if (status != 'rejected')
          _ActionBtn(label: 'admin.reject'.tr(), color: AppColors.red, icon: Icons.close_rounded, onTap: () => _promptReason(context, 'reject')),
        if (status != 'hidden')
          _ActionBtn(label: 'admin.hide'.tr(), color: AppColors.gray, icon: Icons.visibility_off_rounded, onTap: () => _promptReason(context, 'hide')),
        if (status == 'hidden' || status == 'rejected')
          _ActionBtn(label: 'admin.restore'.tr(), color: Colors.blue, icon: Icons.restore_rounded, onTap: () => onAction('restore', null)),
      ],
    );
  }

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
          maxLines: 3,
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, color: AppColors.gray, size: 48),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppColors.gray)),
          ],
        ),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text('admin.loadError'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('admin.retry'.tr()),
            ),
          ],
        ),
      );
}
