class CouponModel {
  final String id;
  final String title;
  final String code;
  final String store;
  final String description;
  final String country;
  final String currency;
  final String discountLabel;
  final String? expiresAt;
  final String? sourceUrl;
  final String createdBy;
  final String status;
  final int verifiedWorks;
  final int verifiedFailed;
  final int trustScore;
  final int hotVotes;
  final int coldVotes;
  final int hotScore;

  const CouponModel({
    required this.id,
    required this.title,
    required this.code,
    required this.store,
    required this.description,
    required this.country,
    required this.currency,
    required this.discountLabel,
    required this.expiresAt,
    required this.sourceUrl,
    required this.createdBy,
    required this.status,
    required this.verifiedWorks,
    required this.verifiedFailed,
    required this.trustScore,
    required this.hotVotes,
    required this.coldVotes,
    required this.hotScore,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      country: json['country']?.toString() ?? 'ES',
      currency: json['currency']?.toString() ?? 'EUR',
      discountLabel: json['discount_label']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString(),
      sourceUrl: json['source_url']?.toString(),
      createdBy: json['created_by']?.toString() ?? 'mobile_user',
      status: json['status']?.toString() ?? 'active',
      verifiedWorks: _int(json['verified_works']),
      verifiedFailed: _int(json['verified_failed']),
      trustScore: _int(json['trust_score'], fallback: 50),
      hotVotes: _int(json['hot_votes']),
      coldVotes: _int(json['cold_votes']),
      hotScore: _int(json['hot_score'], fallback: 50),
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
