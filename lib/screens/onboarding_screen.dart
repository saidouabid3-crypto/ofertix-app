import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    (
      'Encuentra ofertas reales',
      'Compara precios de supermercados y tiendas cerca de ti.',
      Icons.search_rounded,
    ),
    (
      'Guarda tus favoritos',
      'No pierdas las mejores promociones y vuelve a ellas cuando quieras.',
      Icons.favorite_rounded,
    ),
    (
      'Alertas de precio',
      'Recibe aviso cuando un producto baje de precio.',
      Icons.notifications_active_rounded,
    ),
  ];

  void goNext() {
    if (index == pages.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 28),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(.15),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(p.$3, size: 72, color: AppColors.orange),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        p.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        p.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.gray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == i ? AppColors.orange : AppColors.card2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: goNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  index == pages.length - 1 ? 'Empezar' : 'Siguiente',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
