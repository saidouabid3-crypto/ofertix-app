import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthRepository {
  static final AuthRepository instance = AuthRepository();

  final AuthService _authService = AuthService();

  Stream<User?> get authStateChanges {
    return _authService.authStateChanges();
  }

  User? get currentUser {
    return _authService.currentUser;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _authService.register(email: email, password: password);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
