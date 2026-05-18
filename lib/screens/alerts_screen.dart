import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Alerts',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.orange,
                    size: 42,
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    child: Text(
                      'You will receive smart alerts when prices drop.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
