import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/api_config.dart';
import '../core/config/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/marketplace_conversation.dart';
import '../models/marketplace_item.dart';
import '../models/marketplace_review.dart';
import 'api_service.dart';

class MarketplaceService {
  MarketplaceService._();
  static final MarketplaceService instance = MarketplaceService._();

  final ApiService _api = ApiService.instance;

  Future<MarketplaceConversation> startConversationForListing(
    MarketplaceItem item, {
    String initialMessage = '',
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (kDebugMode) {
      debugPrint(
        '[Marketplace16E] start_conversation item=${item.id} '
        'seller=${item.sellerId} auth=${auth == null ? 'no' : 'yes'}',
      );
    }
    final token = await _freshToken();
    final response = await _api.post(
      ApiEndpoints.marketplaceMessagesStart,
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
      body: {
        'listing_id': item.id,
        if (initialMessage.trim().isNotEmpty)
          'initial_message': initialMessage.trim(),
      },
    );
    return MarketplaceConversation.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<MarketplaceConversation>> fetchInbox({int limit = 30}) async {
    final token = await _freshToken();
    final response = await _api.get(
      ApiEndpoints.messagesInbox,
      authorized: true,
      queryParameters: {'limit': limit.clamp(1, 50)},
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final raw = response is List
        ? response
        : response['items'] as List? ?? const [];
    final items = raw
        .whereType<Map>()
        .map(
          (entry) =>
              MarketplaceConversation.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList();
    if (kDebugMode) {
      debugPrint('[Marketplace16E] inbox_fetch count=${items.length}');
    }
    return items;
  }

  Future<MarketplaceConversationThread> fetchConversation(
    String conversationId, {
    int limit = 50,
  }) async {
    final token = await _freshToken();
    final response = await _api.get(
      ApiEndpoints.messageConversation(conversationId),
      authorized: true,
      queryParameters: {'limit': limit.clamp(1, 100)},
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final map = Map<String, dynamic>.from(response as Map);
    final rawConversation = map['conversation'];
    if (rawConversation is! Map) {
      throw const NetworkException(
        'Conversation response did not include its context.',
        code: 'missing_conversation',
      );
    }
    final rawMessages = map['items'] as List? ?? const [];
    final thread = MarketplaceConversationThread(
      conversation: MarketplaceConversation.fromMap(
        Map<String, dynamic>.from(rawConversation),
      ),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (entry) =>
                MarketplaceMessage.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(),
    );
    if (kDebugMode) {
      debugPrint(
        '[Marketplace16E] conversation_fetch id=$conversationId '
        'messages=${thread.messages.length}',
      );
    }
    return thread;
  }

  Future<MarketplaceMessage> sendMessage(
    String conversationId,
    String text,
  ) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 1000) {
      throw const NetworkException(
        'Message must contain between 1 and 1000 characters.',
        code: 'invalid_message',
      );
    }
    final token = await _freshToken();
    try {
      final response = await _api.post(
        ApiEndpoints.messageConversationSend(conversationId),
        authorized: true,
        extraHeaders: {'Authorization': 'Bearer $token'},
        body: {'text': clean},
      );
      final message = MarketplaceMessage.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E] send_message id=$conversationId status=success',
        );
      }
      return message;
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E] send_message id=$conversationId status=failed',
        );
      }
      rethrow;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final token = await _freshToken();
    await _api.post(
      ApiEndpoints.messageConversationRead(conversationId),
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> archiveConversation(String conversationId) async {
    final token = await _freshToken();
    await _api.post(
      ApiEndpoints.messageConversationArchive(conversationId),
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> deleteConversationForMe(String conversationId) async {
    final token = await _freshToken();
    await _api.post(
      ApiEndpoints.messageConversationDeleteForMe(conversationId),
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
  }

  Future<MarketplaceMessage> sendOffer(
    String conversationId, {
    required double amount,
    required String currency,
    String message = '',
  }) async {
    if (amount <= 0) {
      throw const NetworkException(
        'Offer amount must be greater than zero.',
        code: 'invalid_offer',
      );
    }
    final token = await _freshToken();
    try {
      final response = await _api.post(
        ApiEndpoints.messageConversationOffer(conversationId),
        authorized: true,
        extraHeaders: {'Authorization': 'Bearer $token'},
        body: {
          'amount': amount,
          'currency': currency,
          if (message.trim().isNotEmpty) 'message': message.trim(),
        },
      );
      final offer = MarketplaceMessage.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E] send_offer id=$conversationId '
          'amount=$amount status=success',
        );
      }
      return offer;
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E] send_offer id=$conversationId '
          'amount=$amount status=failed',
        );
      }
      rethrow;
    }
  }

  Future<MarketplaceItem> fetchItemById(String itemId) async {
    final response = await _api.get(ApiEndpoints.marketplaceItem(itemId));
    return MarketplaceItem.fromMap(
      Map<String, dynamic>.from(response as Map),
      response['id']?.toString() ?? itemId,
    );
  }

  Future<List<MarketplaceItem>> fetchSimilarItems(
    String itemId, {
    int limit = 8,
  }) async {
    final response = await _api.get(
      ApiEndpoints.marketplaceItemSimilar(itemId),
      queryParameters: {'limit': limit.clamp(1, 12)},
    );
    final rawList = response is Map
        ? (response['items'] as List? ?? const [])
        : (response is List ? response : const []);
    final items = <MarketplaceItem>[];
    for (final e in rawList) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        items.add(MarketplaceItem.fromMap(map, map['id']?.toString() ?? ''));
      } catch (_) {
        continue;
      }
    }
    return items;
  }

  Future<List<MarketplaceItem>> fetchItems({
    int limit = 30,
    String? city,
    String? category,
    String countryCode = 'global',
  }) async {
    final endpoint = ApiEndpoints.marketplaceItemsList(
      limit: limit,
      city: city,
      category: category,
      country: countryCode.trim().isNotEmpty && countryCode != 'global'
          ? countryCode.trim().toLowerCase()
          : null,
    );

    if (kDebugMode) {
      debugPrint(
        '[Marketplace16A] fetch_start endpoint=$endpoint limit=$limit',
      );
    }

    final response = await _api.get(endpoint);

    final rawList = response is List
        ? response
        : response['items'] as List? ?? const [];

    if (kDebugMode) {
      debugPrint('[Marketplace16A] api_success raw_count=${rawList.length}');
    }

    // Parse items with per-item error isolation so one bad item never drops
    // the whole list. Backend already enforces public safety (approved,
    // isActive, visibleToUsers). Flutter does NOT re-filter by country because
    // the backend already returns only country-appropriate items; adding a
    // second client-side country filter can incorrectly drop valid items when
    // sellerCountryCode uses a different casing or alias than the device locale.
    final items = <MarketplaceItem>[];
    for (final e in rawList) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        final id = e['id']?.toString() ?? '';
        final item = MarketplaceItem.fromMap(map, id);
        items.add(item);
        if (kDebugMode) {
          debugPrint(
            '[Marketplace16A] item id=$id title=${item.title.substring(0, item.title.length.clamp(0, 30))} '
            'status=${item.status} active=${item.isActive} visible=${item.visibleToUsers} '
            'category=${item.categoryKey}',
          );
        }
      } catch (err) {
        final id = (e is Map ? e['id'] : null)?.toString() ?? '?';
        if (kDebugMode) {
          debugPrint('[Marketplace16A] dropped id=$id reason=$err');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[Marketplace16A] parsed_count=${items.length}');
      debugPrint('[Marketplace16A] local_filter_before=${items.length}');
      // No client-side country filter — backend already filtered.
      debugPrint('[Marketplace16A] local_filter_after=${items.length}');
      debugPrint('[Marketplace16A] displayed_count=${items.length}');
    }

    return items;
  }

  Future<MarketplaceItem> createItem(
    Map<String, dynamic> listing, {
    required String token,
  }) async {
    final apiBody = Map<String, dynamic>.from(listing);

    if (kDebugMode) {
      final imgs = apiBody['images'];
      final count = imgs is List ? imgs.length : 0;
      final first = imgs is List && imgs.isNotEmpty ? imgs.first : 'none';
      final desc = apiBody['description'];
      final descLen = desc is String ? desc.length : 0;
      final sanitized = {
        'title': apiBody['title'],
        'descriptionLength': descLen,
        'price': apiBody['price'],
        'countryCode': apiBody['countryCode'],
        'currencyCode': apiBody['currencyCode'],
        'city': apiBody['city'],
        'postalCode': apiBody['postalCode'],
        'area': apiBody['area'],
        'categoryKey': apiBody['categoryKey'],
        'conditionKey': apiBody['conditionKey'],
        'deliveryMethodKey': apiBody['deliveryMethodKey'],
        'imagesCount': count,
        'coverImage': apiBody['coverImage'],
        'firstImageUrl': first,
      };
      debugPrint('[SellCreate16A] payload=$sanitized');
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
      return MarketplaceItem.fromMap(
        Map<String, dynamic>.from(response as Map),
        itemId,
      );
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

  Future<MarketplaceItem> updateMyItem(
    String itemId,
    Map<String, dynamic> listing,
  ) async {
    final token = await _freshToken();
    final response = await _api.patch(
      ApiEndpoints.marketplaceMyItem(itemId),
      body: listing,
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final item = MarketplaceItem.fromMap(
      Map<String, dynamic>.from(response as Map),
      response['id']?.toString() ?? itemId,
    );
    if (kDebugMode) {
      debugPrint('[Sell16A] item edited id=${item.id} status=${item.status}');
    }
    return item;
  }

  Future<MarketplaceItem> archiveMyItem(String itemId) async {
    final token = await _freshToken();
    final response = await _api.delete(
      ApiEndpoints.marketplaceMyItem(itemId),
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final item = MarketplaceItem.fromMap(
      Map<String, dynamic>.from(response as Map),
      response['id']?.toString() ?? itemId,
    );
    if (kDebugMode) {
      debugPrint('[Sell16A] item archived id=${item.id}');
    }
    return item;
  }

  Future<MarketplaceItem> markMyItemSold(String itemId) async {
    final token = await _freshToken();
    final response = await _api.post(
      ApiEndpoints.marketplaceMyItemMarkSold(itemId),
      authorized: true,
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    final item = MarketplaceItem.fromMap(
      Map<String, dynamic>.from(response as Map),
      response['id']?.toString() ?? itemId,
    );
    if (kDebugMode) {
      debugPrint('[Sell16A] item marked sold id=${item.id}');
    }
    return item;
  }

  Future<void> favoriteItem(String itemId, String userId) async {
    await _api.post(
      ApiEndpoints.marketplaceItemFavorite(itemId),
      body: {'userId': userId},
      authorized: true,
    );
  }

  Future<bool> saveListing(String itemId) async {
    final token = await _freshToken();
    await _api.post(
      ApiEndpoints.marketplaceItemFavorite(itemId),
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    return true;
  }

  Future<bool> unsaveListing(String itemId) async {
    final token = await _freshToken();
    await _api.delete(
      ApiEndpoints.marketplaceItemFavorite(itemId),
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    return false;
  }

  Future<bool> isListingSaved(String itemId) async {
    final token = await _freshToken();
    final response = await _api.get(
      ApiEndpoints.marketplaceItemFavorite(itemId),
      extraHeaders: {'Authorization': 'Bearer $token'},
    );
    return response is Map && response['is_saved'] == true;
  }

  Future<MarketplaceReview> submitReview({
    required String listingId,
    required String conversationId,
    required String revieweeId,
    required int rating,
    String comment = '',
  }) async {
    final token = await _freshToken();
    final response = await _api.post(
      ApiEndpoints.marketplaceReviews,
      extraHeaders: {'Authorization': 'Bearer $token'},
      body: {
        'listing_id': listingId,
        'conversation_id': conversationId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
      },
    );
    return MarketplaceReview.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// Fetch authenticated seller's own items (pending + approved + rejected + hidden).
  Future<List<MarketplaceItem>> fetchMyItems({int limit = 50}) async {
    if (kDebugMode) {
      debugPrint('[MyListings] GET ${ApiEndpoints.marketplaceMyItems}');
    }
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

  Future<String> _freshToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const UnauthorizedException('Authentication is required.');
    }
    return token;
  }
}
