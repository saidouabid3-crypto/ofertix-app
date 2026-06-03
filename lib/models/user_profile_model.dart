import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String usernameLower;
  final String photoUrl;
  final String bio;
  final String country;
  final String currency;
  final bool isCreator;
  final int followersCount;
  final int followingCount;
  final int reelsCount;
  final int totalLikes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    required this.usernameLower,
    required this.photoUrl,
    required this.bio,
    required this.country,
    required this.currency,
    required this.isCreator,
    required this.followersCount,
    required this.followingCount,
    required this.reelsCount,
    required this.totalLikes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.empty({
    required String uid,
    required String email,
    String country = 'global',
    String currency = 'EUR',
  }) {
    final baseName = email.contains('@')
        ? email.split('@').first
        : 'ofertix_user';
    final safeUsername = _cleanUsername(baseName);

    return UserProfileModel(
      uid: uid,
      email: email,
      displayName: baseName.isEmpty ? 'Ofertix User' : baseName,
      username: safeUsername,
      usernameLower: safeUsername.toLowerCase(),
      photoUrl: '',
      bio: '',
      country: country,
      currency: currency,
      isCreator: false,
      followersCount: 0,
      followingCount: 0,
      reelsCount: 0,
      totalLikes: 0,
      createdAt: null,
      updatedAt: null,
    );
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['displayName'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      usernameLower: (map['username_lower'] ?? map['usernameLower'] ?? '')
          .toString(),
      photoUrl: (map['photo_url'] ?? map['photoUrl'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      country: (map['country'] ?? 'global').toString(),
      currency: (map['currency'] ?? 'EUR').toString(),
      isCreator: map['is_creator'] == true || map['isCreator'] == true,
      followersCount: _toInt(map['followers_count'] ?? map['followersCount']),
      followingCount: _toInt(map['following_count'] ?? map['followingCount']),
      reelsCount: _toInt(map['reels_count'] ?? map['reelsCount']),
      totalLikes: _toInt(map['total_likes'] ?? map['totalLikes']),
      createdAt: _toDate(map['created_at'] ?? map['createdAt']),
      updatedAt: _toDate(map['updated_at'] ?? map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'username': username,
      'username_lower': usernameLower,
      'photo_url': photoUrl,
      'bio': bio,
      'country': country,
      'currency': currency,
      'is_creator': isCreator,
      'followers_count': followersCount,
      'following_count': followingCount,
      'reels_count': reelsCount,
      'total_likes': totalLikes,
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'display_name': displayName,
      'username': username,
      'username_lower': usernameLower,
      'photo_url': photoUrl,
      'bio': bio,
      'country': country,
      'currency': currency,
      'is_creator': isCreator,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  UserProfileModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? usernameLower,
    String? photoUrl,
    String? bio,
    String? country,
    String? currency,
    bool? isCreator,
    int? followersCount,
    int? followingCount,
    int? reelsCount,
    int? totalLikes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final nextUsername = username ?? this.username;

    return UserProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: nextUsername,
      usernameLower: usernameLower ?? nextUsername.toLowerCase(),
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      isCreator: isCreator ?? this.isCreator,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reelsCount: reelsCount ?? this.reelsCount,
      totalLikes: totalLikes ?? this.totalLikes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _cleanUsername(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (cleaned.length < 3) return 'ofertix_user';
    if (cleaned.length > 24) return cleaned.substring(0, 24);
    return cleaned;
  }
}
