import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification_model.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FirebaseFirestore _db = FirebaseService.instance.firestore;

  String? get _uid => AuthService.instance.currentUserId;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  /// Streams the current user's notifications ordered by createdAt descending.
  /// Requires Firestore composite index: notifications(userId ASC, createdAt DESC).
  /// Returns empty stream for unauthenticated users.
  Stream<List<AppNotificationModel>> watchNotifications({int limit = 50}) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();

    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotificationModel.fromDoc).toList());
  }

  Future<int> getUnreadCount() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return 0;
    try {
      final snap = await _col
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    try {
      await _col.doc(notificationId).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final snap = await _col
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    try {
      await _col.doc(notificationId).delete();
    } catch (_) {}
  }
}
