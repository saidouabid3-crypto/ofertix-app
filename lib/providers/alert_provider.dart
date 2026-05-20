import 'package:flutter/material.dart';

class AlertProvider extends ChangeNotifier {
  bool priceAlertsEnabled = true;

  void setPriceAlerts(bool value) {
    priceAlertsEnabled = value;
    notifyListeners();
  }
}
