import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

import '../../widgets/product_grid_card.dart';
import '../../widgets/ai_search_bar.dart';
import '../../widgets/category_chip.dart';

import '../product_details/product_details_screen.dart';
import '../search/search_screen.dart';
import '../deals/deals_screen.dart';
import '../profile/profile_screen.dart';

import 'home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  int selectedIndex = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openTab(int index) {
    if (index == 0) return;

    Widget screen;

    if (index == 1) {
      screen = const SearchScreen();
    } else if (index == 2) {
      screen = const DealsScreen();
    } else {
      screen = const ProfileScreen();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider()..initialize(),
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final allProducts = provider.products;

          final hotProducts = provider.hotProducts.isNotEmpty
              ? provider.hotProducts
              : allProducts.take(6).toList();

          final featuredProducts = provider.featuredProducts.isNotEmpty
              ? provider.featuredProducts
              : allProducts;

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
            bottomNavigationBar: NavigationBar(
              backgroundColor: AppColors.card,
              indicatorColor: AppColors.orange.withValues(alpha: 0.20),
              selectedIndex: selectedIndex,
              onDestinationSelected: openTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.orange),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search, color: AppColors.orange),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_fire_department_outlined),
                  selectedIcon: Icon(
                    Icons.local_fire_department,
                    color: AppColors.orange,
                  ),
                  label: 'Deals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.orange),
                  label: 'Profile',
                ),
              ],
            ),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _Header(),

                        const SizedBox(height: 26),

                        AISearchBar(
                          controller: searchController,
                          onSubmitted: (value) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          onAiTap: () {
                            Navigator.pushNamed(context, '/ai-assistant');
                          },
                        ),

                        const SizedBox(height: 24),

                        _CategoryRow(),

                        const SizedBox(height: 34),

                        _SectionTitle(
                          emoji: '🔥',
                          title: 'Hot Deals',
                          action: 'See all',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DealsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          height: 360,
                          child: hotProducts.isEmpty
                              ? const _EmptyBox(text: 'No hot deals yet')
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: hotProducts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 230,
                                      child: _ProductItem(
                                        product: hotProducts[index],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 38),

                        _SectionTitle(
                          emoji: '⭐',
                          title: 'Featured',
                          action: 'Explore',
                          onTap: () {},
                        ),

                        const SizedBox(height: 18),
                      ]),
                    ),
                  ),

                  if (featuredProducts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyBox(text: 'No products available'),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _ProductItem(product: featuredProducts[index]);
                        }, childCount: featuredProducts.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.56,
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertix',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'AI Shopping Revolution',
              style: TextStyle(color: AppColors.gray, fontSize: 17),
            ),
          ],
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_active,
            color: AppColors.orange,
            size: 30,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const categories = [
      '🔥 Hot',
      '📱 Tech',
      '🎮 Gaming',
      '👟 Fashion',
      '🏠 Home',
      '🛒 Market',
      '💄 Beauty',
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return CategoryChip(category: categories[index]);
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductItem extends StatelessWidget {
  final Product product;

  const _ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductGridCard(
      product: product,
      isFavorite: false,
      onFavorite: () {},
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
