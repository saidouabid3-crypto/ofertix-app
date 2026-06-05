import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile_model.dart';
import '../models/user_identity.dart';
import '../models/marketplace_item.dart';
import '../models/smart_reel_model.dart';
import '../core/config/api_endpoints.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'settings_service.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = AuthService.instance;
  final SettingsService _settings = SettingsService.instance;
  final ApiService _api = ApiService.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<UserProfileModel?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return UserProfileModel.fromMap({
        ...data,
        'uid': data['uid'] ?? user.uid,
        'email': data['email'] ?? user.email ?? '',
      });
    }

    return createProfileIfMissing();
  }

  Future<UserProfileModel?> createProfileIfMissing() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _users.doc(user.uid);
    final doc = await ref.get();

    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromMap(doc.data()!);
    }

    final country = await _settings.getCountry();
    final currency = await _settings.getCurrency();

    final baseProfile =
        UserProfileModel.empty(
          uid: user.uid,
          email: user.email ?? '',
          country: country,
          currency: currency,
        ).copyWith(
          displayName: user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : null,
          photoUrl: user.photoURL ?? '',
        );

    final uniqueUsername = await generateUniqueUsername(baseProfile.username);

    final profile = baseProfile.copyWith(
      username: uniqueUsername,
      usernameLower: uniqueUsername.toLowerCase(),
    );

    await ref.set(profile.toMap(), SetOptions(merge: true));

    return profile;
  }

  Future<UserProfileModel> updateProfile({
    required UserProfileModel profile,
    required String displayName,
    required String username,
    required String bio,
    required String country,
    String? city,
    required String currency,
    required bool isCreator,
    String? photoUrl,
  }) async {
    final cleanDisplayName = displayName.trim();
    final cleanUsername = sanitizeUsername(username);
    final cleanBio = bio.trim();

    if (cleanDisplayName.length < 2) {
      throw Exception('El nombre debe tener al menos 2 caracteres.');
    }

    if (cleanUsername.length < 3) {
      throw Exception('El username debe tener al menos 3 caracteres.');
    }

    if (cleanUsername.length > 24) {
      throw Exception('El username no puede superar 24 caracteres.');
    }

    if (cleanBio.length > 140) {
      throw Exception('La bio no puede superar 140 caracteres.');
    }

    final available = await isUsernameAvailable(
      username: cleanUsername,
      currentUid: profile.uid,
    );

    if (!available) {
      throw Exception('Este username ya está en uso.');
    }

    final updated = profile.copyWith(
      displayName: cleanDisplayName,
      username: cleanUsername,
      usernameLower: cleanUsername.toLowerCase(),
      bio: cleanBio,
      country: country.trim().isEmpty ? 'global' : country.trim(),
      city: city?.trim() ?? profile.city,
      currency: currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
      isCreator: isCreator,
      photoUrl: photoUrl ?? profile.photoUrl,
      updatedAt: DateTime.now(),
    );

    await _users
        .doc(profile.uid)
        .set(updated.toUpdateMap(), SetOptions(merge: true));

    try {
      final token = await _auth.getIdToken();
      if (token != null && token.trim().isNotEmpty) {
        await _api.put(
          '${ApiEndpoints.profiles}/me',
          body: {
            'display_name': updated.displayName,
            'username': updated.username,
            'bio': updated.bio,
            'country': updated.country,
            'city': updated.city,
            'currency': updated.currency,
            'photo_url': updated.photoUrl,
            'is_creator': updated.isCreator,
          },
          extraHeaders: {'Authorization': 'Bearer ${token.trim()}'},
          timeout: const Duration(seconds: 20),
        );
      }
    } catch (_) {}

    await _settings.setCountry(updated.country);
    await _settings.setCurrency(updated.currency);

    return updated;
  }

  Future<String> uploadProfileImage({
    required String uid,
    required XFile image,
  }) async {
    final Uint8List bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('La imagen está vacía.');
    }

    final ref = _storage.ref().child('users/$uid/profile/avatar.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uid': uid, 'source': 'ofertix_profile'},
    );

    await ref.putData(bytes, metadata);

    return ref.getDownloadURL();
  }

  Future<bool> isUsernameAvailable({
    required String username,
    required String currentUid,
  }) async {
    final clean = sanitizeUsername(username).toLowerCase();

    final query = await _users
        .where('username_lower', isEqualTo: clean)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return true;

    final foundUid = query.docs.first.id;
    return foundUid == currentUid;
  }

  Future<String> generateUniqueUsername(String base) async {
    final cleanBase = sanitizeUsername(base).isEmpty
        ? 'ofertix_user'
        : sanitizeUsername(base);

    var candidate = cleanBase;
    var counter = 1;

    while (true) {
      final available = await isUsernameAvailable(
        username: candidate,
        currentUid: _auth.currentUserId ?? '',
      );

      if (available) return candidate;

      counter++;
      candidate = '$cleanBase$counter';

      if (candidate.length > 24) {
        candidate =
            '${cleanBase.substring(0, cleanBase.length > 18 ? 18 : cleanBase.length)}$counter';
      }
    }
  }

  Future<UserProfileModel?> getProfileById(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    final doc = await _users.doc(cleanUid).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    return UserProfileModel.fromMap({
      ...data,
      'uid': data['uid'] ?? cleanUid,
      'email': data['email'] ?? '',
    });
  }

  Future<UserIdentity?> getPublicIdentity(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    try {
      final decoded = await _api.get(
        '${ApiEndpoints.profiles}/$cleanUid/public',
      );
      if (decoded is Map) {
        return UserIdentity.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}

    final profile = await getProfileById(cleanUid);
    return profile == null ? null : UserIdentity.fromProfile(profile);
  }

  Future<List<MarketplaceItem>> getSellItems({
    required String sellerId,
    int limit = 24,
  }) async {
    final cleanSellerId = sellerId.trim();
    if (cleanSellerId.isEmpty) return [];

    try {
      final decoded = await _api.get(
        '${ApiEndpoints.profiles}/$cleanSellerId/sell-items',
        queryParameters: {'limit': limit.clamp(1, 50)},
      );
      final rawItems = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (rawItems is List) {
        return rawItems
            .whereType<Map>()
            .map(
              (item) => MarketplaceItem.fromMap(
                Map<String, dynamic>.from(item),
                item['id']?.toString() ?? '',
              ),
            )
            .toList();
      }
    } catch (_) {}

    final query = await _db
        .collection('marketplace_items')
        .where('sellerId', isEqualTo: cleanSellerId)
        .limit(limit.clamp(1, 50))
        .get();

    return query.docs
        .map((doc) => MarketplaceItem.fromMap(doc.data(), doc.id))
        .where((item) => item.isActive)
        .toList();
  }

  Future<bool> followProfile(String uid) async {
    final token = await _auth.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para seguir perfiles.');
    }

    final decoded = await _api.post(
      '${ApiEndpoints.profiles}/${uid.trim()}/follow',
      extraHeaders: {'Authorization': 'Bearer ${token.trim()}'},
      timeout: const Duration(seconds: 20),
    );
    if (decoded is Map) return decoded['is_following'] == true;
    return true;
  }

  Future<List<SmartReelModel>> getCreatorReels({
    required String creatorId,
    int limit = 24,
  }) async {
    final cleanCreatorId = creatorId.trim();
    if (cleanCreatorId.isEmpty) return [];

    final query = await _db
        .collection('smart_reels')
        .where('creator_id', isEqualTo: cleanCreatorId)
        .where('status', isEqualTo: 'approved')
        .limit(limit.clamp(1, 50))
        .get();

    final reels = query.docs
        .map((doc) {
          final data = doc.data();
          return SmartReelModel.fromJson({...data, 'id': data['id'] ?? doc.id});
        })
        .where((reel) => reel.bestVideoUrl.isNotEmpty)
        .toList();

    reels.sort((a, b) {
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return reels;
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? const <String, dynamic>{};
    if (claims['admin'] == true || claims['role'] == 'admin') {
      return true;
    }

    final doc = await _users.doc(user.uid).get();
    final data = doc.data();
    if (data == null) return false;

    final role = data['role']?.toString().toLowerCase().trim() ?? '';
    return data['isAdmin'] == true ||
        data['admin'] == true ||
        role == 'admin' ||
        role == 'owner';
  }

  String sanitizeUsername(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (cleaned.length > 24) return cleaned.substring(0, 24);
    return cleaned;
  }
}
