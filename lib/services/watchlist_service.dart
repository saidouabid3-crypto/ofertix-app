import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

/// Firestore-backed watchlist service.
///
/// Uses the same [_guestIdKey] as FavoriteService so a guest always has
/// a single device-scoped identity across watchlist, favorites, and alerts.
class WatchlistService {
  WatchlistService._();

  static final WatchlistService instance = WatchlistService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final AuthService _auth = AuthService.instance;

  // Shared guest-id key — same as FavoriteService so one ID per device.
  static const String _guestIdKey = 'ofertix_guest_id';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('watchlist');

  Future<String> _resolveUserId() async {
    final uid = _auth.currentUserId;
    if (uid != null && uid.trim().isNotEmpty) return uid.trim();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestIdKey);
    if (existing != null && existing.isNotEmpty) return 'guest_$existing';
    final newId = _generateGuestId();
    await prefs.setString(_guestIdKey, newId);
    return 'guest_$newId';
  }

  static String _generateGuestId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _docId(String userId, String productId) {
    final safe = productId
        .trim()
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('#', '_')
        .replaceAll('?', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('*', '_');
    return '${userId}_$safe';
  }

  Future<bool> isWatching(String productId) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return false;
    final userId = await _resolveUserId();
    try {
      final doc = await _collection.doc(_docId(userId, cleanId)).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleWatch(Product product) async {
    final cleanId = product.id.trim();
    if (cleanId.isEmpty) return false;
    final watching = await isWatching(cleanId);
    if (watching) {
      await removeWatch(cleanId);
      return false;
    }
    await addWatch(product);
    return true;
  }

  Future<bool> addWatch(Product product) async {
    final cleanId = product.id.trim();
    if (cleanId.isEmpty) return false;
    final userId = await _resolveUserId();
    try {
      await _collection.doc(_docId(userId, cleanId)).set({
        'userId': userId,
        'productId': cleanId,
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image': product.image,
        'store': product.store,
        'category': product.category,
        'affiliateUrl': product.affiliateUrl,
        'country': product.country,
        'currency': product.currency,
        'oldPrice': product.oldPrice,
        'newPrice': product.newPrice,
        'discount': product.discount,
        'isOnline': product.isOnline,
        'isHot': product.isHot,
        'isTrending': product.isTrending,
        'featured': product.featured,
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

  /// Returns all watchlist products for the current user, newest first.
  Future<List<Product>> getWatchlistOnce() async {
    try {
      final userId = await _resolveUserId();
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final pid =
            data['productId']?.toString() ??
            data['id']?.toString() ??
            doc.id;
        return Product.fromMap(data, pid);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> removeWatch(String productId) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return false;
    final userId = await _resolveUserId();
    try {
      await _collection.doc(_docId(userId, cleanId)).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
