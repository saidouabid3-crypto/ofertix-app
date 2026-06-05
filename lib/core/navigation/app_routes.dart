class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String countrySelection = '/country-selection';
  static const String home = '/home';

  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';

  static const String search = '/search';
  static const String deals = '/deals';
  static const String dealFeed = '/deal-feed';
  static const String sell = '/sell';

  static const String aiAssistant = '/ai-assistant';
  static const String favorites = '/favorites';
  static const String watchlist = '/watchlist';
  static const String alerts = '/alerts';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String rewards = '/rewards';
  static const String cashback = '/cashback';
  static const String trending = '/trending';
  static const String scan = '/scan';
  static const String visualSearch = '/visual-search';
  static const String voiceSearch = '/voice-search';

  static const String coupons = '/coupons';
  static const String communityDeals = '/community-deals';
  static const String geoAlerts = '/geo-alerts';
  static const String aiDealBrain = '/ai-deal-brain';
  static const String mysteryBox = '/mystery-box';

  static const String localNearby = '/local/nearby';
  static const String localStore = '/local/store';
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantAddStore = '/merchant/add-store';
  static const String merchantAddOffer = '/merchant/add-offer';
  static const String adminLocalReview = '/admin/local-review';
  static const String adminCommandCenter = '/admin/command-center';

  static const String notifications = '/notifications';

  /// Deep link: `/product/{id}`
  static const String product = '/product';
  static String productById(String id) => '$product/$id';
}
