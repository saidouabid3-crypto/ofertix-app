import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool notificationsEnabled = true;

  void setNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }
}
