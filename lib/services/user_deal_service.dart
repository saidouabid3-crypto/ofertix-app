import '../core/network/api_client.dart';
import '../models/user_generated_deal_model.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// User-generated deals service routed through the unified, locale-aware
/// transport. No hardcoded host; locale headers are injected automatically.
class UserDealService {
  UserDealService._();

  static final UserDealService instance = UserDealService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;
  final ProfileService _profile = ProfileService.instance;

  Future<List<UserGeneratedDealModel>> listDeals({
    String? country,
    String? city,
    String? status,
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.userDeals,
      queryParameters: {
        if (country != null && country.isNotEmpty) 'country': country,
        if (city != null && city.isNotEmpty) 'city': city,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final raw = decoded is Map ? decoded['items'] : decoded;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => UserGeneratedDealModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<UserGeneratedDealModel> createDeal({
    required String title,
    required String store,
    required double currentPrice,
    double? oldPrice,
    String description = '',
    String currency = 'EUR',
    String country = 'ES',
    String city = '',
    double? latitude,
    double? longitude,
    String mediaUrl = '',
  }) async {
    final user = _auth.currentUser;
    final profile = await _profile.getCurrentProfile();
    final creatorId = profile?.uid ?? user?.uid ?? 'mobile_user';
    final creatorName =
        profile?.displayName ?? user?.displayName ?? 'Ofertix User';

    final decoded = await _api.post(
      ApiEndpoints.userDeals,
      body: {
        'title': title,
        'description': description,
        'store': store,
        'current_price': currentPrice,
        'old_price': oldPrice,
        'currency': currency,
        'country': country,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'media_url': mediaUrl,
        'creator_id': creatorId,
        'creator_name': creatorName,
      },
    );

    return UserGeneratedDealModel.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }
}
