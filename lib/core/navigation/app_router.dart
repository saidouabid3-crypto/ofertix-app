import 'package:flutter/material.dart';

import '../../features/splash/splash_screen.dart';

import '../../features/onboarding/onboarding_screen.dart';

import '../../features/country_selection/country_selection_screen.dart';

import '../../features/home/home_screen.dart';

import '../../features/search/search_screen.dart';

import '../../features/deals/deals_screen.dart';

import '../../features/ai_assistant/ai_assistant_screen.dart';

import '../../features/favorites/favorites_screen.dart';

import '../../features/watchlist/watchlist_screen.dart';

import '../../features/alerts/alerts_screen.dart';

import '../../features/profile/profile_screen.dart';

import '../../features/settings/settings_screen.dart';

import '../../features/rewards/rewards_screen.dart';

import '../../features/cashback/cashback_screen.dart';

import '../../features/trending/trending_screen.dart';

import '../../features/scan/scan_screen.dart';

import '../../features/visual_search/visual_search_screen.dart';

import '../../features/voice_search/voice_search_screen.dart';

import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen());

      case AppRoutes.onboarding:
        return _page(const OnboardingScreen());

      case AppRoutes.countrySelection:
        return _page(const CountrySelectionScreen());

      case AppRoutes.home:
        return _page(const HomeScreen());

      case AppRoutes.search:
        return _page(const SearchScreen());

      case AppRoutes.deals:
        return _page(const DealsScreen());

      case AppRoutes.aiAssistant:
        return _page(const AIAssistantScreen());

      case AppRoutes.favorites:
        return _page(
          FavoritesScreen(favoriteIds: const {}, onFavorite: (_) {}),
        );

      case AppRoutes.watchlist:
        return _page(
          WatchlistScreen(productIds: const {}, onToggleWatch: (_) {}),
        );

      case AppRoutes.alerts:
        return _page(const AlertsScreen());

      case AppRoutes.profile:
        return _page(const ProfileScreen());

      case AppRoutes.settings:
        return _page(const SettingsScreen());

      case AppRoutes.rewards:
        return _page(const RewardsScreen());

      case AppRoutes.cashback:
        return _page(const CashbackScreen());

      case AppRoutes.trending:
        return _page(const TrendingScreen());

      case AppRoutes.scan:
        return _page(const ScanScreen());

      case AppRoutes.visualSearch:
        return _page(const VisualSearchScreen());

      case AppRoutes.voiceSearch:
        return _page(const VoiceSearchScreen());

      default:
        return _page(const SplashScreen());
    }
  }

  static PageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
