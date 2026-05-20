import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'rewards_provider.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RewardsProvider(),
      child: Consumer<RewardsProvider>(
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
                              'Rewards 🚀',

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
                                color: AppColors.orange.withValues(alpha: 0.15),

                                borderRadius: BorderRadius.circular(999),
                              ),

                              child: const Text(
                                'VIP LEVEL 3',

                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        /// MAIN CARD
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(28),

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A00), Color(0xFF7C3AED)],
                            ),

                            borderRadius: BorderRadius.circular(34),

                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withValues(alpha: 0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  ),

                                  Spacer(),

                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 26),

                              const Text(
                                'Ofertix Coins',

                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                provider.coins.toString(),

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                ),
                              ),

                              const SizedBox(height: 20),

                              LinearProgressIndicator(
                                value: 0.72,

                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.15,
                                ),

                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                '72% to next VIP level',

                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ACTIONS
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                icon: Icons.add_rounded,
                                title: 'Earn',
                                color: AppColors.orange,
                                onTap: () {
                                  provider.earn(10);
                                },
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: _actionButton(
                                icon: Icons.card_giftcard_rounded,
                                title: 'Redeem',
                                color: AppColors.green,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 34),

                        /// DAILY MISSIONS
                        const Text(
                          'Daily Missions',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _missionCard(
                          icon: Icons.search_rounded,
                          title: 'Search 5 products',
                          reward: '+20',
                          completed: true,
                        ),

                        _missionCard(
                          icon: Icons.shopping_bag_rounded,
                          title: 'Open affiliate deal',
                          reward: '+15',
                        ),

                        _missionCard(
                          icon: Icons.people_alt_rounded,
                          title: 'Invite a friend',
                          reward: '+100',
                        ),

                        _missionCard(
                          icon: Icons.flash_on_rounded,
                          title: 'Daily login bonus',
                          reward: '+5',
                        ),

                        const SizedBox(height: 30),

                        /// BONUS
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(24),

                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(28),
                          ),

                          child: const Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: AppColors.orange,
                                size: 52,
                              ),

                              SizedBox(height: 18),

                              Text(
                                'AI Reward Booster',

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              SizedBox(height: 12),

                              Text(
                                'AI automatically boosts your rewards when detecting hot deals interactions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.gray,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

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

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),

        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),

          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),

        child: Column(
          children: [
            Icon(icon, color: color, size: 34),

            const SizedBox(height: 10),

            Text(
              title,

              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionCard({
    required IconData icon,
    required String title,
    required String reward,
    bool completed = false,
  }) {
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
                color: AppColors.orange.withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(icon, color: AppColors.orange),
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

            if (completed)
              const Icon(Icons.check_circle_rounded, color: AppColors.green)
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),

                  borderRadius: BorderRadius.circular(999),
                ),

                child: Text(
                  reward,

                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
