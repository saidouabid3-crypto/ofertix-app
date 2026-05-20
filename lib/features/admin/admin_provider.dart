import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  bool isLoading = false;

  int totalUsers = 12480;
  int totalClicks = 58291;
  int totalOrders = 3912;

  double revenue = 12840.50;

  List<String> topSearches = [
    'iPhone 15',
    'Gaming Laptop',
    'AirPods',
    'Nike',
    'Smart TV',
  ];

  Future<void> refreshDashboard() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    totalUsers += 12;
    totalClicks += 104;
    revenue += 84.5;

    isLoading = false;
    notifyListeners();
  }
}
