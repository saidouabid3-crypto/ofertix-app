class UserGeneratedDealModel {
  final String id;
  final String title;
  final String description;
  final String store;
  final double currentPrice;
  final double? oldPrice;
  final String currency;
  final int discountPercent;
  final String country;
  final String city;
  final double? latitude;
  final double? longitude;
  final String mediaUrl;
  final String creatorId;
  final String creatorName;
  final String status;
  final int rewardPoints;
  final int hotScore;

  const UserGeneratedDealModel({
    required this.id,
    required this.title,
    required this.description,
    required this.store,
    required this.currentPrice,
    required this.oldPrice,
    required this.currency,
    required this.discountPercent,
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.mediaUrl,
    required this.creatorId,
    required this.creatorName,
    required this.status,
    required this.rewardPoints,
    required this.hotScore,
  });

  factory UserGeneratedDealModel.fromJson(Map<String, dynamic> json) {
    return UserGeneratedDealModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      currentPrice: _double(json['current_price']),
      oldPrice: json['old_price'] == null ? null : _double(json['old_price']),
      currency: json['currency']?.toString() ?? 'EUR',
      discountPercent: _int(json['discount_percent']),
      country: json['country']?.toString() ?? 'ES',
      city: json['city']?.toString() ?? '',
      latitude: json['latitude'] == null ? null : _double(json['latitude']),
      longitude: json['longitude'] == null ? null : _double(json['longitude']),
      mediaUrl: json['media_url']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? 'mobile_user',
      creatorName: json['creator_name']?.toString() ?? 'User',
      status: json['status']?.toString() ?? 'pending',
      rewardPoints: _int(json['reward_points']),
      hotScore: _int(json['hot_score'], fallback: 50),
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _double(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
