import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';
import 'auth_service.dart';

class SocialProfileService {
  SocialProfileService._();

  static final SocialProfileService instance = SocialProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _follows =>
      _db.collection('user_follows');

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('messages');

  String? get currentUserId => _auth.currentUserId;

  Future<UserProfileModel?> getProfileById(String uid) async {
    if (uid.trim().isEmpty) return null;

    final doc = await _users.doc(uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return UserProfileModel.fromMap({...doc.data()!, 'uid': doc.id});
  }

  Future<bool> isFollowing(String creatorId) async {
    final followerId = currentUserId;

    if (followerId == null || creatorId.trim().isEmpty) return false;
    if (followerId == creatorId) return false;

    final followId = _followDocId(followerId: followerId, creatorId: creatorId);

    final doc = await _follows.doc(followId).get();

    return doc.exists;
  }

  Future<bool> toggleFollow(String creatorId) async {
    final followerId = currentUserId;

    if (followerId == null) {
      throw Exception('Debes iniciar sesión para seguir perfiles.');
    }

    if (followerId == creatorId) {
      throw Exception('No puedes seguir tu propio perfil.');
    }

    final followId = _followDocId(followerId: followerId, creatorId: creatorId);

    final followRef = _follows.doc(followId);
    final creatorRef = _users.doc(creatorId);
    final followerRef = _users.doc(followerId);

    return _db.runTransaction<bool>((transaction) async {
      final followSnap = await transaction.get(followRef);

      if (followSnap.exists) {
        transaction.delete(followRef);
        transaction.set(creatorRef, {
          'followers_count': FieldValue.increment(-1),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(followerRef, {
          'following_count': FieldValue.increment(-1),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return false;
      }

      transaction.set(followRef, {
        'id': followId,
        'follower_id': followerId,
        'creator_id': creatorId,
        'created_at': FieldValue.serverTimestamp(),
      });

      transaction.set(creatorRef, {
        'followers_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(followerRef, {
        'following_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> creatorReelsStream(
    String creatorId,
  ) {
    return _db
        .collection('smart_reels')
        .where('creator_id', isEqualTo: creatorId)
        .orderBy('created_at', descending: true)
        .limit(60)
        .snapshots();
  }

  Future<String> openConversation({
    required String creatorId,
    required String reelId,
    required String reelTitle,
  }) async {
    final buyerId = currentUserId;

    if (buyerId == null) {
      throw Exception('Debes iniciar sesión para enviar mensajes.');
    }

    if (buyerId == creatorId) {
      throw Exception('Este reel es tuyo.');
    }

    final conversationId = _conversationDocId(
      buyerId: buyerId,
      creatorId: creatorId,
      reelId: reelId,
    );

    final ref = _conversations.doc(conversationId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'id': conversationId,
        'buyer_id': buyerId,
        'creator_id': creatorId,
        'reel_id': reelId,
        'reel_title': reelTitle,
        'last_message': '',
        'last_message_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'participants': [buyerId, creatorId],
      });
    }

    return conversationId;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    final senderId = currentUserId;

    if (senderId == null) {
      throw Exception('Debes iniciar sesión para enviar mensajes.');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) return;

    final messageRef = _messages.doc();

    await _db.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'id': messageRef.id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'text': cleanText,
        'type': 'text',
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      transaction.set(_conversations.doc(conversationId), {
        'last_message': cleanText,
        'last_message_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
    String conversationId,
  ) {
    return _messages
        .where('conversation_id', isEqualTo: conversationId)
        .orderBy('created_at', descending: true)
        .limit(80)
        .snapshots();
  }

  String _followDocId({required String followerId, required String creatorId}) {
    return '${followerId}_$creatorId';
  }

  String _conversationDocId({
    required String buyerId,
    required String creatorId,
    required String reelId,
  }) {
    return '${buyerId}_${creatorId}_$reelId';
  }
}
