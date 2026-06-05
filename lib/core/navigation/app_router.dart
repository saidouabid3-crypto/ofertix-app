import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/country_selection/country_selection_screen.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

import '../../features/search/search_screen.dart';
import '../../features/deals/deals_screen.dart';
import '../../features/smart_reels/smart_reels_screen.dart';
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
import '../../features/sell/sell_screen.dart';
import '../../features/visual_search/visual_search_screen.dart';
import '../../features/voice_search/voice_search_screen.dart';

import '../../features/coupons/coupons_screen.dart';
import '../../features/community/user_generated_deals_screen.dart';
import '../../features/geo_alerts/geo_alerts_screen.dart';
import '../../features/ai_brain/ai_deal_brain_screen.dart';
import '../../features/mystery_box/mystery_box_screen.dart';
import '../../features/local/nearby_offers_screen.dart';
import '../../features/local/store_details_screen.dart';
import '../../features/local/merchant_dashboard_screen.dart';
import '../../features/local/create_store_screen.dart';
import '../../features/local/create_offer_screen.dart';
import '../../features/local/admin_offer_review_screen.dart';
import '../../features/admin/admin_command_center_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/product_details/product_details_loader_screen.dart';

import 'app_routes.dart';
import 'app_shell.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(SplashScreen());
      case AppRoutes.onboarding:
        return _page(OnboardingScreen());
      case AppRoutes.countrySelection:
        return _page(CountrySelectionScreen());
      case AppRoutes.home:
        return _page(AppShell());

      case AppRoutes.auth:
        return _page(AuthScreen());
      case AppRoutes.login:
        return _page(LoginScreen());
      case AppRoutes.register:
        return _page(RegisterScreen());

      case AppRoutes.search:
        return _page(SearchScreen());
      case AppRoutes.deals:
        return _page(DealsScreen());
      case AppRoutes.dealFeed:
        return _page(
          SmartReelsScreen(baseUrl: ApiConfig.baseUrl),
        );
      case AppRoutes.sell:
        return _page(SellScreen());

      case AppRoutes.aiAssistant:
        return _page(AIAssistantScreen());
      case AppRoutes.favorites:
        return _page(FavoritesScreen());
      case AppRoutes.watchlist:
        return _page(
          WatchlistScreen(productIds: const {}, onToggleWatch: (_) {}),
        );
      case AppRoutes.alerts:
        return _page(AlertsScreen());
      case AppRoutes.profile:
        return _page(ProfileScreen());
      case AppRoutes.settings:
        return _page(SettingsScreen());
      case AppRoutes.rewards:
        return _page(RewardsScreen());
      case AppRoutes.cashback:
        return _page(CashbackScreen());
      case AppRoutes.trending:
        return _page(TrendingScreen());
      case AppRoutes.scan:
        return _page(ScanScreen());
      case AppRoutes.visualSearch:
        return _page(VisualSearchScreen());
      case AppRoutes.voiceSearch:
        return _page(VoiceSearchScreen());

      case AppRoutes.coupons:
        return _page(CouponsScreen());
      case AppRoutes.communityDeals:
        return _page(UserGeneratedDealsScreen());
      case AppRoutes.geoAlerts:
        return _page(GeoAlertsScreen());
      case AppRoutes.aiDealBrain:
        return _page(AIDealBrainScreen());
      case AppRoutes.mysteryBox:
        return _page(MysteryBoxScreen());

      case AppRoutes.localNearby:
        return _page(const NearbyOffersScreen());
      case AppRoutes.localStore:
        final storeId = settings.arguments is String ? settings.arguments as String : '';
        return _page(StoreDetailsScreen(storeId: storeId));
      case AppRoutes.merchantDashboard:
        return _page(const MerchantDashboardScreen());
      case AppRoutes.merchantAddStore:
        return _page(const CreateStoreScreen());
      case AppRoutes.merchantAddOffer:
        return _page(const CreateOfferScreen());
      case AppRoutes.adminLocalReview:
        return _page(const AdminOfferReviewScreen());
      case AppRoutes.adminCommandCenter:
        return _page(const AdminCommandCenterScreen());

      case AppRoutes.notifications:
        return _page(const NotificationCenterScreen());

      default:
        if (settings.name != null && settings.name!.startsWith('${AppRoutes.product}/')) {
          final productId = settings.name!.replaceFirst('${AppRoutes.product}/', '');
          if (productId.isNotEmpty) {
            return _page(ProductDetailsLoaderScreen(productId: productId));
          }
        }
        return _page(SplashScreen());
    }
  }

  static PageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}
