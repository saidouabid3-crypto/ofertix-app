import 'package:flutter/material.dart';

class ScanProvider extends ChangeNotifier {
  String? lastCode;
  bool isScanning = false;

  void startScanning() {
    isScanning = true;
    notifyListeners();
  }

  void stopScanning() {
    isScanning = false;
    notifyListeners();
  }

  void setCode(String code) {
    lastCode = code;
    isScanning = false;
    notifyListeners();
  }
}
