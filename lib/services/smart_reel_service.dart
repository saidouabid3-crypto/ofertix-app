import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/api_endpoints.dart';
import '../models/smart_reel_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class SmartReelService {
  SmartReelService({String? baseUrl, ApiService? api}) : _api = api ?? ApiService.instance;

  static final SmartReelService instance = SmartReelService();

  final ApiService _api;
  final AuthService _auth = AuthService.instance;
  final ProfileService _profileService = ProfileService.instance;

  Future<Map<String, String>> _authHeaders({String emptyMessage = 'Debes iniciar sesión para usar esta función.'}) async {
    final token = await _auth.getIdToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(emptyMessage);
    }

    return {'Authorization': 'Bearer ${token.trim()}'};
  }

  Future<List<SmartReelModel>> getFeed({int limit = 10, String? cursor}) async {
    final viewerId = _auth.currentUserId;

    final decoded = await _api.get(
      ApiEndpoints.smartReelsFeed,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor,
        if (viewerId != null && viewerId.trim().isNotEmpty) 'viewer_id': viewerId,
      },
      timeout: const Duration(seconds: 25),
    );

    final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => SmartReelModel.fromJson(Map<String, dynamic>.from(item)))
        .where((reel) => reel.bestVideoUrl.isNotEmpty)
        .toList();
  }

  Future<SmartReelModel> uploadSmartReel({
    required File videoFile,
    required String title,
    required String description,
    required String store,
    required double currentPrice,
    double? oldPrice,
    String currency = 'EUR',
    String? affiliateUrl,
    String? productId,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
  }) async {
    final resolvedCreator = await _resolveCreator(
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
    );

    final fields = <String, String>{
      'title': title.trim(),
      'description': description.trim(),
      'store': store.trim(),
      'current_price': currentPrice.toString(),
      'currency': currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
      'creator_id': resolvedCreator.id,
      'creator_name': resolvedCreator.name,
      'creator_avatar_url': resolvedCreator.avatarUrl,
      if (oldPrice != null && oldPrice > 0) 'old_price': oldPrice.toString(),
      if (affiliateUrl != null && affiliateUrl.trim().isNotEmpty) 'affiliate_url': affiliateUrl.trim(),
      if (productId != null && productId.trim().isNotEmpty) 'product_id': productId.trim(),
    };

    final decoded = await _api.postMultipart(
      ApiEndpoints.smartReelsUpload,
      fields: fields,
      files: [
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          contentType: _detectVideoType(videoFile.path),
        ),
      ],
      extraHeaders: await _authHeaders(emptyMessage: 'Debes iniciar sesión para subir reels.'),
      timeout: const Duration(seconds: 120),
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid upload response');
    }

    return SmartReelModel.fromJson(decoded);
  }

  Future<SmartReelModel> updateSmartReel({
    required String reelId,
    required String title,
    required String description,
    required String store,
    required double currentPrice,
    double? oldPrice,
    String currency = 'EUR',
    String? affiliateUrl,
    String? productId,
  }) async {
    final decoded = await _api.patch(
      ApiEndpoints.smartReel(reelId),
      extraHeaders: await _authHeaders(),
      timeout: const Duration(seconds: 25),
      body: {
        'title': title.trim(),
        'description': description.trim(),
        'store': store.trim(),
        'current_price': currentPrice,
        'old_price': oldPrice != null && oldPrice > 0 ? oldPrice : null,
        'currency': currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
        'affiliate_url': affiliateUrl != null && affiliateUrl.trim().isNotEmpty ? affiliateUrl.trim() : null,
        'product_id': productId != null && productId.trim().isNotEmpty ? productId.trim() : null,
      },
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid update response');
    }

    return SmartReelModel.fromJson(decoded);
  }

  Future<void> deleteSmartReel(String reelId) async {
    await _api.delete(
      ApiEndpoints.smartReel(reelId),
      extraHeaders: await _authHeaders(),
      timeout: const Duration(seconds: 20),
    );
  }

  Future<void> messageCreator({required String reelId, required String text}) async {
    await _api.post(
      ApiEndpoints.smartReelMessage(reelId),
      extraHeaders: await _authHeaders(),
      body: {'text': text.trim()},
      timeout: const Duration(seconds: 20),
    );
  }

  Future<void> trackView(String reelId) => _safePost(ApiEndpoints.smartReelView(reelId));
  Future<void> trackClick(String reelId) => _safePost(ApiEndpoints.smartReelClick(reelId));
  Future<void> like(String reelId) => _safePost(ApiEndpoints.smartReelLike(reelId));
  Future<void> save(String reelId) => _safePost(ApiEndpoints.smartReelSave(reelId));
  Future<void> report(String reelId) => _safePost(ApiEndpoints.smartReelReport(reelId));

  Future<void> followCreator(String creatorId) async {
    await _api.post(
      ApiEndpoints.smartReelCreatorFollow(creatorId),
      extraHeaders: await _authHeaders(),
      timeout: const Duration(seconds: 20),
    );
  }

  Future<List<SmartReelComment>> getComments(String reelId) async {
    try {
      final decoded = await _api.get(
        ApiEndpoints.smartReelComments(reelId),
        timeout: const Duration(seconds: 20),
      );

      final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
      if (rawItems is! List) return [];

      return rawItems
          .whereType<Map>()
          .map((item) => SmartReelComment.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SmartReelComment?> addComment({
    required String reelId,
    required String text,
    String? userId,
    String? userName,
  }) async {
    try {
      final decoded = await _api.post(
        ApiEndpoints.smartReelComments(reelId),
        extraHeaders: await _authHeaders(),
        body: {'reel_id': reelId, 'text': text.trim()},
        timeout: const Duration(seconds: 20),
      );

      if (decoded is! Map<String, dynamic>) return null;
      return SmartReelComment.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safePost(String endpoint) async {
    try {
      await _api.post(endpoint, timeout: const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<_ResolvedCreator> _resolveCreator({
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
  }) async {
    final user = _auth.currentUser;

    String id = creatorId?.trim() ?? '';
    String name = creatorName?.trim() ?? '';
    String avatar = creatorAvatarUrl?.trim() ?? '';

    if (id.isEmpty && user != null) id = user.uid;
    if (name.isEmpty && user != null) name = user.displayName?.trim() ?? '';

    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile != null) {
        if (id.isEmpty) id = profile.uid;
        if (name.isEmpty) name = profile.displayName;
        if (avatar.isEmpty) avatar = profile.photoUrl;
      }
    } catch (_) {}

    if (id.isEmpty) id = 'mobile_user';

    if (name.isEmpty) {
      final email = user?.email ?? '';
      if (email.contains('@')) name = email.split('@').first;
    }

    if (name.isEmpty) name = 'Ofertix User';
    return _ResolvedCreator(id: id, name: name, avatarUrl: avatar);
  }

  MediaType _detectVideoType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.m4v')) return MediaType('video', 'x-m4v');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    return MediaType('video', 'mp4');
  }
}

class _ResolvedCreator {
  final String id;
  final String name;
  final String avatarUrl;

  const _ResolvedCreator({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}
