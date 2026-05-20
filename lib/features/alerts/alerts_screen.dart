import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'alerts_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlertsProvider()..initialize(),

      child: Consumer<AlertsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,

              body: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,

            appBar: AppBar(
              backgroundColor: Colors.transparent,

              title: const Text('Price Alerts'),
            ),

            body: provider.alerts.isEmpty
                ? const Center(
                    child: Text(
                      'No alerts yet',

                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: provider.alerts.length,

                    itemBuilder: (context, index) {
                      final alert = provider.alerts[index].data();

                      final alertId = provider.alerts[index].id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),

                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: AppColors.card,

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active,

                              color: AppColors.orange,
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Product: ${alert['productId']}',

                                    style: const TextStyle(
                                      color: Colors.white,

                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Target: ${alert['targetPrice']}€',

                                    style: const TextStyle(
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () => provider.deleteAlert(alertId),

                              icon: const Icon(
                                Icons.delete,

                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
