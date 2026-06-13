import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../profile/creator_profile_screen.dart';
import '../../core/config/api_config.dart';

class MarketplaceItemDetailScreen extends StatelessWidget {
  final MarketplaceItem item;

  const MarketplaceItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: item.hasImage
                    ? Image.network(
                        item.mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(height: 16),
            // Title + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.formattedPrice,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // City + condition chips
            Row(
              children: [
                _Chip(icon: Icons.location_on_rounded, label: item.city.isEmpty ? '—' : item.city, color: AppColors.green),
                const SizedBox(width: 8),
                _Chip(icon: Icons.verified_rounded, label: _conditionLabel(item.condition), color: AppColors.orange),
              ],
            ),
            const SizedBox(height: 14),
            // Description
            if (item.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Text(
                  item.description,
                  style: TextStyle(color: text, fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
            ],
            // Seller
            GestureDetector(
              onTap: item.sellerId.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatorProfileScreen(
                            creatorId: item.sellerId,
                            baseUrl: ApiConfig.baseUrl,
                          ),
                        ),
                      ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.orange.withValues(alpha: .18),
                      backgroundImage: item.sellerAvatarUrl.startsWith('http')
                          ? NetworkImage(item.sellerAvatarUrl)
                          : null,
                      child: item.sellerAvatarUrl.startsWith('http')
                          ? null
                          : Icon(Icons.person_rounded, color: AppColors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sellerName.isNotEmpty ? item.sellerName : '—',
                            style: TextStyle(color: text, fontWeight: FontWeight.w800),
                          ),
                          if (item.sellerUsername.isNotEmpty)
                            Text(
                              '@${item.sellerUsername}',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (item.sellerVerified)
                      Icon(Icons.verified_rounded, color: AppColors.orange, size: 18),
                    Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Contact CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _contactSeller(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(
                  'marketplace.contactSeller'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactSeller(BuildContext context) {
    // Messages backend exists; for now show a snackbar directing to the Messages tab.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('marketplace.messagesComingSoon'.tr()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.orange.withValues(alpha: .10),
      child: Center(
        child: Icon(Icons.shopping_bag_rounded, color: AppColors.orange, size: 64),
      ),
    );
  }

  String _conditionLabel(String condition) {
    const map = {
      'new': 'Nuevo',
      'used_like_new': 'Como nuevo',
      'used_good': 'Buen estado',
      'used_fair': 'Aceptable',
    };
    return map[condition] ?? condition;
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
