import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final Set<String> favoriteIds;
  final void Function(String) onFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteIds,
    required this.onFavorite,
  });

  Product productFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, doc.id);
  }

  @override
  Widget build(BuildContext context) {
    if (favoriteIds.isEmpty) {
      return const SafeArea(
        child: Center(child: Text('Aún no tienes favoritos')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          );
        }

        if (snapshot.hasError) {
          return SafeArea(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final products = snapshot.data!.docs
            .map(productFromDoc)
            .where((p) => favoriteIds.contains(p.id))
            .toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            children: [
              const Text(
                'Favoritos',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),

              if (products.isEmpty)
                const Center(child: Text('Aún no tienes favoritos')),

              ...products.map(
                (p) => ProductCard(
                  product: p,
                  isFavorite: true,
                  onFavorite: () => onFavorite(p.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(
                          product: p,
                          isFavorite: true,
                          onFavorite: () => onFavorite(p.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
