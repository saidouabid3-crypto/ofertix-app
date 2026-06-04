import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/alerts_repository.dart';
import '../../services/auth_service.dart';
import '../../services/price_alert_checker_service.dart';

/// Price alerts provider. Requires Firebase authentication.
/// Guests see an empty state — no Firestore reads or writes are performed.
class AlertsProvider extends ChangeNotifier {
  final AlertsRepository _repository = AlertsRepository.instance;
  final AuthService _auth = AuthService.instance;

  bool isLoading = false;
  bool isChecking = false;
  bool isDeleting = false;
  String? error;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts = [];

  StreamSubscription<List<QueryDocumentSnapshot<Map<String, dynamic>>>>?
      _subscription;

  String? get _uid => _auth.currentUserId?.trim();
  bool get _isAuthenticated {
    final uid = _uid;
    return uid != null && uid.isNotEmpty;
  }

  Future<void> initialize() async {
    // Guests cannot use price alerts.
    if (!_isAuthenticated) {
      isLoading = false;
      alerts = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.initializeNotifications();
      await _subscription?.cancel();

      _subscription = _repository
          .watchAlerts(userId: _uid!)
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
    if (!_isAuthenticated) return null;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final id = await _repository.createProductAlert(
        product: product,
        targetPrice: targetPrice,
        userId: _uid!,
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
    if (!_isAuthenticated) return null;

    final cleanQuery = productQuery.trim();
    if (cleanQuery.isEmpty || targetPrice <= 0) return null;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final id = await _repository.createAiAlert(
        productQuery: cleanQuery,
        targetPrice: targetPrice,
        userId: _uid!,
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
    if (!ok) error = 'Could not delete alert';
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

  Future<bool> updateTargetPrice({
    required String alertId,
    required double targetPrice,
  }) async {
    final ok = await _repository.updateTargetPrice(
      alertId: alertId,
      targetPrice: targetPrice,
    );
    if (!ok) {
      error = 'Could not update alert';
      notifyListeners();
    }
    return ok;
  }

  /// Runs the client-side price checker for the current user's active alerts.
  /// Fetches latest prices from the products collection and triggers local
  /// notifications + updates alert documents for any price drops.
  Future<void> checkAlerts() async {
    if (!_isAuthenticated || isChecking) return;
    isChecking = true;
    error = null;
    notifyListeners();
    try {
      await PriceAlertCheckerService.instance.checkActiveAlerts(
        userId: _uid!,
      );
    } catch (_) {}
    isChecking = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_isAuthenticated) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      alerts = await _repository.getAlertsOnce(userId: _uid!);
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
