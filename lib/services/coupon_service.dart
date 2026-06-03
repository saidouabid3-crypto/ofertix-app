import '../core/network/api_client.dart';
import '../models/coupon_model.dart';
import 'auth_service.dart';

/// Coupons service routed through the unified, locale-aware transport.
class CouponService {
  CouponService._();

  static final CouponService instance = CouponService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;

  Future<List<CouponModel>> listCoupons({String? country, String? store}) async {
    final decoded = await _api.get(
      ApiEndpoints.coupons,
      queryParameters: {
        if (country != null && country.trim().isNotEmpty) 'country': country,
        if (store != null && store.trim().isNotEmpty) 'store': store,
      },
    );

    final raw = decoded is Map ? decoded['items'] : decoded;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => CouponModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CouponModel> createCoupon({
    required String title,
    required String code,
    required String store,
    String description = '',
    String country = 'ES',
    String currency = 'EUR',
    String discountLabel = '',
    String? expiresAt,
    String? sourceUrl,
  }) async {
    final decoded = await _api.post(
      ApiEndpoints.coupons,
      body: {
        'title': title,
        'code': code,
        'store': store,
        'description': description,
        'country': country,
        'currency': currency,
        'discount_label': discountLabel,
        'expires_at': expiresAt,
        'source_url': sourceUrl,
        'created_by': _auth.currentUserId ?? 'mobile_user',
      },
    );

    return CouponModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  Future<CouponModel> verifyCoupon({
    required String couponId,
    required bool works,
  }) async {
    final decoded = await _api.post(
      ApiEndpoints.couponVerify(couponId),
      body: {
        'user_id': _auth.currentUserId ?? 'mobile_user',
        'works': works,
      },
    );

    return CouponModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }
}
