import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/config/api_endpoints.dart';
import '../models/marketplace_item.dart';
import 'api_service.dart';

class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _api = ApiService.instance;

  static const String _collection = 'marketplace_items';

  Future<List<MarketplaceItem>> fetchItems({
    int limit = 30,
    String? city,
    String? category,
    String countryCode = 'global',
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.marketplaceItemsList(
          limit: limit,
          city: city,
          category: category,
          country: countryCode.trim().isNotEmpty && countryCode != 'global'
              ? countryCode.trim().toLowerCase()
              : null,
        ),
      );
      final list = response is List
          ? response
          : response['items'] as List? ?? const [];
      final items = list
          .map(
            (e) => MarketplaceItem.fromMap(
              Map<String, dynamic>.from(e),
              e['id']?.toString() ?? '',
            ),
          )
          .toList();

      return _filterByCountry(items, countryCode);
    } catch (_) {
      Query<Map<String, dynamic>> ref = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true);
      if (city != null && city.trim().isNotEmpty)
        ref = ref.where('city', isEqualTo: city.trim());
      if (category != null && category.trim().isNotEmpty)
        ref = ref.where('category', isEqualTo: category.trim());
      final snap = await ref
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final items = snap.docs
          .map((d) => MarketplaceItem.fromMap(d.data(), d.id))
          .toList();

      return _filterByCountry(items, countryCode);
    }
  }

  List<MarketplaceItem> _filterByCountry(
    List<MarketplaceItem> items,
    String countryCode,
  ) {
    final normalized = countryCode.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'global') return items;

    return items
        .where((item) => item.isAvailableForCountry(normalized))
        .toList();
  }

  Future<String> createItem(MarketplaceItem item) async {
    final data = item.toMap()
      ..addAll({'createdAt': FieldValue.serverTimestamp(), 'isActive': true});
    try {
      final response = await _api.post(
        ApiEndpoints.marketplaceItems,
        body: data,
        authorized: true,
      );
      return response['id']?.toString() ?? '';
    } catch (_) {
      final doc = await _firestore.collection(_collection).add(data);
      return doc.id;
    }
  }

  Future<void> favoriteItem(String itemId, String userId) async {
    try {
      await _api.post(
        ApiEndpoints.marketplaceItemFavorite(itemId),
        body: {'userId': userId},
        authorized: true,
      );
    } catch (_) {
      await _firestore
          .collection(_collection)
          .doc(itemId)
          .collection('favorites')
          .doc(userId)
          .set({'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> reportItem(String itemId, String userId, String reason) async {
    try {
      await _api.post(
        ApiEndpoints.marketplaceItemReport(itemId),
        body: {'userId': userId, 'reason': reason},
        authorized: true,
      );
    } catch (_) {
      await _firestore.collection('item_reports').add({
        'itemId': itemId,
        'userId': userId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
