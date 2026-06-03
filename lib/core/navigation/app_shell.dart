import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../widgets/bottom_nav.dart';

import '../../features/home/home_screen.dart';

import '../../features/ai_assistant/ai_assistant_screen.dart';

import '../../features/scan/scan_screen.dart';

import '../../features/sell/sell_screen.dart';

import '../../features/smart_reels/smart_reels_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(),
      const ScanScreen(),
      SmartReelsScreen(
        baseUrl: ApiConfig.baseUrl,
        isVisible: currentIndex == 2,
      ),
      SellScreen(),
      AIAssistantScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
