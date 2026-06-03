import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/local_engine_provider.dart';
import 'local_widgets.dart';

class AdminOfferReviewScreen extends StatelessWidget {
  const AdminOfferReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalEngineProvider()..loadPendingOffers(),
      child: Consumer<LocalEngineProvider>(
        builder: (context, provider, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text('local.adminReview'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [IconButton(onPressed: provider.loadPendingOffers, icon: const Icon(Icons.refresh_rounded))],
          ),
          body: RefreshIndicator(
            color: AppColors.orange,
            onRefresh: provider.loadPendingOffers,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: AppColors.orange, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('local.pendingOffers'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                            const SizedBox(height: 4),
                            Text('local.adminReviewSubtitle'.tr(), style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Text(provider.pendingOffers.length.toString(), style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 28)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading) Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.orange))),
                if (!provider.isLoading && provider.pendingOffers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                    child: Text('local.noPendingOffers'.tr(), style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800)),
                  ),
                ...provider.pendingOffers.map(
                  (offer) => LocalOfferCard(
                    offer: offer,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => provider.approveOffer(offer.id),
                          icon: Icon(Icons.check_circle_rounded, color: AppColors.green),
                        ),
                        IconButton(
                          onPressed: () => provider.rejectOffer(offer.id, reason: 'Rejected by admin'),
                          icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
