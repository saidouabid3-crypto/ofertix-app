import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static String? get userId => auth.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> products() {
    return db.collection('products');
  }

  static CollectionReference<Map<String, dynamic>> users() {
    return db.collection('users');
  }

  static CollectionReference<Map<String, dynamic>> alerts() {
    return db.collection('alerts');
  }

  static CollectionReference<Map<String, dynamic>> analytics() {
    return db.collection('analytics');
  }
}
