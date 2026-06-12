import 'api_config.dart';

/// Typed catalogue of every backend route the app talks to.
///
/// Keep every backend path here. Services must call [ApiService] with these
/// constants/functions instead of hardcoding strings, so language headers,
/// Render base URL, and route contracts stay unified across the whole app.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => ApiConfig.baseUrl;

  // --- Products -------------------------------------------------------------
  static const String products = '/products';
  static String productsList({String? country, int? limit, int? page}) =>
      _withQuery(products, {'country': country, 'limit': limit, 'page': page});
  static String productDetail(String productId) => '/product-detail/$productId';
  static String productDetailForCountry(String productId, String country) =>
      _withQuery(productDetail(productId), {'country': country});
  static String productDealVerdict(String productId, String country) =>
      _withQuery('/api/products/$productId/deal-verdict', {'country': country});

  // --- AI search / recommendations -----------------------------------------
  static const String aiChat = '/api/ai/chat';
  static const String aiSearch = '/api/ai/search';
  static const String aiSearchStream = '/api/ai/search/stream';
  static const String aiRecommendations = '/api/ai/recommendations';
  static const String aiAnalyzeProduct = '/api/ai/analyze-product';
  static const String aiAskBeforeBuying = '/api/ai/ask-before-buying';
  static const String aiDailyHunt = '/api/ai/daily-hunt';
  static const String aiCardVerdict = '/api/ai/card-verdict';

  // --- AI Deal Brain Pro ----------------------------------------------------
  static const String aiDealBrainExtractUrl = '/ai-deal-brain/extract-url';
  static const String aiDealBrainAnalyzeGlobal =
      '/ai-deal-brain/analyze-global';
  static const String aiDealBrainAnalyzeUrl = '/ai-deal-brain/analyze-url';
  static const String aiDealBrainNegotiate = '/ai-deal-brain/negotiate';

  // --- AI Deal Brain authenticated -----------------------------------------
  static const String aiBrainAnalyze = '/ai/brain/analyze';
  static const String aiBrainHistory = '/ai/brain/history';

  // --- Home feed / i18n / market -------------------------------------------
  static const String productSearch = '/api/products/search';
  static const String homeFeed = '/home-feed';
  static String homeFeedForCountry({
    required String country,
    int limit = 30,
    String? userId,
    String? variant,
    String? seenIds,
  }) => _withQuery(homeFeed, {
    'country': country,
    'limit': limit,
    'userId': userId,
    'variant': variant,
    'seenIds': seenIds,
  });

  static const String i18nCountries = '/i18n/countries';
  static const String i18nLanguages = '/i18n/languages';
  static const String market = '/market';
  static const String marketplace = '/marketplace';

  static const String marketplaceItems = '/marketplace/items';
  static String marketplaceItemsList({
    int? limit,
    String? city,
    String? category,
    String? country,
  }) => _withQuery(marketplaceItems, {
    'limit': limit,
    'city': city,
    'category': category,
    'country': country,
  });
  static String marketplaceItemFavorite(String itemId) =>
      '/marketplace/items/$itemId/favorite';
  static String marketplaceItemReport(String itemId) =>
      '/marketplace/items/$itemId/report';
  static const String marketplaceUploadImage = '/marketplace/upload-image';

  // --- Ofertix Local Engine -------------------------------------------------
  static const String localStores = '/api/local/stores';
  static const String localStoresNearby = '/api/local/stores/nearby';
  static String localStore(String storeId) => '/api/local/stores/$storeId';
  static String localStoreOffers(String storeId) =>
      '/api/local/stores/$storeId/offers';

  static const String localOffers = '/api/local/offers';
  static const String localOffersNearby = '/api/local/offers/nearby';
  static const String localOffersHot = '/api/local/offers/hot';
  static String localOffer(String offerId) => '/api/local/offers/$offerId';
  static String localOfferClick(String offerId) =>
      '/api/local/offers/$offerId/click';

  static const String merchantStores = '/api/merchant/stores';
  static const String merchantOffers = '/api/merchant/offers';
  static const String adminLocalOffersPending =
      '/api/admin/local/offers/pending';
  static String adminLocalOfferApprove(String offerId) =>
      '/api/admin/local/offers/$offerId/approve';
  static String adminLocalOfferReject(String offerId) =>
      '/api/admin/local/offers/$offerId/reject';

  // --- Events ---------------------------------------------------------------
  static const String eventProductView = '/events/product-view';
  static const String eventOfferClick = '/events/offer-click';
  static const String eventAiAsk = '/events/ai-ask';
  static const String eventReportProduct = '/events/report-product';

  // --- Ads ------------------------------------------------------------------
  static const String adsImpression = '/ads/impression';
  static const String adsClick = '/ads/click';
  static const String adsRevenueEstimate = '/ads/revenue/estimate';
  static String adsRevenueEstimateFor({
    required String slot,
    required int impressions,
    required double rpm,
  }) => _withQuery(adsRevenueEstimate, {
    'slot': slot,
    'impressions': impressions,
    'rpm': rpm,
  });

  // --- Community ------------------------------------------------------------
  static const String communityVote = '/community/vote';
  static const String communitySummary = '/community/summary';

  // --- Coupons --------------------------------------------------------------
  static const String coupons = '/coupons';
  static String couponVerify(String couponId) => '/coupons/$couponId/verify';

  // --- Geo alerts -----------------------------------------------------------
  static const String geoAlertsNearby = '/geo-alerts/nearby';

  // --- Mystery box ----------------------------------------------------------
  static const String mysteryBoxToday = '/mystery-box/today';
  static const String mysteryBoxOpen = '/mystery-box/open';
  static const String mysteryBoxClaim = '/mystery-box/claim';

  // --- User-generated deals -------------------------------------------------
  static const String userDeals = '/user-deals';

  // --- Smart reels ----------------------------------------------------------
  static const String smartReels = '/smart-reels';
  static const String smartReelsFeed = '/smart-reels/feed';
  static const String smartReelsUpload = '/smart-reels/upload';
  static String smartReel(String reelId) => '/smart-reels/$reelId';
  static String smartReelMessage(String reelId) =>
      '/smart-reels/$reelId/message';
  static String smartReelView(String reelId) => '/smart-reels/$reelId/view';
  static String smartReelClick(String reelId) => '/smart-reels/$reelId/click';
  static String smartReelLike(String reelId) => '/smart-reels/$reelId/like';
  static String smartReelSave(String reelId) => '/smart-reels/$reelId/save';
  static String smartReelReport(String reelId) => '/smart-reels/$reelId/report';
  static String smartReelComments(String reelId) =>
      '/smart-reels/$reelId/comments';
  static String smartReelCreatorFollow(String creatorId) =>
      '/smart-reels/creators/$creatorId/follow';
  static const String reelsUploadVideo = '/api/reels/upload-video';

  // --- Messages -------------------------------------------------------------
  static const String messagesInbox = '/messages/inbox';
  static const String messagesStart = '/messages/start';
  static String messageConversation(String conversationId) =>
      '/messages/conversations/$conversationId';
  static String messageConversationSend(String conversationId) =>
      '/messages/conversations/$conversationId/send';
  static String messageConversationRead(String conversationId) =>
      '/messages/conversations/$conversationId/read';

  // --- Profiles / admin / setup --------------------------------------------
  static const String profiles = '/profiles';
  static const String adminDashboard = '/admin/dashboard';
  static const String setupPublic = '/setup/public';
  static const String setupAdmin = '/setup/admin';

  // --- Scan -----------------------------------------------------------------
  static const String scan = '/api/scan';
  static const String scanProduct = '/api/scan/product';

  // --- Backward-compatible Uri getters -------------------------------------
  static Uri productsUri({String? countryCode, int? limit}) =>
      ApiConfig.uri(products, {'country': countryCode, 'limit': limit});

  static Uri get aiSearchUri => ApiConfig.uri(aiSearch);
  static Uri get scanUri => ApiConfig.uri(scan);

  static String _withQuery(String path, Map<String, dynamic> values) {
    final query = <String, String>{};
    values.forEach((key, value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isNotEmpty) query[key] = text;
    });
    if (query.isEmpty) return path;
    return Uri(path: path).replace(queryParameters: query).toString();
  }
}
