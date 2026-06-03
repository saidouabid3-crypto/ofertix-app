import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/local_offer_model.dart';
import '../../models/local_store_model.dart';
import '../../services/local_engine_service.dart';
import 'local_widgets.dart';

class StoreDetailsScreen extends StatefulWidget {
  final String storeId;
  final LocalStoreModel? initialStore;

  const StoreDetailsScreen({super.key, required this.storeId, this.initialStore});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  LocalStoreModel? store;
  List<LocalOfferModel> offers = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    store = widget.initialStore;
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final loadedStore = widget.initialStore ?? await LocalEngineService.instance.getStore(widget.storeId);
      final loadedOffers = await LocalEngineService.instance.getStoreOffers(widget.storeId);
      if (!mounted) return;
      setState(() {
        store = loadedStore;
        offers = loadedOffers;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = store ?? LocalStoreModel.empty();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(data.name.isEmpty ? 'local.storeDetails'.tr() : data.name, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            _StoreHero(store: data),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
            const SizedBox(height: 18),
            Text('local.activeOffers'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 10),
            if (loading) Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.orange))),
            if (!loading && offers.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                child: Text('local.noStoreOffers'.tr(), style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800)),
              ),
            ...offers.map((offer) => LocalOfferCard(offer: offer)),
          ],
        ),
      ),
    );
  }
}

class _StoreHero extends StatelessWidget {
  final LocalStoreModel store;
  const _StoreHero({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: store.logo.startsWith('http')
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(store.logo, fit: BoxFit.cover))
                    : Icon(Icons.storefront_rounded, color: AppColors.orange, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(store.name.isEmpty ? 'local.unnamedStore'.tr() : store.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
                        if (store.verified) Icon(Icons.verified_rounded, color: AppColors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text([store.category, store.city].where((e) => e.trim().isNotEmpty).join(' • '), style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          if (store.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(store.description, style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700, height: 1.35)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Chip(icon: Icons.location_on_rounded, label: store.address.isEmpty ? store.city : store.address),
              if (store.hasWhatsApp) _Chip(icon: Icons.chat_rounded, label: 'WhatsApp'),
              if (store.hasWebsite) _Chip(icon: Icons.public_rounded, label: 'Website'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: AppColors.orange, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
      );
}
