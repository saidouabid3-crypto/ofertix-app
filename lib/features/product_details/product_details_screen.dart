import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool isFavorite = false;

  Future<void> openLink() async {
    final url = Uri.parse(widget.product.affiliateUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final hasDiscount =
        product.discount > 0 && product.oldPrice > product.newPrice;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: CustomScrollView(
        slivers: [
          /// APP BAR
          SliverAppBar(
            expandedHeight: 420,

            pinned: true,

            backgroundColor: AppColors.background,

            leading: IconButton(
              onPressed: () => Navigator.pop(context),

              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,

                color: Colors.white,
              ),
            ),

            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });
                },

                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,

                  color: isFavorite ? AppColors.red : Colors.white,
                ),
              ),

              const SizedBox(width: 8),
            ],

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,

                children: [
                  Hero(
                    tag: product.id,

                    child: Image.network(
                      product.image,

                      fit: BoxFit.cover,

                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.card,

                        child: const Icon(
                          Icons.image_not_supported_rounded,

                          color: Colors.white54,

                          size: 80,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,

                        end: Alignment.bottomCenter,

                        colors: [
                          Colors.transparent,

                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),

                  if (hasDiscount)
                    Positioned(
                      top: 110,
                      left: 20,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.green,

                          borderRadius: BorderRadius.circular(99),
                        ),

                        child: Text(
                          '-${product.discount}% OFF',

                          style: const TextStyle(
                            color: Colors.white,

                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    bottom: 28,
                    left: 22,
                    right: 22,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.18),

                            borderRadius: BorderRadius.circular(999),
                          ),

                          child: const Text(
                            '🧠 AI VERIFIED DEAL',

                            style: TextStyle(
                              color: AppColors.orange,

                              fontWeight: FontWeight.w900,

                              fontSize: 11,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          product.name,

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 34,

                            fontWeight: FontWeight.w900,

                            height: 1.1,

                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          product.store.toUpperCase(),

                          style: const TextStyle(
                            color: AppColors.gray,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// PRICE
                  Row(
                    children: [
                      Text(
                        '${product.newPrice.toStringAsFixed(2)}€',

                        style: const TextStyle(
                          color: AppColors.orange,

                          fontSize: 42,

                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(width: 12),

                      if (hasDiscount)
                        Text(
                          '${product.oldPrice.toStringAsFixed(2)}€',

                          style: const TextStyle(
                            color: AppColors.gray,

                            fontSize: 18,

                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.14),

                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: const Text(
                          'HOT DEAL',

                          style: TextStyle(
                            color: AppColors.green,

                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// AI ANALYSIS
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: AppColors.card,

                      borderRadius: BorderRadius.circular(30),

                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.psychology_alt_rounded,

                              color: AppColors.orange,

                              size: 34,
                            ),

                            SizedBox(width: 12),

                            Text(
                              'AI Analysis',

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 24,

                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _analysisItem(
                          '🔥 Great price compared to market average.',
                        ),

                        _analysisItem('📈 Trending product this week.'),

                        _analysisItem(
                          '💸 Cashback available on selected stores.',
                        ),

                        _analysisItem('⚡ Limited stock detected.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// STATS
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          '4.9',
                          'Rating',
                          Icons.star,
                          AppColors.orange,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _statCard(
                          '92%',
                          'Hot Score',
                          Icons.local_fire_department_rounded,
                          AppColors.red,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _statCard(
                          '12%',
                          'Cashback',
                          Icons.payments_rounded,
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// DESCRIPTION
                  const Text(
                    'Description',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 28,

                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Smart AI powered product recommendation selected from multiple stores and marketplaces. Optimized for best value, price and popularity.',

                    style: TextStyle(
                      color: AppColors.gray,

                      fontSize: 15,

                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 38),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 18),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),

                          onPressed: openLink,

                          icon: const Icon(Icons.shopping_bag_rounded),

                          label: const Text(
                            'Buy Now',

                            style: TextStyle(
                              fontWeight: FontWeight.w900,

                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,

                          borderRadius: BorderRadius.circular(22),
                        ),

                        child: IconButton(
                          onPressed: () {},

                          icon: const Icon(
                            Icons.share_rounded,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),

            child: Icon(
              Icons.check_circle_rounded,

              color: AppColors.green,

              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,

              style: const TextStyle(
                color: AppColors.gray,

                height: 1.5,

                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 24,

              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,

            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
