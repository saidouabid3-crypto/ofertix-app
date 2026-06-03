import 'package:firebase_auth/firebase_auth.dart';

import 'api_service.dart';
import 'fcm_token_service.dart';
import 'firebase_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseService.instance.auth;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => currentUser?.uid;

  bool get isLoggedIn => currentUser != null;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _syncToken();

    final uid = credential.user?.uid;
    if (uid != null) {
      // Fire-and-forget — never blocks login flow.
      FcmTokenService.instance.registerForUser(uid);
    }

    return credential;
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _syncToken();

    final uid = credential.user?.uid;
    if (uid != null) {
      // Fire-and-forget — never blocks registration flow.
      FcmTokenService.instance.registerForUser(uid);
    }

    return credential;
  }

  Future<void> logout() async {
    ApiService.instance.clearToken();

    await _auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String?> getIdToken() async {
    return await currentUser?.getIdToken();
  }

  Future<void> _syncToken() async {
    final token = await getIdToken();

    ApiService.instance.setToken(token);
  }
}
