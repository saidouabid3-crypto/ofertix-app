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
  final String city;
  final String currency;
  final String role;
  final bool isCreator;
  final bool isVerified;
  final bool sellerVerified;
  final int followersCount;
  final int followingCount;
  final int reelsCount;
  final int sellItemsCount;
  final int totalLikes;
  final double ratingAverage;
  final int ratingCount;
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
    required this.city,
    required this.currency,
    required this.role,
    required this.isCreator,
    required this.isVerified,
    required this.sellerVerified,
    required this.followersCount,
    required this.followingCount,
    required this.reelsCount,
    required this.sellItemsCount,
    required this.totalLikes,
    required this.ratingAverage,
    required this.ratingCount,
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
      displayName: baseName.isEmpty ? 'User' : baseName,
      username: safeUsername,
      usernameLower: safeUsername.toLowerCase(),
      photoUrl: '',
      bio: '',
      country: country,
      city: '',
      currency: currency,
      role: 'user',
      isCreator: false,
      isVerified: false,
      sellerVerified: false,
      followersCount: 0,
      followingCount: 0,
      reelsCount: 0,
      sellItemsCount: 0,
      totalLikes: 0,
      ratingAverage: 0,
      ratingCount: 0,
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
      city: (map['city'] ?? '').toString(),
      currency: (map['currency'] ?? 'EUR').toString(),
      role: (map['role'] ?? 'user').toString(),
      isCreator: map['is_creator'] == true || map['isCreator'] == true,
      isVerified:
          map['is_verified'] == true ||
          map['isVerified'] == true ||
          map['verified'] == true,
      sellerVerified:
          map['seller_verified'] == true || map['sellerVerified'] == true,
      followersCount: _toInt(map['followers_count'] ?? map['followersCount']),
      followingCount: _toInt(map['following_count'] ?? map['followingCount']),
      reelsCount: _toInt(map['reels_count'] ?? map['reelsCount']),
      sellItemsCount: _toInt(map['sell_items_count'] ?? map['sellItemsCount']),
      totalLikes: _toInt(map['total_likes'] ?? map['totalLikes']),
      ratingAverage: _toDouble(map['rating_average'] ?? map['ratingAverage']),
      ratingCount: _toInt(map['rating_count'] ?? map['ratingCount']),
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
      'city': city,
      'currency': currency,
      'role': role,
      'is_creator': isCreator,
      'is_verified': isVerified,
      'seller_verified': sellerVerified,
      'followers_count': followersCount,
      'following_count': followingCount,
      'reels_count': reelsCount,
      'sell_items_count': sellItemsCount,
      'total_likes': totalLikes,
      'rating_average': ratingAverage,
      'rating_count': ratingCount,
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
      'city': city,
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
    String? city,
    String? currency,
    String? role,
    bool? isCreator,
    bool? isVerified,
    bool? sellerVerified,
    int? followersCount,
    int? followingCount,
    int? reelsCount,
    int? sellItemsCount,
    int? totalLikes,
    double? ratingAverage,
    int? ratingCount,
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
      city: city ?? this.city,
      currency: currency ?? this.currency,
      role: role ?? this.role,
      isCreator: isCreator ?? this.isCreator,
      isVerified: isVerified ?? this.isVerified,
      sellerVerified: sellerVerified ?? this.sellerVerified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reelsCount: reelsCount ?? this.reelsCount,
      sellItemsCount: sellItemsCount ?? this.sellItemsCount,
      totalLikes: totalLikes ?? this.totalLikes,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
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
