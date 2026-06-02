import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';
import '../../models/product.dart';
import '../../models/ofertix_ad_model.dart';
import '../../widgets/daily_ai_hunt_section.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/ofertix_ad_slot.dart';
import '../product_details/product_details_screen.dart';
import '../search/search_screen.dart';
import 'home_provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> openProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }

  void openSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
  }

  void openCategory(HomeCategory category, List<Product> products) {
    final categoryProducts = products.where(category.matches).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialCategory: category.key,
          initialCategoryLabel: category.labelKey.tr(),
          initialQuery: category.query,
          initialResults: categoryProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeProvider>(
      create: (_) => HomeProvider()..initialize(),
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final products = provider.products;

          final hotProducts = provider.hotProducts.isNotEmpty
              ? provider.hotProducts.take(8).toList()
              : products.where((p) => p.isHot || p.isTrending).take(8).toList();

          final onlineProducts = provider.onlineProducts.isNotEmpty
              ? provider.onlineProducts.take(8).toList()
              : products.take(8).toList();

          final trendingProducts = provider.featuredProducts.isNotEmpty
              ? provider.featuredProducts.take(8).toList()
              : products
                    .where((p) => p.featured || p.sponsored)
                    .take(8)
                    .toList();

          return Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.orange,
                onRefresh: provider.initialize,
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 112),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _Header(
                            onAlerts: () =>
                                Navigator.pushNamed(context, '/alerts'),
                            onProfile: () =>
                                Navigator.pushNamed(context, '/profile'),
                          ),
                          SizedBox(height: 14),

                          _CleanSearchBar(
                            controller: searchController,
                            onTap: openSearch,
                            onSubmitted: (_) => openSearch(),
                          ),

                          SizedBox(height: 14),

                          _CategoryCirclesRow(
                            onCategoryTap: (category) =>
                                openCategory(category, products),
                          ),

                          SizedBox(height: 14),

                          _HeroBanner(
                            isLoading: provider.isLoading,
                            productCount: products.length,
                            onViewDeals: () =>
                                Navigator.pushNamed(context, '/deals'),
                          ),

                          SizedBox(height: 14),

                          _QuickActions(
                            onBlindBox: () =>
                                Navigator.pushNamed(context, '/mystery-box'),
                            onHot: () =>
                                Navigator.pushNamed(context, '/trending'),
                            onAiBrain: () =>
                                Navigator.pushNamed(context, '/ai-deal-brain'),
                            onNearMe: () => Navigator.pushNamed(
                              context,
                              AppRoutes.localNearby,
                            ),
                            onRadar: () => Navigator.pushNamed(
                              context,
                              AppRoutes.localNearby,
                            ),
                          ),

                          SizedBox(height: 14),

                          OfertixAdSlot(
                            placement: OfertixAdPlacement.homeTop,
                            fallback: _AdSlot(),
                          ),

                          SizedBox(height: 20),

                          _SectionHeader(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.redOrange,
                            title: 'home.hotDeals'.tr(),
                            action: 'common.viewAll'.tr(),
                            onTap: () => Navigator.pushNamed(context, '/deals'),
                          ),
                          SizedBox(height: 10),
                          provider.isLoading && hotProducts.isEmpty
                              ? _LoadingProducts()
                              : _HorizontalProducts(
                                  products: hotProducts,
                                  userPosition: provider.userPosition,
                                  emptyText: 'home.noHotDeals'.tr(),
                                  onProductTap: openProduct,
                                ),

                          SizedBox(height: 20),

                          _CashbackBanner(
                            onTap: () =>
                                Navigator.pushNamed(context, '/cashback'),
                          ),

                          SizedBox(height: 20),

                          const DailyAiHuntSection(),

                          SizedBox(height: 20),

                          _SectionHeader(
                            icon: Icons.public_rounded,
                            iconColor: AppColors.green,
                            title: 'home.globalOnline'.tr(),
                            action: 'common.viewAll'.tr(),
                            onTap: openSearch,
                          ),
                          SizedBox(height: 10),
                          provider.isLoading && onlineProducts.isEmpty
                              ? _LoadingProducts()
                              : _HorizontalProducts(
                                  products: onlineProducts,
                                  userPosition: provider.userPosition,
                                  emptyText: 'home.noOnlineDeals'.tr(),
                                  onProductTap: openProduct,
                                ),

                          SizedBox(height: 20),

                          _SectionHeader(
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.green,
                            title: 'home.trending'.tr(),
                            action: 'common.explore'.tr(),
                            onTap: () =>
                                Navigator.pushNamed(context, '/trending'),
                          ),
                          SizedBox(height: 10),

                          if (provider.isLoading && trendingProducts.isEmpty)
                            _LoadingGrid()
                          else if (trendingProducts.isEmpty)
                            _EmptyBox(text: 'home.noProducts'.tr())
                          else
                            _ProductGrid(
                              products: trendingProducts,
                              userPosition: provider.userPosition,
                              onProductTap: openProduct,
                            ),
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

// ============================================================
// ✅ HEADER - Logo + Ofertix + Bell + Profile
// ============================================================
class _Header extends StatelessWidget {
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  _Header({required this.onAlerts, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.20),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.local_offer_rounded, color: Colors.white, size: 23),
        ),
        SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ofertix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1E2022),
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'home.tagline'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF7C848E),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onAlerts,
          showDot: true,
        ),
        SizedBox(width: 9),
        GestureDetector(
          onTap: onProfile,
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Color(0xFFE7EBEF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                SizedBox(width: 7),
                Text(
                  'common.profile'.tr(),
                  style: TextStyle(
                    color: Color(0xFF1E2022),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFE7EBEF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Color(0xFF1E2022), size: 22),
          ),
          if (showDot)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ SEARCH BAR
// ============================================================
class _CleanSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged<String> onSubmitted;

  _CleanSearchBar({
    required this.controller,
    required this.onTap,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE6EAEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 14),
          Icon(Icons.search_rounded, color: Color(0xFF9AA1AA), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                'home.searchHint'.tr(),
                style: TextStyle(
                  color: Color(0xFF9AA1AA),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ PRODUCT CATEGORIES ROW - linked to product.category/categoryGroup
// ============================================================
class HomeCategory {
  final String key;
  final String labelKey;
  final String query;
  final IconData icon;
  final Color color;
  final List<String> aliases;

  const HomeCategory({
    required this.key,
    required this.labelKey,
    required this.query,
    required this.icon,
    required this.color,
    required this.aliases,
  });

  bool matches(Product product) {
    final haystack = [
      product.category,
      product.categoryGroup,
      product.name,
      product.fullTitle,
      product.description,
    ].join(' ').toLowerCase();

    return aliases.any((alias) => haystack.contains(alias.toLowerCase()));
  }
}

class _CategoryCirclesRow extends StatelessWidget {
  final ValueChanged<HomeCategory> onCategoryTap;

  const _CategoryCirclesRow({required this.onCategoryTap});

  static const List<HomeCategory> _categories = [
    HomeCategory(
      key: 'fashion',
      labelKey: 'categories.fashion',
      query: 'fashion moda ropa clothes shoes',
      icon: Icons.checkroom_rounded,
      color: Color(0xFFE11D48),
      aliases: ['fashion', 'moda', 'ropa', 'clothes', 'shoes', 'zapatos'],
    ),
    HomeCategory(
      key: 'electronics',
      labelKey: 'categories.electronics',
      query: 'electronics tecnologia gadgets',
      icon: Icons.devices_rounded,
      color: Color(0xFF2563EB),
      aliases: ['electronics', 'electronica', 'electrónica', 'tech', 'gadgets'],
    ),
    HomeCategory(
      key: 'cars',
      labelKey: 'categories.cars',
      query: 'cars coche auto car accessories',
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFF111827),
      aliases: ['cars', 'car', 'coche', 'auto', 'automovil', 'automóvil', 'vehicle'],
    ),
    HomeCategory(
      key: 'home',
      labelKey: 'categories.home',
      query: 'home casa hogar furniture',
      icon: Icons.home_rounded,
      color: Color(0xFFF97316),
      aliases: ['home', 'casa', 'hogar', 'furniture', 'muebles'],
    ),
    HomeCategory(
      key: 'beauty',
      labelKey: 'categories.beauty',
      query: 'beauty belleza skincare perfume',
      icon: Icons.spa_rounded,
      color: Color(0xFFDB2777),
      aliases: ['beauty', 'belleza', 'skincare', 'makeup', 'perfume', 'cosmetic'],
    ),
    HomeCategory(
      key: 'sports',
      labelKey: 'categories.sports',
      query: 'sports deporte fitness',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF16A34A),
      aliases: ['sports', 'sport', 'deporte', 'fitness', 'gym'],
    ),
    HomeCategory(
      key: 'kids',
      labelKey: 'categories.kids',
      query: 'kids niños juguetes baby',
      icon: Icons.child_care_rounded,
      color: Color(0xFF7C3AED),
      aliases: ['kids', 'niños', 'ninos', 'baby', 'bebé', 'bebe', 'toys', 'juguetes'],
    ),
    HomeCategory(
      key: 'gaming',
      labelKey: 'categories.gaming',
      query: 'gaming playstation xbox pc gamer',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF9333EA),
      aliases: ['gaming', 'gamer', 'playstation', 'xbox', 'nintendo', 'game'],
    ),
    HomeCategory(
      key: 'food',
      labelKey: 'categories.food',
      query: 'food comida supermercado',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEA580C),
      aliases: ['food', 'comida', 'restaurant', 'restaurante', 'supermarket'],
    ),
    HomeCategory(
      key: 'supermarket',
      labelKey: 'categories.supermarket',
      query: 'supermarket supermercado grocery',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFF059669),
      aliases: ['supermarket', 'supermercado', 'grocery', 'mercado'],
    ),
    HomeCategory(
      key: 'pharmacy',
      labelKey: 'categories.pharmacy',
      query: 'pharmacy farmacia health',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF0891B2),
      aliases: ['pharmacy', 'farmacia', 'health', 'salud'],
    ),
    HomeCategory(
      key: 'travel',
      labelKey: 'categories.travel',
      query: 'travel viajes hotel flight',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF0F766E),
      aliases: ['travel', 'viajes', 'hotel', 'flight', 'vuelo'],
    ),
    HomeCategory(
      key: 'tools',
      labelKey: 'categories.tools',
      query: 'tools herramientas bricolaje',
      icon: Icons.construction_rounded,
      color: Color(0xFFB45309),
      aliases: ['tools', 'herramientas', 'bricolaje', 'construction'],
    ),
    HomeCategory(
      key: 'phones',
      labelKey: 'categories.phones',
      query: 'phones mobile smartphone iphone samsung',
      icon: Icons.phone_iphone_rounded,
      color: Color(0xFF0284C7),
      aliases: ['phone', 'phones', 'mobile', 'smartphone', 'iphone', 'samsung'],
    ),
    HomeCategory(
      key: 'computers',
      labelKey: 'categories.computers',
      query: 'computers laptop pc portátil',
      icon: Icons.laptop_mac_rounded,
      color: Color(0xFF4F46E5),
      aliases: ['computer', 'computers', 'laptop', 'pc', 'portatil', 'portátil'],
    ),
    HomeCategory(
      key: 'pets',
      labelKey: 'categories.pets',
      query: 'pets mascotas animals',
      icon: Icons.pets_rounded,
      color: Color(0xFFCA8A04),
      aliases: ['pets', 'mascotas', 'pet', 'dog', 'cat', 'perro', 'gato'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'categories.title'.tr(),
                style: TextStyle(
                  color: Color(0xFF1E2022),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'common.explore'.tr(),
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = _categories[index];

              return GestureDetector(
                onTap: () => onCategoryTap(category),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: category.color.withValues(alpha: 0.28),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: category.color.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 25,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        category.labelKey.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1E2022),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ✅ HERO BANNER
// ============================================================
class _HeroBanner extends StatelessWidget {
  final bool isLoading;
  final int productCount;
  final VoidCallback onViewDeals;

  _HeroBanner({
    required this.isLoading,
    required this.productCount,
    required this.onViewDeals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00), Color(0xFFFF9500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5,
            top: -5,
            bottom: -5,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: 50,
            top: 10,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'home.exclusiveBadge'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'home.heroTitle'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: onViewDeals,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E2022),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.viewDeals'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ QUICK ACTIONS - 5 أيقونات
// ============================================================
class _QuickActions extends StatelessWidget {
  final VoidCallback onBlindBox;
  final VoidCallback onHot;
  final VoidCallback onAiBrain;
  final VoidCallback onNearMe;
  final VoidCallback onRadar;

  _QuickActions({
    required this.onBlindBox,
    required this.onHot,
    required this.onAiBrain,
    required this.onNearMe,
    required this.onRadar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionItem(
            label: 'home.blindBox'.tr(),
            icon: Icons.inventory_2_rounded,
            color: Color(0xFF6C63FF),
            onTap: onBlindBox,
          ),
          _ActionItem(
            label: 'home.hot'.tr(),
            icon: Icons.local_fire_department_rounded,
            color: Color(0xFFFF4500),
            onTap: onHot,
          ),
          _ActionItem(
            label: 'home.aiBrain'.tr(),
            icon: Icons.psychology_rounded,
            color: Color(0xFFFF6B9D),
            onTap: onAiBrain,
          ),
          _ActionItem(
            label: 'home.nearMe'.tr(),
            icon: Icons.location_on_rounded,
            color: Color(0xFF00C853),
            onTap: onNearMe,
          ),
          _ActionItem(
            label: 'local.radarTitle'.tr(),
            icon: Icons.radar_rounded,
            color: Color(0xFF2196F3),
            onTap: onRadar,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF1E2022),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ CASHBACK BANNER
// ============================================================
class _CashbackBanner extends StatelessWidget {
  final VoidCallback onTap;

  _CashbackBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFFFE0B2)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.confirmation_num_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extra Cashback.\nExtra Savings.',
                    style: TextStyle(
                      color: Color(0xFF1E2022),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Collect extra cashback on top deals & save more!',
                    style: TextStyle(
                      color: Color(0xFF7C848E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF1E2022),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Collect\nNow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ✅ WIDGETS الأخرى
// ============================================================

class _AdSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDCE1E6)),
      ),
      child: Row(
        children: [
          Text(
            'SPONSORED',
            style: TextStyle(
              color: Color(0xFF9AA1AA),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          Spacer(),
          Text(
            'Your ad here',
            style: TextStyle(
              color: Color(0xFF6E7580),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.open_in_new_rounded, color: Color(0xFF9AA1AA), size: 14),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String action;
  final VoidCallback onTap;

  _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Color(0xFF1E2022),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size(0, 34),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: iconColor, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  final List<Product> products;
  final dynamic userPosition;
  final String emptyText;
  final ValueChanged<Product> onProductTap;

  _HorizontalProducts({
    required this.products,
    required this.userPosition,
    required this.emptyText,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return _EmptyBox(text: emptyText);
    return SizedBox(
      height: 292,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 168,
            child: ProductGridCard(
              product: product,
              userPosition: userPosition,
              onTap: () => onProductTap(product),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final dynamic userPosition;
  final ValueChanged<Product> onProductTap;

  _ProductGrid({
    required this.products,
    required this.userPosition,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: products.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductGridCard(
          product: product,
          userPosition: userPosition,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}

class _LoadingProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 292,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(width: 168, child: _LoadingCard()),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.56,
      children: [
        _LoadingCard(),
        _LoadingCard(),
        _LoadingCard(),
        _LoadingCard(),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFE8ECEF)),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.orange,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE8ECEF)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF7C848E),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
