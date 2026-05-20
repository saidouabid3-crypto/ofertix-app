import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class ProfileRepository {
  final AuthService _authService = AuthService();

  User? get currentUser {
    return _authService.currentUser;
  }

  Future<String> getCountry() {
    return SettingsService.country();
  }

  Future<String> getCurrency() {
    return SettingsService.currency();
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
