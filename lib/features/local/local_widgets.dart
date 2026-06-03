import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/local_offer_model.dart';
import '../../models/local_store_model.dart';

class LocalStoreCard extends StatelessWidget {
  final LocalStoreModel store;
  final VoidCallback? onTap;

  const LocalStoreCard({super.key, required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: store.logo.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(store.logo, fit: BoxFit.cover),
                      )
                    : Icon(Icons.storefront_rounded, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name.isEmpty ? 'local.unnamedStore'.tr() : store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (store.verified)
                          Icon(Icons.verified_rounded, color: AppColors.green, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [store.category, store.city].where((e) => e.trim().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${store.offerCount} ${'local.offers'.tr()}',
                      style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class LocalOfferCard extends StatelessWidget {
  final LocalOfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LocalOfferCard({super.key, required this.offer, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (offer.riskLevel) {
      'RED' => Colors.redAccent,
      'YELLOW' => Colors.amber,
      _ => AppColors.green,
    };

    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: offer.hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(offer.image, fit: BoxFit.cover),
                      )
                    : Icon(Icons.local_offer_rounded, color: AppColors.orange, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title.isEmpty ? 'local.unnamedOffer'.tr() : offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [offer.storeName, offer.city].where((e) => e.trim().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${offer.newPrice.toStringAsFixed(2)} ${offer.currency}',
                          style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        if (offer.oldPrice > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${offer.oldPrice.toStringAsFixed(2)} ${offer.currency}',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            offer.riskLevel,
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                        if (offer.discountPercent > 0) ...[
                          const SizedBox(width: 8),
                          Text('-${offer.discountPercent}%', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
