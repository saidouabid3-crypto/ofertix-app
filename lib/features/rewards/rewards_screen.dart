import 'package:easy_localization/easy_localization.dart';
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
      child: const _RewardsBody(),
    );
  }
}

class _RewardsBody extends StatelessWidget {
  const _RewardsBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () => provider.refresh(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Header ─────────────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'auto.rewards_rewards_screen.rewards'.tr(),
                          style: const TextStyle(
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
                          child: Text(
                            _vipLabel(provider.coins),
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Main coins card ─────────────────────────────────────
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
                          Text(
                            'auto.rewards_rewards_screen.ofertix_coins'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          provider.isLoading
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  '${provider.coins}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                  ),
                                ),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _levelProgress(provider.coins),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _progressLabel(provider.coins),
                            style:
                                const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // ── Daily missions (not yet tracked — coming soon) ──────
                    Text(
                      'auto.rewards_rewards_screen.daily_missions'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _missionCard(
                      icon: Icons.search_rounded,
                      title: 'rewards.missionSearch'.tr(),
                      reward: '+20',
                    ),
                    _missionCard(
                      icon: Icons.shopping_bag_rounded,
                      title: 'rewards.missionOpenDeal'.tr(),
                      reward: '+15',
                    ),
                    _missionCard(
                      icon: Icons.people_alt_rounded,
                      title: 'rewards.missionInvite'.tr(),
                      reward: '+100',
                    ),
                    _missionCard(
                      icon: Icons.flash_on_rounded,
                      title: 'rewards.missionDailyLogin'.tr(),
                      reward: '+5',
                    ),

                    const SizedBox(height: 30),

                    // ── AI booster banner ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.orange,
                            size: 52,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'auto.rewards_rewards_screen.ai_reward_booster'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'auto.rewards_rewards_screen.ai_automatically_boosts_your_rewards_w'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// VIP level based on real coin count.
  String _vipLabel(int coins) {
    final level = (coins ~/ 100) + 1;
    return 'LEVEL $level';
  }

  /// Progress within the current level (0.0 – 1.0).
  double _levelProgress(int coins) {
    final coinsInLevel = coins % 100;
    return coinsInLevel / 100;
  }

  String _progressLabel(int coins) {
    final remaining = 100 - (coins % 100);
    return '$remaining ${'rewards.coinsToNextLevel'.tr()}';
  }

  Widget _missionCard({
    required IconData icon,
    required String title,
    required String reward,
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
