import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

/// Watchlist service with split guest/auth behavior:
///
/// - **Authenticated users** → Firestore `watchlist/{uid}_{productId}`
/// - **Guest users** → SharedPreferences local storage only (no Firestore writes)
///
/// After login, call [migrateLocalToFirestore] once to move locally-saved items
/// into the authenticated user's Firestore watchlist.
class WatchlistService {
  WatchlistService._();

  static final WatchlistService instance = WatchlistService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final AuthService _auth = AuthService.instance;

  // SharedPreferences key for guest-local watchlist (v1 to allow future migration).
  static const String _localKey = 'ofertix_local_watchlist_v1';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('watchlist');

  // ─── Auth helpers ─────────────────────────────────────────────────────────

  bool get _isAuthenticated {
    final uid = _auth.currentUserId;
    return uid != null && uid.trim().isNotEmpty;
  }

  String? get _uid => _auth.currentUserId?.trim();

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

  // ─── Local (guest) storage ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _readLocalRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _writeLocalRaw(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(items));
    } catch (_) {}
  }

  Future<bool> _isWatchingLocal(String productId) async {
    final items = await _readLocalRaw();
    return items.any((m) => m['id']?.toString() == productId);
  }

  Future<bool> _addLocal(Product product) async {
    final items = await _readLocalRaw();
    if (items.any((m) => m['id']?.toString() == product.id)) return true;
    items.add({
      'id': product.id,
      'name': product.name,
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
      'isGlobal': product.isGlobal,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await _writeLocalRaw(items);
    return true;
  }

  Future<bool> _removeLocal(String productId) async {
    final items = await _readLocalRaw();
    items.removeWhere((m) => m['id']?.toString() == productId);
    await _writeLocalRaw(items);
    return true;
  }

  Future<List<Product>> _getLocalProducts() async {
    final items = await _readLocalRaw();
    return items.map((m) {
      final id = m['id']?.toString() ?? '';
      return Product.fromMap(m, id);
    }).toList();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<bool> isWatching(String productId) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return false;

    if (_isAuthenticated) {
      try {
        final doc = await _collection.doc(_docId(_uid!, cleanId)).get();
        return doc.exists;
      } catch (_) {
        return false;
      }
    } else {
      return _isWatchingLocal(cleanId);
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

    if (_isAuthenticated) {
      try {
        await _collection.doc(_docId(_uid!, cleanId)).set({
          'userId': _uid,
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
    } else {
      return _addLocal(product);
    }
  }

  Future<bool> removeWatch(String productId) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return false;

    if (_isAuthenticated) {
      try {
        await _collection.doc(_docId(_uid!, cleanId)).delete();
        return true;
      } catch (_) {
        return false;
      }
    } else {
      return _removeLocal(cleanId);
    }
  }

  /// Returns all watchlist products for the current user, newest first.
  Future<List<Product>> getWatchlistOnce() async {
    if (_isAuthenticated) {
      try {
        final snapshot = await _collection
            .where('userId', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final pid = data['productId']?.toString() ??
              data['id']?.toString() ??
              doc.id;
          return Product.fromMap(data, pid);
        }).toList();
      } catch (_) {
        return [];
      }
    } else {
      return _getLocalProducts();
    }
  }

  // ─── Post-login migration ──────────────────────────────────────────────────

  /// Moves locally-saved guest watchlist items into the authenticated
  /// user's Firestore watchlist, then clears local storage.
  ///
  /// Call this once immediately after a successful login or registration.
  /// Safe to call even if there are no local items — exits early.
  Future<void> migrateLocalToFirestore() async {
    if (!_isAuthenticated) return;
    final localItems = await _readLocalRaw();
    if (localItems.isEmpty) return;

    for (final m in localItems) {
      try {
        final id = m['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        await _collection.doc(_docId(_uid!, id)).set({
          'userId': _uid,
          'productId': id,
          'id': id,
          'name': m['name'] ?? '',
          'description': '',
          'image': m['image'] ?? '',
          'store': m['store'] ?? '',
          'category': m['category'] ?? '',
          'affiliateUrl': m['affiliateUrl'] ?? '',
          'country': m['country'] ?? '',
          'currency': m['currency'] ?? 'EUR',
          'oldPrice': m['oldPrice'] ?? 0,
          'newPrice': m['newPrice'] ?? 0,
          'discount': m['discount'] ?? 0,
          'isOnline': m['isOnline'] ?? true,
          'isHot': m['isHot'] ?? false,
          'isTrending': m['isTrending'] ?? false,
          'featured': false,
          'sponsored': false,
          'views': 0,
          'clicks': 0,
          'sales': 0,
          'lat': 0.0,
          'lng': 0.0,
          'migratedFromGuest': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Never block login for a failed watchlist migration.
      }
    }

    // Clear local storage after successful migration.
    await _writeLocalRaw([]);
  }
}
