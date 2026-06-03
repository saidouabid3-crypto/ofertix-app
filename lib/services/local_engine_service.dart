
import '../core/network/api_client.dart';
import '../models/local_offer_model.dart';
import '../models/local_store_model.dart';

class LocalEngineService {
  LocalEngineService._();

  static final LocalEngineService instance = LocalEngineService._();
  final ApiService _api = ApiService.instance;

  Future<List<LocalStoreModel>> getFeaturedStores({
    String countryCode = 'es',
    String? city,
    int limit = 12,
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.localStores,
      queryParameters: {
        'country': countryCode,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        'featured': 'true',
        'limit': limit.toString(),
      },
    );
    return _storesFromResponse(decoded);
  }

  Future<List<LocalStoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? category,
    int limit = 30,
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.localStoresNearby,
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radiusKm': radiusKm.toString(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
        'limit': limit.toString(),
      },
    );
    return _storesFromResponse(decoded);
  }

  Future<LocalStoreModel> getStore(String storeId) async {
    final decoded = await _api.get(ApiEndpoints.localStore(storeId));
    final raw = decoded is Map && decoded['store'] is Map ? decoded['store'] : decoded;
    if (raw is Map) return LocalStoreModel.fromJson(Map<String, dynamic>.from(raw));
    return LocalStoreModel.empty();
  }

  Future<List<LocalOfferModel>> getStoreOffers(String storeId) async {
    final decoded = await _api.get(ApiEndpoints.localStoreOffers(storeId));
    return _offersFromResponse(decoded);
  }

  Future<List<LocalOfferModel>> getNearbyOffers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? category,
    int limit = 50,
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.localOffersNearby,
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radiusKm': radiusKm.toString(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
        'limit': limit.toString(),
      },
    );
    return _offersFromResponse(decoded);
  }

  Future<List<LocalOfferModel>> getHotLocalOffers({
    String countryCode = 'es',
    String? city,
    int limit = 30,
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.localOffersHot,
      queryParameters: {
        'country': countryCode,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        'limit': limit.toString(),
      },
    );
    return _offersFromResponse(decoded);
  }

  Future<LocalStoreModel> createStore(LocalStoreModel store) async {
    final decoded = await _api.post(
      ApiEndpoints.merchantStores,
      body: store.toJson(),
      authorized: true,
    );
    final raw = decoded is Map && decoded['store'] is Map ? decoded['store'] : decoded;
    if (raw is Map) return LocalStoreModel.fromJson(Map<String, dynamic>.from(raw));
    return store;
  }

  Future<LocalOfferModel> createOffer(LocalOfferModel offer) async {
    final decoded = await _api.post(
      ApiEndpoints.merchantOffers,
      body: offer.toJson(),
      authorized: true,
    );
    final raw = decoded is Map && decoded['offer'] is Map ? decoded['offer'] : decoded;
    if (raw is Map) return LocalOfferModel.fromJson(Map<String, dynamic>.from(raw));
    return offer;
  }

  Future<List<LocalStoreModel>> getMerchantStores() async {
    final decoded = await _api.get(ApiEndpoints.merchantStores, authorized: true);
    return _storesFromResponse(decoded);
  }

  Future<List<LocalOfferModel>> getMerchantOffers() async {
    final decoded = await _api.get(ApiEndpoints.merchantOffers, authorized: true);
    return _offersFromResponse(decoded);
  }

  Future<List<LocalOfferModel>> getPendingOffers({int limit = 50}) async {
    final decoded = await _api.get(
      ApiEndpoints.adminLocalOffersPending,
      queryParameters: {'limit': limit.toString()},
      authorized: true,
    );
    return _offersFromResponse(decoded);
  }

  Future<LocalOfferModel> approveOffer(String offerId) async {
    final decoded = await _api.post(
      ApiEndpoints.adminLocalOfferApprove(offerId),
      authorized: true,
    );
    final raw = decoded is Map && decoded['offer'] is Map ? decoded['offer'] : decoded;
    if (raw is Map) return LocalOfferModel.fromJson(Map<String, dynamic>.from(raw));
    return LocalOfferModel.empty();
  }

  Future<LocalOfferModel> rejectOffer(String offerId, {String reason = ''}) async {
    final decoded = await _api.post(
      ApiEndpoints.adminLocalOfferReject(offerId),
      body: {'reason': reason},
      authorized: true,
    );
    final raw = decoded is Map && decoded['offer'] is Map ? decoded['offer'] : decoded;
    if (raw is Map) return LocalOfferModel.fromJson(Map<String, dynamic>.from(raw));
    return LocalOfferModel.empty();
  }

  Future<void> registerOfferClick(String offerId) async {
    await _api.post(ApiEndpoints.localOfferClick(offerId));
  }

  List<LocalStoreModel> _storesFromResponse(dynamic decoded) {
    final raw = decoded is Map ? (decoded['items'] ?? decoded['stores'] ?? decoded['data']) : decoded;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => LocalStoreModel.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty || e.name.isNotEmpty)
        .toList();
  }

  List<LocalOfferModel> _offersFromResponse(dynamic decoded) {
    final raw = decoded is Map ? (decoded['items'] ?? decoded['offers'] ?? decoded['data']) : decoded;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => LocalOfferModel.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty || e.title.isNotEmpty)
        .toList();
  }
}
