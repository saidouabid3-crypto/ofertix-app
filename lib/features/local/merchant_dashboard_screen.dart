import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/local_engine_provider.dart';
import 'create_offer_screen.dart';
import 'create_store_screen.dart';
import 'local_widgets.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalEngineProvider()..loadMerchantDashboard(),
      child: Consumer<LocalEngineProvider>(
        builder: (context, provider, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text('local.merchantDashboard'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [IconButton(onPressed: provider.loadMerchantDashboard, icon: const Icon(Icons.refresh_rounded))],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.black,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOfferScreen())),
            icon: const Icon(Icons.add_rounded),
            label: Text('local.addOffer'.tr()),
          ),
          body: RefreshIndicator(
            color: AppColors.orange,
            onRefresh: provider.loadMerchantDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                _Stats(stores: provider.stores.length, offers: provider.offers.length),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoreScreen())),
                    icon: const Icon(Icons.storefront_rounded),
                    label: Text('local.addStore'.tr()),
                  ),
                ),
                const SizedBox(height: 20),
                Text('local.myStores'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 10),
                if (provider.isLoading) Center(child: CircularProgressIndicator(color: AppColors.orange)),
                if (!provider.isLoading && provider.stores.isEmpty) _Empty(text: 'local.noMerchantStores'.tr()),
                ...provider.stores.map((store) => LocalStoreCard(store: store)),
                const SizedBox(height: 20),
                Text('local.myOffers'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 10),
                if (!provider.isLoading && provider.offers.isEmpty) _Empty(text: 'local.noMerchantOffers'.tr()),
                ...provider.offers.map((offer) => LocalOfferCard(offer: offer)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final int stores;
  final int offers;
  const _Stats({required this.stores, required this.offers});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.orangeGradient, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Expanded(child: _Stat(value: stores.toString(), label: 'local.stores'.tr())),
            Expanded(child: _Stat(value: offers.toString(), label: 'local.offers'.tr())),
            Expanded(child: _Stat(value: '0', label: 'local.leads'.tr())),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)), Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800))]);
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800)));
}
