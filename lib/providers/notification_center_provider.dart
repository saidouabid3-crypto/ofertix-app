import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification_model.dart';
import '../services/app_notification_service.dart';
import '../services/auth_service.dart';

enum NotificationCenterState { loading, loaded, empty, error, loginRequired }

class NotificationCenterProvider extends ChangeNotifier {
  final AppNotificationService _service = AppNotificationService.instance;

  NotificationCenterState state = NotificationCenterState.loading;
  List<AppNotificationModel> notifications = [];
  String? errorMessage;
  StreamSubscription<List<AppNotificationModel>>? _sub;

  int get unreadCount => notifications.where((n) => !n.read).length;
  bool get isLoggedIn => AuthService.instance.isLoggedIn;

  void initialize() {
    if (!isLoggedIn) {
      state = NotificationCenterState.loginRequired;
      notifyListeners();
      return;
    }
    _subscribe();
  }

  void _subscribe() {
    state = NotificationCenterState.loading;
    errorMessage = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.watchNotifications().listen(
      (list) {
        notifications = list;
        state = list.isEmpty
            ? NotificationCenterState.empty
            : NotificationCenterState.loaded;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        state = NotificationCenterState.error;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _service.deleteNotification(id);
    notifications.removeWhere((n) => n.id == id);
    if (notifications.isEmpty && state == NotificationCenterState.loaded) {
      state = NotificationCenterState.empty;
    }
    notifyListeners();
  }

  void retry() => _subscribe();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
