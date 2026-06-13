import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/api_config.dart';
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

  /// Upload an image picked from the gallery to the backend (Cloudinary via
  /// server-side). Returns a record: url is set on success, error code is set
  /// on failure ('IMAGE_TOO_LARGE', 'INVALID_TYPE', 'UPLOAD_FAILED', …).
  Future<({String? url, String? error})> uploadImage(
    XFile xFile,
    String token,
  ) async {
    // Pre-flight: check size before sending to backend (5 MB limit).
    final bytes = await xFile.length();
    if (bytes > 5 * 1024 * 1024) {
      if (kDebugMode) debugPrint('[SellUpload] file too large: $bytes bytes');
      return (url: null, error: 'IMAGE_TOO_LARGE');
    }

    // Determine MIME type: prefer xFile.mimeType, fall back to extension.
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    final rawMime = xFile.mimeType?.toLowerCase() ?? _mimeFromPath(xFile.path);
    final mime = allowed.contains(rawMime) ? rawMime : _mimeFromPath(xFile.path);
    if (!allowed.contains(mime)) {
      if (kDebugMode) debugPrint('[SellUpload] unsupported MIME: $mime');
      return (url: null, error: 'INVALID_TYPE');
    }

    try {
      final uri = ApiConfig.uri(ApiEndpoints.marketplaceUploadImage);
      if (kDebugMode) {
        debugPrint('[SellUpload] POST $uri  file=${xFile.name}  bytes=$bytes  mime=$mime');
      }

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            xFile.path,
            contentType: MediaType.parse(mime),
          ),
        );

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        debugPrint('[SellUpload] status=${response.statusCode}  body=${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        return (url: url, error: url == null ? 'UPLOAD_FAILED' : null);
      }

      // Try to extract structured error code from backend response.
      String code = 'UPLOAD_FAILED';
      try {
        final err = jsonDecode(response.body);
        if (err is Map) {
          final detail = err['detail'];
          if (detail is Map) code = detail['code'] as String? ?? code;
        }
      } catch (_) {}
      return (url: null, error: code);
    } catch (e) {
      if (kDebugMode) debugPrint('[SellUpload] exception=$e');
      return (url: null, error: 'UPLOAD_FAILED');
    }
  }

  static String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    const map = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    return map[ext] ?? 'image/jpeg';
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
