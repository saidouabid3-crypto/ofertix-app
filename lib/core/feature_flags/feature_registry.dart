enum OfertixFeatureStatus { active, adminOnly, needsSetup, disabled, hidden }

class OfertixFeature {
  const OfertixFeature({
    required this.key,
    required this.name,
    required this.status,
    this.userVisible = true,
    this.adminVisible = true,
    this.reason = '',
  });
  final String key;
  final String name;
  final OfertixFeatureStatus status;
  final bool userVisible;
  final bool adminVisible;
  final String reason;
  bool get canShowToUser =>
      status == OfertixFeatureStatus.active && userVisible;
  bool get canShowToAdmin =>
      adminVisible && status != OfertixFeatureStatus.hidden;
}

class OfertixFeatureRegistry {
  static const Map<String, OfertixFeature> features = {
    'home': OfertixFeature(
      key: 'home',
      name: 'Home',
      status: OfertixFeatureStatus.active,
    ),
    'products': OfertixFeature(
      key: 'products',
      name: 'Products',
      status: OfertixFeatureStatus.active,
    ),
    'search': OfertixFeature(
      key: 'search',
      name: 'Search',
      status: OfertixFeatureStatus.active,
    ),
    'ai_assistant': OfertixFeature(
      key: 'ai_assistant',
      name: 'AI Assistant',
      status: OfertixFeatureStatus.active,
    ),
    'ai_brain': OfertixFeature(
      key: 'ai_brain',
      name: 'AI Brain',
      status: OfertixFeatureStatus.active,
    ),
    'scan': OfertixFeature(
      key: 'scan',
      name: 'Scan',
      status: OfertixFeatureStatus.active,
    ),
    'visual_search': OfertixFeature(
      key: 'visual_search',
      name: 'Visual Search',
      status: OfertixFeatureStatus.active,
    ),
    'voice_search': OfertixFeature(
      key: 'voice_search',
      name: 'Voice Search',
      status: OfertixFeatureStatus.active,
    ),
    'reels': OfertixFeature(
      key: 'reels',
      name: 'Reels',
      status: OfertixFeatureStatus.active,
    ),
    'marketplace': OfertixFeature(
      key: 'marketplace',
      name: 'Marketplace',
      status: OfertixFeatureStatus.active,
    ),
    'messages': OfertixFeature(
      key: 'messages',
      name: 'Messages',
      status: OfertixFeatureStatus.active,
    ),
    'profile': OfertixFeature(
      key: 'profile',
      name: 'Profile',
      status: OfertixFeatureStatus.active,
    ),
    'favorites': OfertixFeature(
      key: 'favorites',
      name: 'Favorites',
      status: OfertixFeatureStatus.active,
    ),
    'alerts': OfertixFeature(
      key: 'alerts',
      name: 'Alerts',
      status: OfertixFeatureStatus.active,
    ),
    'watchlist': OfertixFeature(
      key: 'watchlist',
      name: 'Watchlist',
      status: OfertixFeatureStatus.active,
    ),
    'admin': OfertixFeature(
      key: 'admin',
      name: 'Admin',
      status: OfertixFeatureStatus.adminOnly,
      userVisible: false,
    ),
    'cashback': OfertixFeature(
      key: 'cashback',
      name: 'Cashback',
      status: OfertixFeatureStatus.needsSetup,
      userVisible: false,
      reason: 'Requires affiliate conversion tracking and payout setup.',
    ),
    'coupons_p2p': OfertixFeature(
      key: 'coupons_p2p',
      name: 'P2P Coupons',
      status: OfertixFeatureStatus.adminOnly,
      userVisible: false,
      reason: 'Requires moderation and fraud rules.',
    ),
    'mystery_box': OfertixFeature(
      key: 'mystery_box',
      name: 'Mystery Box',
      status: OfertixFeatureStatus.adminOnly,
      userVisible: false,
      reason: 'Requires reward pool and abuse protection.',
    ),
  };
  static bool canShowToUser(String key) =>
      features[key]?.canShowToUser ?? false;
  static bool canShowToAdmin(String key) =>
      features[key]?.canShowToAdmin ?? false;
}
