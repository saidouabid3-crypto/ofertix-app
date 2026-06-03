import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  // ── Instance API (singleton pattern — used by Batch 7-13 services) ─────────

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  User? get currentUser => auth.currentUser;
  String? get currentUserId => auth.currentUser?.uid;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> authStateChanges() => auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      firestore.collection(path);

  DocumentReference<Map<String, dynamic>> document(String path) =>
      firestore.doc(path);

  Future<String?> getDeviceToken() async {
    try {
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  // ── Static API (backward compat for 278f377 committed code) ────────────────

  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static String? get userId => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> products() =>
      db.collection('products');

  static CollectionReference<Map<String, dynamic>> users() =>
      db.collection('users');

  static CollectionReference<Map<String, dynamic>> alerts() =>
      db.collection('alerts');

  static CollectionReference<Map<String, dynamic>> analytics() =>
      db.collection('analytics');
}
