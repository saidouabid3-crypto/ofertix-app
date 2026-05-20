import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';
import 'ai_assistant_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController controller = TextEditingController();

  final List<String> prompts = const [
    'Best iPhone deals under 500€',
    'Gaming setup offers',
    'Cheap AirPods alternatives',
    'Home products with discount',
    'AliExpress hot deals',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void search(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    context.read<AIAssistantProvider>().search(text);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIAssistantProvider(),
      child: Consumer<AIAssistantProvider>(
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
                                color: AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'AI MODE',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.orange.withValues(alpha: 0.95),
                                const Color(0xFF7C3AED),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withValues(alpha: 0.28),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.psychology_alt_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Ask Ofertix AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tell me what you want. I will find the smartest deals for you.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.orange.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(color: Colors.white),
                                  onSubmitted: (value) =>
                                      search(context, value),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Example: best smartwatch under 80€',
                                    hintStyle: TextStyle(color: AppColors.gray),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    search(context, controller.text),
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: prompts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  controller.text = prompts[index];
                                  search(context, prompts[index]);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card2,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    prompts[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            const Text(
                              'AI Results',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
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

                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.orange,
                        ),
                      ),
                    )
                  else if (provider.results.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'Ask AI to find your next deal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final Product product = provider.results[index];

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
