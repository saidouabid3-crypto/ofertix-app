import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/config/api_endpoints.dart';
import 'api_service.dart';

class AdRevenueEstimate {
  final String slot;
  final int impressions;
  final int clicks;
  final double rpm;
  final double estimatedRevenue;

  const AdRevenueEstimate({
    required this.slot,
    required this.impressions,
    required this.clicks,
    required this.rpm,
    required this.estimatedRevenue,
  });

  factory AdRevenueEstimate.fromMap(Map<String, dynamic> map) {
    return AdRevenueEstimate(
      slot: map['slot']?.toString() ?? 'home_banner',
      impressions: _toInt(map['impressions']),
      clicks: _toInt(map['clicks']),
      rpm: _toDouble(map['rpm'] ?? map['estimated_rpm']),
      estimatedRevenue: _toDouble(
        map['estimatedRevenue'] ?? map['estimated_revenue'],
      ),
    );
  }

  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
}

class AdRevenueService {
  AdRevenueService._();
  static final AdRevenueService instance = AdRevenueService._();

  final ApiService _api = ApiService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> trackImpression(String slot) async {
    try {
      await _api.post(ApiEndpoints.adsImpression, body: {'slot': slot});
    } catch (_) {
      await _firestore.collection('ad_events').add({
        'slot': slot,
        'type': 'impression',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> trackClick(String slot) async {
    try {
      await _api.post(ApiEndpoints.adsClick, body: {'slot': slot});
    } catch (_) {
      await _firestore.collection('ad_events').add({
        'slot': slot,
        'type': 'click',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<AdRevenueEstimate> estimate({
    String slot = 'home_banner',
    int impressions = 10000,
    double rpm = 1.5,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.adsRevenueEstimateFor(slot: slot, impressions: impressions, rpm: rpm),
      );
      return AdRevenueEstimate.fromMap(Map<String, dynamic>.from(response));
    } catch (_) {
      return AdRevenueEstimate(
        slot: slot,
        impressions: impressions,
        clicks: 0,
        rpm: rpm,
        estimatedRevenue: (impressions / 1000) * rpm,
      );
    }
  }
}
