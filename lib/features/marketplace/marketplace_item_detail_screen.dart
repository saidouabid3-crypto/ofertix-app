import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import '../profile/creator_profile_screen.dart';
import 'marketplace_listing_form_screen.dart';

class MarketplaceItemDetailScreen extends StatefulWidget {
  final MarketplaceItem item;
  final bool showOwnerStatus;

  const MarketplaceItemDetailScreen({
    super.key,
    required this.item,
    this.showOwnerStatus = false,
  });

  @override
  State<MarketplaceItemDetailScreen> createState() =>
      _MarketplaceItemDetailScreenState();
}

class _MarketplaceItemDetailScreenState
    extends State<MarketplaceItemDetailScreen> {
  late MarketplaceItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<MarketplaceItem>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceListingFormScreen(existingItem: _item),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _item = updated);
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sell16.archiveTitle'.tr()),
        content: Text('sell16.archiveMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('sell16.archive'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final archived = await MarketplaceService.instance.archiveMyItem(
        _item.id,
      );
      if (!mounted) return;
      setState(() => _item = archived);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sell16.archiveFailed'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'marketplace.openListing'.tr(),
          style: TextStyle(color: text, fontWeight: FontWeight.w900),
        ),
        backgroundColor: bg,
        iconTheme: IconThemeData(color: text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: _item.hasImage
                    ? Image.network(
                        _item.mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                      )
                    : const _ImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _item.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              _item.formattedPrice,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_on_rounded,
                  label: _item.city,
                  color: AppColors.green,
                ),
                _InfoChip(
                  icon: Icons.verified_rounded,
                  label: 'sell16.condition.${_item.conditionKey}'.tr(),
                  color: AppColors.orange,
                ),
                _InfoChip(
                  icon: Icons.local_shipping_outlined,
                  label: 'sell16.delivery.${_item.deliveryMethodKey}'.tr(),
                  color: AppColors.orange,
                ),
                if (widget.showOwnerStatus)
                  _InfoChip(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'sell16.status.${_item.status}'.tr(),
                    color: _statusColor(_item.status),
                  ),
              ],
            ),
            if (widget.showOwnerStatus && _item.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Panel(
                color: AppColors.red.withValues(alpha: .08),
                border: AppColors.red.withValues(alpha: .3),
                child: Text(
                  'sell16.rejectionReason'.tr(
                    namedArgs: {'reason': _item.rejectionReason},
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _Panel(color: card, border: border, child: Text(_item.description)),
            const SizedBox(height: 14),
            if (!widget.showOwnerStatus)
              GestureDetector(
                onTap: _item.sellerId.isEmpty
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatorProfileScreen(
                            creatorId: _item.sellerId,
                            baseUrl: ApiConfig.baseUrl,
                          ),
                        ),
                      ),
                child: _Panel(
                  color: card,
                  border: border,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            _item.sellerAvatarUrl.startsWith('http')
                            ? NetworkImage(_item.sellerAvatarUrl)
                            : null,
                        child: _item.sellerAvatarUrl.startsWith('http')
                            ? null
                            : const Icon(Icons.person_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _item.sellerName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_item.sellerVerified)
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.orange,
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.showOwnerStatus) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _item.canEdit ? _edit : null,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text('sell16.edit'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _item.isArchived ? null : _archive,
                      icon: const Icon(Icons.archive_outlined),
                      label: Text('sell16.archive'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'approved' || 'active' || 'published' => AppColors.green,
    'rejected' => AppColors.red,
    'hidden' || 'archived' => AppColors.gray,
    _ => AppColors.orange,
  };
}

class _Panel extends StatelessWidget {
  final Color color;
  final Color border;
  final Widget child;

  const _Panel({
    required this.color,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    ),
    child: child,
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: .1),
    child: const Icon(
      Icons.shopping_bag_rounded,
      color: AppColors.orange,
      size: 64,
    ),
  );
}
