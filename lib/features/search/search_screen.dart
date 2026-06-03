import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

import '../../widgets/ai_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_grid_card.dart';

import '../product_details/product_details_screen.dart';

import 'search_provider.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryLabel;
  final String? initialQuery;
  final List<Product> initialResults;

  const SearchScreen({
    super.key,
    this.initialCategory,
    this.initialCategoryLabel,
    this.initialQuery,
    this.initialResults = const [],
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();

  final List<String> trendingSearches = [
    'iPhone 15',
    'Gaming Laptop',
    'AirPods',
    'Smart TV',
    'Nike',
    'PlayStation',
    'Smartwatch',
  ];

  final List<String> categories = [
    '🔥 Trending',
    '📱 Tech',
    '🎮 Gaming',
    '👟 Fashion',
    '🏠 Home',
    '💄 Beauty',
    '🛒 Market',
  ];

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void performSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) return;

    context.read<SearchProvider>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider()..setInitialResults(widget.initialResults),

      child: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(18),

                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        /// HEADER
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),

                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,

                                color: Colors.white,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),

                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.14),

                                borderRadius: BorderRadius.circular(99),
                              ),

                              child: const Text(
                                'SMART SEARCH',

                                style: TextStyle(
                                  color: AppColors.orange,

                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Search Anything 🔥',

                          style: TextStyle(
                            color: Colors.white,

                            fontSize: 38,

                            fontWeight: FontWeight.w900,

                            letterSpacing: -1.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'AI powered product discovery & price comparison.',

                          style: TextStyle(
                            color: AppColors.gray,

                            fontSize: 15,

                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// SEARCH BAR
                        AISearchBar(
                          controller: controller,

                          onSubmitted: (value) {
                            performSearch(context, value);
                          },

                          onAiTap: () {
                            performSearch(context, controller.text);
                          },
                        ),

                        const SizedBox(height: 22),

                        /// CATEGORIES
                        SizedBox(
                          height: 46,

                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,

                            itemCount: categories.length,

                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),

                            itemBuilder: (context, index) {
                              return CategoryChip(category: categories[index]);
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// TRENDING SEARCHES
                        Row(
                          children: [
                            const Text(
                              'Trending Searches',

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 24,

                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              '${trendingSearches.length} hot',

                              style: const TextStyle(color: AppColors.gray),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children: trendingSearches.map((search) {
                            return GestureDetector(
                              onTap: () {
                                controller.text = search;

                                performSearch(context, search);
                              },

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),

                                decoration: BoxDecoration(
                                  color: AppColors.card,

                                  borderRadius: BorderRadius.circular(999),

                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),

                                child: Text(
                                  search,

                                  style: const TextStyle(
                                    color: Colors.white,

                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 34),

                        /// RESULTS HEADER
                        Row(
                          children: [
                            const Text(
                              'Results',

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 30,

                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const Spacer(),

                            if (provider.results.isNotEmpty)
                              Text(
                                '${provider.results.length} found',

                                style: const TextStyle(
                                  color: AppColors.gray,

                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),
                      ]),
                    ),
                  ),

                  /// LOADING
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.orange,
                        ),
                      ),
                    )
                  /// EMPTY
                  else if (provider.results.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,

                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),

                          child: Text(
                            'Search products with AI to discover amazing deals.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: AppColors.gray,

                              fontSize: 16,

                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  /// RESULTS
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),

                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = provider.results[index];

                          return ProductGridCard(
                            product: product,

                            isFavorite: false,

                            onFavorite: () {},

                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          );
                        }, childCount: provider.results.length),

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,

                              mainAxisSpacing: 16,

                              crossAxisSpacing: 16,

                              childAspectRatio: 0.68,
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
