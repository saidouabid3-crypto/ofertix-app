import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/api_config.dart';
import '../core/config/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/marketplace_item.dart';
import 'api_service.dart';

class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  final ApiService _api = ApiService.instance;

  Future<List<MarketplaceItem>> fetchItems({
    int limit = 30,
    String? city,
    String? category,
    String countryCode = 'global',
  }) async {
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

  Future<String> createItem(
    MarketplaceItem item, {
    required String token,
  }) async {
    // API body uses an ISO timestamp so the backend receives plain JSON.
    final apiBody = Map<String, dynamic>.from(item.toMap())
      ..['createdAt'] =
          item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String();

    if (kDebugMode) {
      final imgs = apiBody['images'];
      final count = imgs is List ? imgs.length : 0;
      final first = imgs is List && imgs.isNotEmpty ? imgs.first : 'none';
      debugPrint('[SellCreate] images=$count');
      debugPrint('[SellCreate] firstUrl=$first');
      debugPrint(
        '[SellCreate] endpoint=${ApiConfig.uri(ApiEndpoints.marketplaceItems)}',
      );
      debugPrint(
        '[SellCreate] payloadOwnerFields=sellerId,userId,ownerId '
        '(backend-owned)',
      );
    }

    try {
      final response = await _api.post(
        ApiEndpoints.marketplaceItems,
        body: apiBody,
        authorized: true,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );
      final itemId = response['id']?.toString() ?? '';
      if (kDebugMode) {
        debugPrint('[SellCreate] status=200');
        debugPrint('[SellCreate] body=${jsonEncode(response)}');
      }
      if (itemId.isEmpty) {
        throw const NetworkException(
          'Marketplace create response did not include an item id.',
          code: 'missing_item_id',
          cause: 'response.id was empty',
        );
      }
      return itemId;
    } catch (e) {
      if (kDebugMode) {
        final status = _statusCode(e);
        final body = e is AppException ? e.cause : e;
        final code = e is AppException ? e.code : null;
        debugPrint('[SellCreate] status=$status');
        debugPrint('[SellCreate] body=$body');
        debugPrint('[SellSubmit] failed step=create code=${code ?? status}');
      }
      rethrow;
    }
  }

  Future<void> favoriteItem(String itemId, String userId) async {
    await _api.post(
      ApiEndpoints.marketplaceItemFavorite(itemId),
      body: {'userId': userId},
      authorized: true,
    );
  }

  /// Fetch authenticated seller's own items (pending + approved + rejected + hidden).
  Future<List<MarketplaceItem>> fetchMyItems({int limit = 50}) async {
    if (kDebugMode)
      debugPrint('[MyListings] GET ${ApiEndpoints.marketplaceMyItems}');
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        throw const UnauthorizedException('Authentication is required.');
      }
      final response = await _api.get(
        ApiEndpoints.marketplaceMyItems,
        authorized: true,
        queryParameters: {'limit': limit},
        extraHeaders: {'Authorization': 'Bearer $token'},
      );
      final list = response is List
          ? response
          : response['items'] as List? ?? const [];
      final items = list
          .map(
            (e) => MarketplaceItem.fromMap(
              Map<String, dynamic>.from(e as Map),
              e['id']?.toString() ?? '',
            ),
          )
          .toList();
      if (kDebugMode) {
        final ids = items.take(5).map((i) => i.id).join(',');
        debugPrint('[MyListings] status=200  count=${items.length}  ids=$ids');
      }
      return items;
    } catch (e) {
      if (kDebugMode) {
        final status = _statusCode(e);
        final body = e is AppException ? e.cause : e;
        debugPrint('[MyListings] status=$status');
        debugPrint('[MyListings] body=$body');
      }
      rethrow;
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
    final mime = allowed.contains(rawMime)
        ? rawMime
        : _mimeFromPath(xFile.path);
    if (!allowed.contains(mime)) {
      if (kDebugMode) debugPrint('[SellUpload] unsupported MIME: $mime');
      return (url: null, error: 'INVALID_TYPE');
    }

    try {
      final uri = ApiConfig.uri(ApiEndpoints.marketplaceUploadImage);
      if (kDebugMode) {
        debugPrint(
          '[SellUpload] POST $uri  file=${xFile.name}  bytes=$bytes  mime=$mime',
        );
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

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        debugPrint(
          '[SellUpload] status=${response.statusCode}  body=${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // ApiEnvelopeMiddleware wraps responses as {success, data, error}.
        // After the backend pre-envelopes, the URL is at body['data']['url'].
        // Support both shapes for robustness.
        final url = _extractUrl(body);
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

  /// Extract the image URL from the API envelope response.
  /// Supports:
  ///   body['data']['url']   — standard post-fix envelope
  ///   body['url']           — direct (legacy / before middleware)
  static String? _extractUrl(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map) {
      final u = data['url'];
      if (u is String && u.isNotEmpty) return u;
    }
    final direct = body['url'];
    if (direct is String && direct.isNotEmpty) return direct;
    return null;
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
    await _api.post(
      ApiEndpoints.marketplaceItemReport(itemId),
      body: {'userId': userId, 'reason': reason},
      authorized: true,
    );
  }

  static int? _statusCode(Object error) {
    if (error is NetworkException) return error.statusCode;
    if (error is UnauthorizedException) return 401;
    if (error is ForbiddenException) return 403;
    if (error is NotFoundException) return 404;
    return null;
  }
}
