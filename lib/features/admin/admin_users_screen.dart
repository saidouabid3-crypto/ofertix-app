import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_user_view_model.dart';
import 'admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isLoadingUsers && provider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (provider.usersError != null && provider.users.isEmpty) {
      return _ErrorRetry(msg: provider.usersError!, onRetry: provider.loadUsers);
    }

    if (provider.users.isEmpty) {
      return _EmptyState('admin.noData'.tr());
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: provider.loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.users.length,
        itemBuilder: (context, i) => _UserCard(
          user: provider.users[i],
          onAction: (action, {reason, role}) async {
            final ok = await provider.actOnUser(
              provider.users[i].uid,
              action,
              reason: reason,
              role: role,
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

typedef _UserAction = void Function(
  String action, {
  String? reason,
  String? role,
});

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onAction});

  final AdminUserViewModel user;
  final _UserAction onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: user.isBanned ? Border.all(color: AppColors.red.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.orange,
                backgroundImage: user.photoUrl.startsWith('http') ? NetworkImage(user.photoUrl) : null,
                child: !user.photoUrl.startsWith('http')
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName : user.email,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.orange, size: 15),
                      ],
                      if (user.isAdmin) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.admin_panel_settings_rounded, color: Colors.purple, size: 15),
                      ],
                    ]),
                    if (user.username.isNotEmpty)
                      Text('@${user.username}', style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                    Text(user.role.toUpperCase(),
                        style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (user.isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                  ),
                  child: Text('admin.banned'.tr(),
                      style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 12, children: [
            _Stat(Icons.play_circle_outline_rounded, user.reelsCount.toString(), 'Reels'),
            _Stat(Icons.storefront_rounded, user.sellItemsCount.toString(), 'Items'),
            _Stat(Icons.people_alt_rounded, user.followersCount.toString(), 'Followers'),
            if (user.reportsCount > 0)
              _Stat(Icons.flag_rounded, user.reportsCount.toString(), 'Reports', color: AppColors.red),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!user.isVerified)
              _Btn(label: 'admin.verify'.tr(), color: AppColors.green, icon: Icons.verified_rounded,
                  onTap: () => onAction('verify')),
            if (user.isVerified)
              _Btn(label: 'admin.unverify'.tr(), color: AppColors.gray, icon: Icons.cancel_rounded,
                  onTap: () => onAction('unverify')),
            if (!user.sellerVerified)
              _Btn(label: 'admin.verifySeller'.tr(), color: Colors.blue, icon: Icons.store_rounded,
                  onTap: () => onAction('verify_seller')),
            if (user.sellerVerified)
              _Btn(label: 'admin.removeSellerVerification'.tr(), color: AppColors.gray, icon: Icons.remove_circle_outline_rounded,
                  onTap: () => onAction('remove_seller')),
            if (!user.isBanned)
              _Btn(label: 'admin.ban'.tr(), color: AppColors.red, icon: Icons.block_rounded,
                  onTap: () => _promptBan(context)),
            if (user.isBanned)
              _Btn(label: 'admin.unban'.tr(), color: AppColors.green, icon: Icons.check_circle_rounded,
                  onTap: () => onAction('unban')),
            _Btn(label: 'admin.role'.tr(), color: Colors.amber, icon: Icons.manage_accounts_rounded,
                onTap: () => _promptRole(context)),
          ]),
        ],
      ),
    );
  }

  Future<void> _promptBan(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.ban'.tr(), style: const TextStyle(color: AppColors.red)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin.reason'.tr(),
            hintStyle: const TextStyle(color: AppColors.gray),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gray)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.red)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.ban'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onAction('ban', reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
  }

  Future<void> _promptRole(BuildContext context) async {
    const roles = ['user', 'creator', 'seller', 'merchant'];
    String? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, ss) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('admin.role'.tr(), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => RadioListTile<String>(
            title: Text(r.toUpperCase(), style: const TextStyle(color: Colors.white)),
            value: r,
            groupValue: selected,
            activeColor: AppColors.orange,
            onChanged: (v) => ss(() => selected = v),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('admin.dismiss'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
            child: Text('admin.confirmAction'.tr()),
          ),
        ],
      )),
    );
    if (confirmed == true && selected != null && context.mounted) {
      onAction('role', role: selected);
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, {this.color = AppColors.gray});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text('$value $label', style: TextStyle(color: color, fontSize: 11)),
      ]);
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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
          const Icon(Icons.inbox_rounded, color: AppColors.gray, size: 48),
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
