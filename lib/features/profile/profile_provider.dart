import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  User? user;

  String country = 'ES';

  String currency = 'EUR';

  bool isLoading = true;

  Future<void> initialize() async {
    user = _repository.currentUser;

    country = await _repository.getCountry();

    currency = await _repository.getCurrency();

    isLoading = false;

    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}
