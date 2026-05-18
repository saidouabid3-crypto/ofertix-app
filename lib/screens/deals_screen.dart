import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'details_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final ApiService api = ApiService();
  final ScrollController scrollController = ScrollController();

  List<Product> allDeals = [];

  int page = 1;
  int totalCount = 0;
  bool loadingFirst = true;
  bool loadingMore = false;
  bool hasMore = true;
  String currentCountry = 'es';

  @override
  void initState() {
    super.initState();
    _initAndLoad();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 400) {
        loadMoreDeals();
      }
    });
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        currentCountry = prefs.getString('country') ?? 'es';
      });
      loadFirstPage();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadFirstPage() async {
    setState(() {
      loadingFirst = true;
      loadingMore = false;
      page = 1;
      hasMore = true;
      allDeals = [];
    });

    final result = await api.getProductsPage(
      page: 1,
      limit: 50,
      countryCode: currentCountry,
    );

    final deals = result.products
        .where((p) => p.discount >= 10 || p.isHot)
        .toList();

    deals.sort((a, b) => b.discount.compareTo(a.discount));

    setState(() {
      allDeals = deals;
      totalCount = result.count;
      hasMore = result.hasMore;
      loadingFirst = false;
    });
  }

  Future<void> loadMoreDeals() async {
    if (loadingMore || !hasMore) return;

    setState(() {
      loadingMore = true;
    });

    final nextPage = page + 1;
    final result = await api.getProductsPage(
      page: nextPage,
      limit: 50,
      countryCode: currentCountry,
    );

    final deals = result.products
        .where((p) => p.discount >= 10 || p.isHot)
        .toList();

    deals.sort((a, b) => b.discount.compareTo(a.discount));

    setState(() {
      page = nextPage;
      allDeals.addAll(deals);
      totalCount = result.count;
      hasMore = result.hasMore;
      loadingMore = false;
    });
  }

  Future<void> refreshDeals() async {
    final prefs = await SharedPreferences.getInstance();
    currentCountry = prefs.getString('country') ?? 'es';
    await loadFirstPage();
  }

  void openProduct(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          product: p,
          allProducts: allDeals,
          isFavorite: false,
          onFavorite: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: loadingFirst
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : RefreshIndicator(
                onRefresh: refreshDeals,
                color: AppColors.orange,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                  children: [
                    Text(
                      '🔥 Hot Deals',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Best discounts available now',
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xffFF7A00), Color(0xffFF3D00)],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FLASH SALE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Top discounts',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Trending Now',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${allDeals.length}/$totalCount',
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (allDeals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'No deals found',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                    ...allDeals.map(
                      (p) => ProductCard(
                        product: p,
                        isFavorite: false,
                        onFavorite: () {},
                        onTap: () => openProduct(p),
                      ),
                    ),
                    if (loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    if (!hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No more deals',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
