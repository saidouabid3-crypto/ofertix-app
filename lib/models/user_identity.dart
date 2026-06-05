import 'marketplace_item.dart';
import 'user_profile_model.dart';

class UserIdentity {
  final String uid;
  final String displayName;
  final String username;
  final String photoUrl;
  final String bio;
  final String country;
  final String city;
  final String currency;
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

  const UserIdentity({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.photoUrl,
    required this.bio,
    required this.country,
    required this.city,
    required this.currency,
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
  });

  factory UserIdentity.fromProfile(UserProfileModel profile) {
    return UserIdentity(
      uid: profile.uid,
      displayName: profile.displayName,
      username: profile.username,
      photoUrl: profile.photoUrl,
      bio: profile.bio,
      country: profile.country,
      city: profile.city,
      currency: profile.currency,
      isCreator: profile.isCreator,
      isVerified: profile.isVerified,
      sellerVerified: profile.sellerVerified,
      followersCount: profile.followersCount,
      followingCount: profile.followingCount,
      reelsCount: profile.reelsCount,
      sellItemsCount: profile.sellItemsCount,
      totalLikes: profile.totalLikes,
      ratingAverage: profile.ratingAverage,
      ratingCount: profile.ratingCount,
    );
  }

  factory UserIdentity.fromMap(Map<String, dynamic> map) {
    return UserIdentity.fromProfile(UserProfileModel.fromMap(map));
  }

  factory UserIdentity.fromMarketplaceItem(MarketplaceItem item) {
    return UserIdentity(
      uid: item.sellerId,
      displayName: item.sellerName,
      username: item.sellerUsername,
      photoUrl: item.sellerAvatarUrl,
      bio: '',
      country: item.sellerCountryCode,
      city: item.city,
      currency: item.currency,
      isCreator: false,
      isVerified: item.sellerVerified,
      sellerVerified: item.sellerVerified,
      followersCount: 0,
      followingCount: 0,
      reelsCount: 0,
      sellItemsCount: 0,
      totalLikes: 0,
      ratingAverage: 0,
      ratingCount: 0,
    );
  }

  String nameOr(String fallback) {
    final name = displayName.trim();
    if (name.isNotEmpty) return name;
    final handle = username.trim();
    if (handle.isNotEmpty) return '@$handle';
    return fallback;
  }

  String get handle {
    final value = username.trim();
    return value.isEmpty ? '' : '@$value';
  }

  String get avatarUrl => photoUrl.trim();

  bool get hasAvatar => avatarUrl.startsWith('http');

  String get locationLabel {
    final parts = [
      if (city.trim().isNotEmpty) city.trim(),
      if (country.trim().isNotEmpty && country != 'global')
        country.trim().toUpperCase(),
    ];
    return parts.join(', ');
  }
}
