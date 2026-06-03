import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'cashback_provider.dart';

class CashbackScreen extends StatelessWidget {
  const CashbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CashbackProvider(),
      child: Consumer<CashbackProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),

                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        /// HEADER
                        Row(
                          children: [
                            const Text(
                              'Cashback 💸',

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),

                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.15),

                                borderRadius: BorderRadius.circular(999),
                              ),

                              child: const Text(
                                'ACTIVE',

                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        /// MAIN CARD
                        Container(
                          padding: const EdgeInsets.all(28),

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
                            ),

                            borderRadius: BorderRadius.circular(34),

                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.savings_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  ),

                                  Spacer(),

                                  Icon(
                                    Icons.payments_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              const Text(
                                'Available Cashback',

                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                '${provider.cashback.toStringAsFixed(2)}€',

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                'Withdraw anytime after confirmation.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),

                                onPressed: () {
                                  provider.calculate(price: 120, percent: 5);
                                },

                                icon: const Icon(Icons.calculate_rounded),

                                label: const Text(
                                  'Calculate',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),

                                onPressed: () {},

                                icon: const Icon(Icons.wallet_rounded),

                                label: const Text(
                                  'Withdraw',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// STATS
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                '5%',
                                'Average Rate',
                                Icons.percent_rounded,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: _statCard(
                                '${provider.finalPrice.toStringAsFixed(0)}€',
                                'Final Price',
                                Icons.shopping_bag_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 34),

                        /// HISTORY
                        const Text(
                          'Recent Cashback',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _cashbackItem('Amazon Order', '+4.25€', true),

                        _cashbackItem('MediaMarkt Purchase', '+8.90€', true),

                        _cashbackItem('Amazon Tech Deal', 'Pending', false),

                        const SizedBox(height: 40),
                      ]),
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

  Widget _statCard(String value, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        children: [
          Icon(icon, color: AppColors.green, size: 34),

          const SizedBox(height: 14),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(title, style: const TextStyle(color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _cashbackItem(String title, String value, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(18),
              ),

              child: const Icon(Icons.payments_rounded, color: AppColors.green),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            Text(
              value,

              style: TextStyle(
                color: completed ? AppColors.green : AppColors.orange,

                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
