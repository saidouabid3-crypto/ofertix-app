import '../core/network/api_client.dart';
import '../models/geo_alert_model.dart';

/// Geo-alert service routed through the unified, locale-aware transport.
class GeoAlertService {
  GeoAlertService._();

  static final GeoAlertService instance = GeoAlertService._();

  final ApiService _api = ApiService.instance;

  Future<List<NearbyDealModel>> nearbyDeals({
    required double latitude,
    required double longitude,
    List<String> watchlistProductIds = const [],
  }) async {
    final decoded = await _api.get(
      ApiEndpoints.geoAlertsNearby,
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (watchlistProductIds.isNotEmpty)
          'watchlist': watchlistProductIds.join(','),
      },
    );

    final raw = decoded is Map ? decoded['items'] : decoded;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => NearbyDealModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
