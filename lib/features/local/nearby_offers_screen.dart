import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/local_engine_provider.dart';
import 'local_widgets.dart';
import 'store_details_screen.dart';

class NearbyOffersScreen extends StatelessWidget {
  const NearbyOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalEngineProvider()..loadNearby(radiusKm: 12),
      child: Consumer<LocalEngineProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              title: Text('local.nearbyTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                IconButton(
                  onPressed: provider.isLoading ? null : () => provider.loadNearby(radiusKm: 12),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => provider.loadNearby(radiusKm: 12),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                children: [
                  _Hero(provider: provider),
                  const SizedBox(height: 18),
                  Text('local.localOffers'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 10),
                  if (provider.isLoading) const _LoadingList(),
                  if (provider.errorMessage != null) _ErrorBox(text: provider.errorMessage!),
                  if (!provider.isLoading && provider.offers.isEmpty && provider.errorMessage == null)
                    _EmptyBox(text: 'local.noNearbyOffers'.tr()),
                  ...provider.offers.map((offer) => LocalOfferCard(offer: offer)),
                  const SizedBox(height: 20),
                  Text('local.nearbyStores'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 10),
                  if (!provider.isLoading && provider.stores.isEmpty && provider.errorMessage == null)
                    _EmptyBox(text: 'local.noNearbyStores'.tr()),
                  ...provider.stores.map(
                    (store) => LocalStoreCard(
                      store: store,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StoreDetailsScreen(storeId: store.id, initialStore: store)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final LocalEngineProvider provider;
  const _Hero({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.radar_rounded, color: Colors.black, size: 34),
          const SizedBox(height: 10),
          Text('local.radarTitle'.tr(), style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('local.radarSubtitle'.tr(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text('${provider.offers.length} ${'local.offers'.tr()} • ${provider.stores.length} ${'local.stores'.tr()}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.orange)));
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
        child: Text(text.tr(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800)),
      );
}
