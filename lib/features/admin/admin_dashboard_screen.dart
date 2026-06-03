import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'admin_provider.dart';

import 'widgets/stat_card.dart';
import 'widgets/analytics_chart.dart';
import 'widgets/top_product_tile.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),

      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.orange,

                onRefresh: provider.refreshDashboard,

                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),

                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          /// HEADER
                          Row(
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Admin Dashboard',

                                    style: TextStyle(
                                      color: Colors.white,

                                      fontSize: 34,

                                      fontWeight: FontWeight.w900,

                                      letterSpacing: -1,
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    'Ofertix Analytics System',

                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),

                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(
                                    alpha: 0.15,
                                  ),

                                  borderRadius: BorderRadius.circular(999),
                                ),

                                child: const Text(
                                  'LIVE',

                                  style: TextStyle(
                                    color: AppColors.green,

                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          /// STATS
                          SizedBox(
                            height: 180,

                            child: GridView.count(
                              physics: const NeverScrollableScrollPhysics(),

                              crossAxisCount: 2,

                              mainAxisSpacing: 14,

                              crossAxisSpacing: 14,

                              childAspectRatio: 1.4,

                              children: [
                                AdminStatCard(
                                  title: 'Users',

                                  value: provider.totalUsers.toString(),

                                  icon: Icons.people_alt_rounded,

                                  color: AppColors.orange,
                                ),

                                AdminStatCard(
                                  title: 'Clicks',

                                  value: provider.totalClicks.toString(),

                                  icon: Icons.ads_click_rounded,

                                  color: AppColors.green,
                                ),

                                AdminStatCard(
                                  title: 'Orders',

                                  value: provider.totalOrders.toString(),

                                  icon: Icons.shopping_bag_rounded,

                                  color: AppColors.red,
                                ),

                                AdminStatCard(
                                  title: 'Revenue',

                                  value:
                                      '${provider.revenue.toStringAsFixed(0)}€',

                                  icon: Icons.payments_rounded,

                                  color: Colors.amber,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 34),

                          /// CHART
                          const Text(
                            'Analytics',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 28,

                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const AnalyticsChart(),

                          const SizedBox(height: 34),

                          /// TOP SEARCHES
                          const Text(
                            'Trending Searches',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 28,

                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 18),

                          ...provider.topSearches.map(
                            (search) => Container(
                              margin: const EdgeInsets.only(bottom: 12),

                              padding: const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color: AppColors.card,

                                borderRadius: BorderRadius.circular(22),
                              ),

                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),

                                    decoration: BoxDecoration(
                                      color: AppColors.orange.withValues(
                                        alpha: 0.14,
                                      ),

                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    child: const Icon(
                                      Icons.trending_up_rounded,

                                      color: AppColors.orange,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Text(
                                      search,

                                      style: const TextStyle(
                                        color: Colors.white,

                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),

                                  const Text(
                                    'HOT',

                                    style: TextStyle(
                                      color: AppColors.red,

                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 34),

                          /// TOP PRODUCTS
                          const Text(
                            'Top Products',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 28,

                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const TopProductTile(
                            name: 'iPhone 15 Pro Max',

                            store: 'Amazon',

                            clicks: '12.4K',

                            revenue: '+420€',
                          ),

                          const TopProductTile(
                            name: 'Gaming Laptop RTX',

                            store: 'PcComponentes',

                            clicks: '8.1K',

                            revenue: '+310€',
                          ),

                          const TopProductTile(
                            name: 'AirPods Pro',

                            store: 'Amazon',

                            clicks: '5.6K',

                            revenue: '+170€',
                          ),

                          const SizedBox(height: 50),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
