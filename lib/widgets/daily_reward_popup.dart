import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/coin_service.dart';

class DailyRewardPopup {
  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final lastClaim = prefs.getString('daily_reward');

    bool canClaim = true;

    if (lastClaim != null) {
      final lastDate = DateTime.parse(lastClaim);

      final now = DateTime.now();

      final difference = now.difference(lastDate).inHours;

      if (difference < 24) {
        canClaim = false;
      }
    }

    if (!canClaim) {
      return;
    }

    await CoinService.addCoins(10);

    await prefs.setString('daily_reward', DateTime.now().toIso8601String());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎁", style: TextStyle(fontSize: 60)),

              const SizedBox(height: 20),

              const Text(
                "Daily Reward",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "+10 Coins",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Awesome!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
