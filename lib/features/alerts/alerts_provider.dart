import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'alerts_repository.dart';

class AlertsProvider extends ChangeNotifier {
  final AlertsRepository _repository = AlertsRepository();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts = [];

  bool isLoading = true;

  StreamSubscription? _sub;

  Future<void> initialize() async {
    _sub?.cancel();

    _sub = _repository.alerts().listen((snapshot) {
      alerts = snapshot.docs;

      isLoading = false;

      notifyListeners();
    });
  }

  Future<void> createAlert({
    required String productId,
    required double targetPrice,
  }) async {
    await _repository.createAlert(
      productId: productId,
      targetPrice: targetPrice,
    );
  }

  Future<void> deleteAlert(String alertId) async {
    await _repository.deleteAlert(alertId);
  }

  @override
  void dispose() {
    _sub?.cancel();

    super.dispose();
  }
}
