import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const DetailsScreen({
    super.key,
    required this.product,
    this.allProducts = const [],
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late bool favorite;
  late int hoursLeft;

  @override
  void initState() {
    super.initState();
    favorite = widget.isFavorite;
    hoursLeft = Random().nextInt(20) + 1;
  }

  void toggle() {
    widget.onFavorite();
    setState(() => favorite = !favorite);
  }

  Future<void> openDeal([Product? product]) async {
    final p = product ?? widget.product;
    final url = p.affiliateUrl.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay enlace disponible')));
      return;
    }

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  List<Product> getRecommendations() {
    final current = widget.product;
    final all = widget.allProducts;

    if (all.isEmpty) return [];

    final currentName = current.name.toLowerCase();
    final currentCategory = current.category.toLowerCase();
    final currentStore = current.store.toLowerCase();

    final scored = <MapEntry<Product, int>>[];

    for (final p in all) {
      if (p.id == current.id) continue;

      int score = 0;

      final name = p.name.toLowerCase();
      final category = p.category.toLowerCase();
      final store = p.store.toLowerCase();

      if (category == currentCategory) score += 30;
      if (store == currentStore) score += 8;

      if (currentName.contains('iphone') || currentName.contains('apple')) {
        if (name.contains('airpod')) score += 60;
        if (name.contains('cargador') || name.contains('charger')) score += 50;
        if (name.contains('case') || name.contains('funda')) score += 50;
        if (name.contains('cable')) score += 40;
        if (name.contains('powerbank') || name.contains('power bank')) {
          score += 40;
        }
        if (name.contains('iphone')) score += 30;
        if (category.contains('smartphone')) score += 20;
      }

      if (currentCategory.contains('smartphone')) {
        if (name.contains('cargador') ||
            name.contains('charger') ||
            name.contains('cable') ||
            name.contains('funda') ||
            name.contains('case') ||
            name.contains('airpod') ||
            name.contains('auriculares')) {
          score += 45;
        }
      }

      if (currentCategory.contains('tv')) {
        if (name.contains('soundbar') ||
            name.contains('barra') ||
            name.contains('hdmi') ||
            name.contains('auriculares') ||
            name.contains('altavoz')) {
          score += 45;
        }
      }

      if (currentCategory.contains('pc') ||
          currentCategory.contains('laptop')) {
        if (name.contains('mouse') ||
            name.contains('ratón') ||
            name.contains('teclado') ||
            name.contains('monitor') ||
            name.contains('ssd') ||
            name.contains('ram')) {
          score += 45;
        }
      }

      if (score > 0) scored.add(MapEntry(p, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final recommendations = scored.map((e) => e.key).take(8).toList();

    if (recommendations.length < 4) {
      final extra = all
          .where((p) => p.id != current.id && !recommendations.contains(p))
          .take(8 - recommendations.length)
          .toList();

      recommendations.addAll(extra);
    }

    return recommendations;
  }

  void openRecommendation(Product p) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          product: p,
          allProducts: widget.allProducts,
          isFavorite: false,
          onFavorite: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasDiscount = p.oldPrice > p.newPrice && p.discount > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);
    final cardColor = isDark ? AppColors.card : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    final recommendations = getRecommendations();

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 340,
                child: Stack(
                  children: [
                    Hero(
                      tag: p.id,
                      child: Image.network(
                        p.image,
                        width: double.infinity,
                        height: 340,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark ? AppColors.card2 : Colors.white,
                        ),
                      ),
                    ),

                    Container(
                      height: 340,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, bgColor],
                        ),
                      ),
                    ),

                    if (hasDiscount)
                      Positioned(
                        left: 18,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '-${p.discount}% DESCUENTO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Text(
                          '${p.newPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontSize: 34,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${p.oldPrice.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 18,
                              color: subTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.red,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Only today',
                                style: TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '⏰ Ends in ${hoursLeft}h',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _InfoRow(
                      icon: Icons.store_rounded,
                      title: 'Tienda',
                      value: p.store,
                    ),
                    _InfoRow(
                      icon: Icons.category_rounded,
                      title: 'Categoría',
                      value: p.category,
                    ),
                    _InfoRow(
                      icon: Icons.timer_rounded,
                      title: 'Deal ends',
                      value: '⏰ Ends in ${hoursLeft}h',
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Descripción',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      p.description.isEmpty ? p.name : p.description,
                      style: TextStyle(color: subTextColor, height: 1.5),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: () => openDeal(),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text(
                                'Get Deal',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          height: 56,
                          width: 64,
                          child: FilledButton(
                            onPressed: toggle,
                            style: FilledButton.styleFrom(
                              backgroundColor: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Icon(
                              favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favorite
                                  ? AppColors.red
                                  : (isDark ? AppColors.white : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (recommendations.isNotEmpty) ...[
                      const SizedBox(height: 34),

                      Row(
                        children: [
                          Text(
                            'Recommended for you',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'AI Picks',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final item = recommendations[index];

                            return _RecommendationCard(
                              product: item,
                              onTap: () => openRecommendation(item),
                              onDealTap: () => openDeal(item),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDealTap;

  const _RecommendationCard({
    required this.product,
    required this.onTap,
    required this.onDealTap,
  });

  bool get hasDiscount =>
      product.discount > 0 && product.oldPrice > product.newPrice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.card : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Image.network(
                    product.image,
                    height: 105,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 105,
                      color: isDark ? AppColors.card2 : const Color(0xFFF1F1F1),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ),

                if (hasDiscount)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '-${product.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧠 AI Match',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product.store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${product.newPrice.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: FilledButton(
                      onPressed: onDealTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Get Deal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.card : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: subTextColor)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
