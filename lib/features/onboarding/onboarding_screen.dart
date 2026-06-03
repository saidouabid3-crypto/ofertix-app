import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'onboarding_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),

      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: provider.controller,

                      onPageChanged: provider.updatePage,

                      children: const [
                        _Page(
                          icon: Icons.psychology,

                          title: 'AI Shopping',

                          subtitle:
                              'Find the best deals with artificial intelligence.',
                        ),

                        _Page(
                          icon: Icons.travel_explore,

                          title: 'Worldwide Deals',

                          subtitle:
                              'Discover offers from local and global stores.',
                        ),

                        _Page(
                          icon: Icons.notifications_active,

                          title: 'Smart Alerts',

                          subtitle: 'Get notified instantly when prices drop.',
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),

                    child: Row(
                      children: [
                        Row(
                          children: List.generate(3, (index) {
                            final active = provider.currentPage == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),

                              margin: const EdgeInsets.only(right: 8),

                              width: active ? 28 : 10,

                              height: 10,

                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.orange
                                    : Colors.white24,

                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                        ),

                        const Spacer(),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,

                              vertical: 14,
                            ),
                          ),

                          onPressed: () async {
                            if (provider.currentPage < 2) {
                              provider.nextPage();

                              return;
                            }

                            await provider.finish();

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pushReplacementNamed(
                              context,
                              '/country-selection',
                            );
                          },

                          child: Text(
                            provider.currentPage == 2 ? 'Start' : 'Next',
                          ),
                        ),
                      ],
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

class _Page extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  const _Page({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: 160,
            height: 160,

            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, size: 80, color: AppColors.orange),
          ),

          const SizedBox(height: 50),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 30,

              fontWeight: FontWeight.w900,

              color: Colors.white,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            subtitle,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 16,

              height: 1.5,

              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}
