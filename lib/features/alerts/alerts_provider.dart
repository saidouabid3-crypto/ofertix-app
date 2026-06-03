import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product.dart';
import '../../repositories/alerts_repository.dart';
import '../../services/auth_service.dart';

class AlertsProvider extends ChangeNotifier {
  final AlertsRepository _repository = AlertsRepository.instance;
  final AuthService _auth = AuthService.instance;

  bool isLoading = false;
  bool isDeleting = false;

  String? error;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts = [];

  StreamSubscription<List<QueryDocumentSnapshot<Map<String, dynamic>>>>?
  _subscription;

  // Resolved once per session in initialize().
  String _userId = '';

  static const String _guestIdKey = 'ofertix_guest_id';

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

  Future<void> initialize() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.initializeNotifications();

      _userId = await _resolveUserId();

      await _subscription?.cancel();

      _subscription = _repository
          .watchAlerts(userId: _userId)
          .listen(
            (items) {
              alerts = items;
              isLoading = false;
              error = null;
              notifyListeners();
            },
            onError: (e) {
              error = e.toString();
              isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createProductAlert({
    required Product product,
    required double targetPrice,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _userId.isNotEmpty ? _userId : await _resolveUserId();

      final id = await _repository.createProductAlert(
        product: product,
        targetPrice: targetPrice,
        userId: userId,
      );

      isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> createAiAlert({
    required String productQuery,
    required double targetPrice,
  }) async {
    final cleanQuery = productQuery.trim();

    if (cleanQuery.isEmpty || targetPrice <= 0) {
      return null;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _userId.isNotEmpty ? _userId : await _resolveUserId();

      final id = await _repository.createAiAlert(
        productQuery: cleanQuery,
        targetPrice: targetPrice,
        userId: userId,
      );

      isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    isDeleting = true;
    error = null;
    notifyListeners();

    final ok = await _repository.deleteAlert(alertId);

    if (!ok) {
      error = 'Could not delete alert';
    }

    isDeleting = false;
    notifyListeners();

    return ok;
  }

  Future<bool> setAlertActive({
    required String alertId,
    required bool active,
  }) async {
    final ok = await _repository.setAlertActive(
      alertId: alertId,
      active: active,
    );

    if (!ok) {
      error = 'Could not update alert';
      notifyListeners();
    }

    return ok;
  }

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final userId = _userId.isNotEmpty ? _userId : await _resolveUserId();
      alerts = await _repository.getAlertsOnce(userId: userId);
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
