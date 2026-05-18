import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/product_grid_card.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  final Set<String> favoriteIds;
  final void Function(String) onFavorite;

  const SearchScreen({
    super.key,
    required this.favoriteIds,
    required this.onFavorite,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  String selectedStore = 'All';
  String selectedCategory = 'All';
  String country = 'ES';

  final List<String> mainCategories = [
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
    'Deals',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    loadCountry();
  }

  Future<void> loadCountry() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      country = prefs.getString('country') ?? 'ES';
    });
  }

  bool matchesCountry(Product product) {
    if (country == 'ES') {
      return product.category.isNotEmpty;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Firebase error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final allProducts = (snapshot.data?.docs ?? [])
              .map((doc) {
                return Product.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              })
              .where(matchesCountry)
              .toList();

          final stores = [
            'All',
            ...allProducts
                .map((p) => p.store)
                .where((s) => s.trim().isNotEmpty)
                .toSet(),
          ];

          final firebaseCategories = allProducts
              .map((p) => p.category)
              .where((c) => c.trim().isNotEmpty)
              .toSet()
              .toList();

          final categories = [
            ...mainCategories,
            ...firebaseCategories.where((c) => !mainCategories.contains(c)),
          ];

          final products = allProducts.where((p) {
            final q = query.trim().toLowerCase();

            final matchesQuery =
                q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.store.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q);

            final matchesStore =
                selectedStore == 'All' || p.store == selectedStore;

            final matchesCategory =
                selectedCategory == 'All' || p.category == selectedCategory;

            return matchesQuery && matchesStore && matchesCategory;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const Text(
                'Search',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 6),

              const Text(
                'Find products, stores and deals',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
              ),

              const SizedBox(height: 18),

              TextField(
                onChanged: (value) {
                  setState(() {
                    query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'iPhone, PS5, aceite, Nike...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Stores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: stores.map((store) {
                    final selected = selectedStore == store;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(store),
                        selected: selected,
                        selectedColor: AppColors.orange,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedStore = store;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories.map((category) {
                    final selected = selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        selectedColor: AppColors.orange,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Text(
                    '${products.length} results',
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (query.isNotEmpty ||
                      selectedStore != 'All' ||
                      selectedCategory != 'All')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          query = '';
                          selectedStore = 'All';
                          selectedCategory = 'All';
                        });
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  ),
                ),

              ...products.map((p) {
                return ProductGridCard(
                  product: p,
                  isFavorite: widget.favoriteIds.contains(p.id),
                  onFavorite: () => widget.onFavorite(p.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(
                          product: p,
                          isFavorite: widget.favoriteIds.contains(p.id),
                          onFavorite: () => widget.onFavorite(p.id),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
