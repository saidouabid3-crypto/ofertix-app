import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

import '../widgets/product_card.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/daily_reward_popup.dart';

import '../services/api_service.dart';
import 'deals_screen.dart';
import 'details_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'watchlist_screen.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  final Set<String>? initialFavorites;

  const HomeScreen({super.key, this.initialFavorites});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  late Set<String> favoriteIds;
  List<Product> sharedProducts = [];

  @override
  void initState() {
    super.initState();
    favoriteIds = widget.initialFavorites ?? {};
  }

  void toggleFavorite(String id) {
    setState(() {
      favoriteIds.contains(id) ? favoriteIds.remove(id) : favoriteIds.add(id);
    });
  }

  void updateSharedProducts(List<Product> products) {
    sharedProducts = products;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(
        favoriteIds: favoriteIds,
        onFavorite: toggleFavorite,
        onProductsLoaded: updateSharedProducts,
      ),
      const DealsScreen(),
      const ScanScreen(),
      WatchlistScreen(
        products: sharedProducts,
        favoriteIds: favoriteIds,
        onFavorite: toggleFavorite,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: BottomNav(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final Set<String> favoriteIds;
  final void Function(String) onFavorite;
  final void Function(List<Product>) onProductsLoaded;

  const _HomeContent({
    required this.favoriteIds,
    required this.onFavorite,
    required this.onProductsLoaded,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final ApiService api = ApiService();
  final ScrollController scrollController = ScrollController();

  Timer? searchDebounce;
  final List<String> recentSearches = [];
  List<Product> allProducts = [];

  int page = 1;
  int totalCount = 0;

  bool loadingFirst = true;
  bool loadingMore = false;
  bool hasMore = true;

  String query = '';
  String selectedCategory = 'All';
  bool gridMode = true;
  String currentCountry = 'es';

  int selectedOfferType = 0;
  Position? _currentUserPosition;

  final categories = [
    'All',
    'Electrónica',
    'Smartphones',
    'Gaming',
    'PC & Laptops',
    'TV & Audio',
    'Supermercado',
    'Bebidas',
    'Comida',
    'Snacks',
    'Moda',
    'Zapatos',
    'Perfumes',
    'Belleza',
    'Hogar',
    'Cocina',
    'Muebles',
    'Decoración',
    'Deportes',
    'Fitness',
    'Bebés',
    'Mascotas',
    'Automóvil',
    'Herramientas',
    'Sponsored Deals',
  ];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _determinePosition();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 400) {
        loadMoreProducts();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyRewardPopup.show(context);
    });
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.reduced,
        ),
      );

      if (mounted) {
        setState(() {
          _currentUserPosition = position;
        });
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      currentCountry = (prefs.getString('country') ?? 'es').toLowerCase();
    });

    await loadFirstPage();
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadFirstPage() async {
    setState(() {
      loadingFirst = true;
      page = 1;
      hasMore = true;
      allProducts = [];
    });

    final result = await api.getProductsPage(
      page: 1,
      limit: 50,
      countryCode: currentCountry,
    );

    if (!mounted) return;

    setState(() {
      allProducts = result.products;
      hasMore = result.hasMore;
      totalCount = result.count;
      loadingFirst = false;
    });

    debugPrint("COUNTRY: $currentCountry");
    debugPrint("PRODUCTS FOUND: ${result.products.length}");

    widget.onProductsLoaded(allProducts);
  }

  Future<void> loadMoreProducts() async {
    if (loadingMore || !hasMore || query.trim().isNotEmpty) return;

    setState(() {
      loadingMore = true;
    });

    final nextPage = page + 1;

    final result = await api.getProductsPage(
      page: nextPage,
      limit: 50,
      countryCode: currentCountry,
    );

    if (!mounted) return;

    setState(() {
      page = nextPage;
      allProducts.addAll(result.products);
      hasMore = result.hasMore;
      totalCount = allProducts.length;
      loadingMore = false;
    });

    widget.onProductsLoaded(allProducts);
  }

  Future<void> refreshProducts() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      currentCountry = (prefs.getString('country') ?? 'es').toLowerCase();
    });

    await loadFirstPage();
  }

  void _saveRecentSearch(String value) {
    final text = value.trim();
    if (text.length < 2) return;

    setState(() {
      recentSearches.removeWhere(
        (item) => item.toLowerCase() == text.toLowerCase(),
      );
      recentSearches.insert(0, text);

      if (recentSearches.length > 8) {
        recentSearches.removeLast();
      }
    });
  }

  List<Product> filterProducts(List<Product> products) {
    final q = query.trim().toLowerCase();

    bool matchCategory(Product p) {
      if (selectedCategory == 'All') return true;

      final text = '${p.name} ${p.category} ${p.description} ${p.store}'
          .toLowerCase();

      final cat = selectedCategory.toLowerCase();

      if (cat.contains('electrónica')) {
        return text.contains('electr') ||
            text.contains('phone') ||
            text.contains('smartphone') ||
            text.contains('iphone') ||
            text.contains('samsung') ||
            text.contains('audio') ||
            text.contains('usb') ||
            text.contains('camera');
      }

      if (cat.contains('smartphones')) {
        return text.contains('phone') ||
            text.contains('iphone') ||
            text.contains('samsung') ||
            text.contains('xiaomi');
      }

      if (cat.contains('gaming')) {
        return text.contains('gaming') ||
            text.contains('ps5') ||
            text.contains('xbox') ||
            text.contains('game');
      }

      if (cat.contains('moda')) {
        return text.contains('fashion') ||
            text.contains('ropa') ||
            text.contains('clothing') ||
            text.contains('shirt') ||
            text.contains('dress') ||
            text.contains('shoes') ||
            text.contains('sneakers');
      }

      if (cat.contains('hogar') || cat.contains('cocina')) {
        return text.contains('home') ||
            text.contains('kitchen') ||
            text.contains('furniture') ||
            text.contains('decor');
      }

      if (cat.contains('deportes') || cat.contains('fitness')) {
        return text.contains('sport') ||
            text.contains('fitness') ||
            text.contains('gym');
      }

      if (cat.contains('mascotas')) {
        return text.contains('pet') ||
            text.contains('dog') ||
            text.contains('cat');
      }

      return p.category.toLowerCase().contains(cat);
    }

    final filtered = products.where((p) {
      final text = '${p.name} ${p.store} ${p.category} ${p.description}'
          .toLowerCase();

      final matchesSearch = q.isEmpty || text.contains(q);
      final matchesCategory = matchCategory(p);

      bool matchesType = true;

      if (selectedOfferType == 1) {
        matchesType = p.isOnline;
      }

      if (selectedOfferType == 2) {
        matchesType = !p.isOnline;
      }

      return matchesSearch && matchesCategory && matchesType;
    }).toList();

    if (selectedOfferType == 2 &&
        _currentUserPosition != null &&
        filtered.isNotEmpty) {
      filtered.sort((a, b) {
        if (a.lat == 0.0 || a.lng == 0.0) return 1;
        if (b.lat == 0.0 || b.lng == 0.0) return -1;

        final distA = Geolocator.distanceBetween(
          _currentUserPosition!.latitude,
          _currentUserPosition!.longitude,
          a.lat,
          a.lng,
        );

        final distB = Geolocator.distanceBetween(
          _currentUserPosition!.latitude,
          _currentUserPosition!.longitude,
          b.lat,
          b.lng,
        );

        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  void openProduct(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          product: p,
          allProducts: allProducts,
          isFavorite: widget.favoriteIds.contains(p.id),
          onFavorite: () {
            widget.onFavorite(p.id);
          },
        ),
      ),
    );
  }

  void openAiAssistant() {
    final productsForAI = filterProducts(allProducts);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIAssistantScreen(
          userPosition: _currentUserPosition,
          products: productsForAI.isEmpty ? allProducts : productsForAI,
          userCountry: currentCountry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);
    final cardColor = isDark ? AppColors.card : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    final products = filterProducts(allProducts);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: loadingFirst
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : RefreshIndicator(
                onRefresh: refreshProducts,
                color: AppColors.orange,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ofertix',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AI-powered deal hunter',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor),
                        onSubmitted: _saveRecentSearch,
                        onChanged: (v) {
                          if (searchDebounce?.isActive ?? false) {
                            searchDebounce!.cancel();
                          }

                          searchDebounce = Timer(
                            const Duration(milliseconds: 300),
                            () {
                              setState(() {
                                query = v;
                              });
                            },
                          );
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: subTextColor),
                          icon: Icon(Icons.search_rounded, color: subTextColor),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(0, "Todo", Icons.all_inclusive_rounded),
                          _buildTypeTab(1, "Online", Icons.language_rounded),
                          _buildTypeTab(
                            2,
                            "Tiendas",
                            Icons.location_on_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (query.trim().isEmpty) ...[
                      if (recentSearches.isNotEmpty) ...[
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentSearches.length,
                            itemBuilder: (context, index) {
                              final item = recentSearches[index];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    query = item;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.history_rounded,
                                        size: 16,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      GestureDetector(
                        onTap: openAiAssistant,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffFF9800), Color(0xffFF5722)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Prueba nuestro Radar IA!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Encuentra chollos brutales con el buscador inteligente.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],

                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final active = selectedCategory == category;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: active ? AppColors.orange : cardColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: active ? Colors.white : textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 26),

                    Row(
                      children: [
                        Text(
                          'Products',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              gridMode = !gridMode;
                            });
                          },
                          icon: Icon(
                            gridMode
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            color: AppColors.orange,
                          ),
                        ),
                        Text(
                          '${products.length}/$totalCount',
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      ),

                    if (gridMode)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.64,
                            ),
                        itemBuilder: (context, index) {
                          final p = products[index];

                          return ProductGridCard(
                            product: p,
                            isFavorite: widget.favoriteIds.contains(p.id),
                            userPosition: _currentUserPosition,
                            onFavorite: () {
                              widget.onFavorite(p.id);
                            },
                            onTap: () {
                              openProduct(p);
                            },
                          );
                        },
                      )
                    else
                      ...products.map((p) {
                        return ProductCard(
                          product: p,
                          isFavorite: widget.favoriteIds.contains(p.id),
                          userPosition: _currentUserPosition,
                          onFavorite: () {
                            widget.onFavorite(p.id);
                          },
                          onTap: () {
                            openProduct(p);
                          },
                        );
                      }),

                    if (loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                          ),
                        ),
                      ),

                    if (!hasMore && query.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No more products',
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

  Widget _buildTypeTab(int index, String label, IconData icon) {
    final isSelected = selectedOfferType == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedOfferType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
