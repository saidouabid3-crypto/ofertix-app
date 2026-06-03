import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class FavoriteService {
  FavoriteService._();

  static final FavoriteService instance = FavoriteService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final AuthService _authService = AuthService.instance;

  static const String _guestIdKey = 'ofertix_guest_id';

  CollectionReference<Map<String, dynamic>> get _favoritesCollection {
    return _firestore.collection('favorites');
  }

  /// Returns the Firebase UID for authenticated users.
  /// For guests, returns a persistent device-scoped id (guest_{random32hex})
  /// stored in SharedPreferences so each device has its own isolated favorites.
  Future<String> _resolveUserId() async {
    final uid = _authService.currentUserId;
    if (uid != null && uid.trim().isNotEmpty) {
      return uid.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestIdKey);
    if (existing != null && existing.isNotEmpty) {
      return 'guest_$existing';
    }
    final newId = _generateGuestId();
    await prefs.setString(_guestIdKey, newId);
    return 'guest_$newId';
  }

  static String _generateGuestId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _safeDocId({required String userId, required String productId}) {
    final safeProductId = productId
        .trim()
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('#', '_')
        .replaceAll('?', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('*', '_');

    return '${userId}_$safeProductId';
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchFavorites() async* {
    final userId = await _resolveUserId();

    yield* _favoritesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;

          docs.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          return docs;
        });
  }

  Stream<Set<String>> watchFavoriteIds() {
    return watchFavorites().map((docs) {
      return docs
          .map((doc) => doc.data()['productId']?.toString() ?? '')
          .where((id) => id.trim().isNotEmpty)
          .toSet();
    });
  }

  Future<List<Product>> getFavoritesOnce() async {
    try {
      final userId = await _resolveUserId();

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final docs = snapshot.docs;

      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      return docs.map(_productFromFavoriteDoc).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Set<String>> getFavoriteIdsOnce() async {
    try {
      final userId = await _resolveUserId();

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['productId']?.toString() ?? '')
          .where((id) => id.trim().isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> isFavorite(String productId) async {
    final cleanId = productId.trim();

    if (cleanId.isEmpty) return false;

    final userId = await _resolveUserId();
    final docId = _safeDocId(userId: userId, productId: cleanId);

    try {
      final doc = await _favoritesCollection.doc(docId).get();

      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(Product product) async {
    final cleanId = product.id.trim();

    if (cleanId.isEmpty) return false;

    final saved = await isFavorite(cleanId);

    if (saved) {
      await removeFavorite(cleanId);
      return false;
    }

    await addFavorite(product);
    return true;
  }

  Future<bool> addFavorite(Product product) async {
    final cleanId = product.id.trim();

    if (cleanId.isEmpty) return false;

    final userId = await _resolveUserId();
    final docId = _safeDocId(userId: userId, productId: cleanId);

    try {
      await _favoritesCollection.doc(docId).set({
        'userId': userId,
        'productId': cleanId,
        'productName': product.name,
        'productImage': product.image,
        'store': product.store,
        'currentPrice': product.newPrice,

        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image': product.image,
        'category': product.category,
        'affiliateUrl': product.affiliateUrl,
        'country': product.country,
        'oldPrice': product.oldPrice,
        'newPrice': product.newPrice,
        'discount': product.discount,
        'isOnline': product.isOnline,
        'isGlobal': product.isGlobal,
        'featured': product.featured,
        'isHot': product.isHot,
        'isTrending': product.isTrending,
        'sponsored': product.sponsored,
        'views': product.views,
        'clicks': product.clicks,
        'sales': product.sales,
        'lat': product.lat,
        'lng': product.lng,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFavorite(String productId) async {
    final cleanId = productId.trim();

    if (cleanId.isEmpty) return false;

    final userId = await _resolveUserId();
    final docId = _safeDocId(userId: userId, productId: cleanId);

    try {
      await _favoritesCollection.doc(docId).delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearFavorites() async {
    try {
      final userId = await _resolveUserId();

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return true;
    } catch (_) {
      return false;
    }
  }

  Product _productFromFavoriteDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final productId =
        data['productId']?.toString() ?? data['id']?.toString() ?? doc.id;

    final map = <String, dynamic>{
      'id': productId,
      'name':
          data['name'] ??
          data['productName'] ??
          data['productId'] ??
          'Favorite product',
      'description': data['description'] ?? '',
      'image': data['image'] ?? data['productImage'] ?? '',
      'store': data['store'] ?? '',
      'category': data['category'] ?? '',
      'affiliateUrl': data['affiliateUrl'] ?? '',
      'country': data['country'] ?? 'global',
      'oldPrice': data['oldPrice'] ?? data['currentPrice'] ?? 0,
      'newPrice': data['newPrice'] ?? data['currentPrice'] ?? 0,
      'discount': data['discount'] ?? 0,
      'isOnline': data['isOnline'] ?? true,
      'isGlobal': data['isGlobal'] ?? false,
      'featured': data['featured'] ?? false,
      'isHot': data['isHot'] ?? false,
      'isTrending': data['isTrending'] ?? false,
      'sponsored': data['sponsored'] ?? false,
      'views': data['views'] ?? 0,
      'clicks': data['clicks'] ?? 0,
      'sales': data['sales'] ?? 0,
      'lat': data['lat'] ?? 0.0,
      'lng': data['lng'] ?? 0.0,
    };

    return Product.fromMap(map, productId);
  }
}
