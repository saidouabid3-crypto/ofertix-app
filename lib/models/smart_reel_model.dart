class SmartReelModel {
  final String id;
  final String productId;
  final String title;
  final String description;
  final String store;
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;
  final double currentPrice;
  final double? oldPrice;
  final String currency;
  final int discountPercent;
  final String thumbnailUrl;
  final String videoMp4Url;
  final String? videoHlsUrl;
  final String affiliateUrl;
  final int dealScore;
  final String aiVerdict;
  final String fakeDiscountRisk;
  final String status;
  final String provider;
  final int views;
  final int likes;
  final int comments;
  final int saves;
  final int reports;
  final int hotVotes;
  final int coldVotes;
  final int hotScore;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final DateTime? createdAt;

  const SmartReelModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.description,
    required this.store,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatarUrl,
    required this.currentPrice,
    required this.oldPrice,
    required this.currency,
    required this.discountPercent,
    required this.thumbnailUrl,
    required this.videoMp4Url,
    required this.videoHlsUrl,
    required this.affiliateUrl,
    required this.dealScore,
    required this.aiVerdict,
    required this.fakeDiscountRisk,
    required this.status,
    required this.provider,
    required this.views,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.reports,
    required this.hotVotes,
    required this.coldVotes,
    required this.hotScore,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowing,
    required this.createdAt,
  });

  factory SmartReelModel.fromJson(Map<String, dynamic> json) {
    return SmartReelModel(
      id: _string(json['id']),
      productId: _string(json['product_id']),
      title: _string(json['title']),
      description: _string(json['description']),
      store: _string(json['store']),
      creatorId: _string(json['creator_id'], fallback: 'ofertix_creator'),
      creatorName: _string(json['creator_name'], fallback: 'Creator'),
      creatorAvatarUrl: _string(json['creator_avatar_url']),
      currentPrice: _double(json['current_price']),
      oldPrice: json['old_price'] == null ? null : _double(json['old_price']),
      currency: _string(json['currency'], fallback: 'EUR'),
      discountPercent: _int(json['discount_percent']),
      thumbnailUrl: _string(json['thumbnail_url']),
      videoMp4Url: _string(json['video_mp4_url']),
      videoHlsUrl: _string(json['video_hls_url']),
      affiliateUrl: _string(json['affiliate_url']),
      dealScore: _int(json['deal_score']),
      aiVerdict: _string(json['ai_verdict'], fallback: 'Oferta analizada'),
      fakeDiscountRisk: _string(
        json['fake_discount_risk'],
        fallback: 'unknown',
      ),
      status: _string(json['status'], fallback: 'approved'),
      provider: _string(json['provider'], fallback: 'cloudinary'),
      views: _int(json['views']),
      likes: _int(json['likes']),
      comments: _int(json['comments']),
      saves: _int(json['saves']),
      reports: _int(json['reports']),
      hotVotes: _int(json['hot_votes']),
      coldVotes: _int(json['cold_votes']),
      hotScore: _int(json['hot_score'], fallback: 50),
      isLiked: _bool(json['is_liked']),
      isSaved: _bool(json['is_saved']),
      isFollowing: _bool(json['is_following']),
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'title': title,
      'description': description,
      'store': store,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'creator_avatar_url': creatorAvatarUrl,
      'current_price': currentPrice,
      'old_price': oldPrice,
      'currency': currency,
      'discount_percent': discountPercent,
      'thumbnail_url': thumbnailUrl,
      'video_mp4_url': videoMp4Url,
      'video_hls_url': videoHlsUrl,
      'affiliate_url': affiliateUrl,
      'deal_score': dealScore,
      'ai_verdict': aiVerdict,
      'fake_discount_risk': fakeDiscountRisk,
      'status': status,
      'provider': provider,
      'views': views,
      'likes': likes,
      'comments': comments,
      'saves': saves,
      'reports': reports,
      'hot_votes': hotVotes,
      'cold_votes': coldVotes,
      'hot_score': hotScore,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'is_following': isFollowing,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  SmartReelModel copyWith({
    int? views,
    int? likes,
    int? comments,
    int? saves,
    int? reports,
    int? hotVotes,
    int? coldVotes,
    int? hotScore,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
  }) {
    return SmartReelModel(
      id: id,
      productId: productId,
      title: title,
      description: description,
      store: store,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      currentPrice: currentPrice,
      oldPrice: oldPrice,
      currency: currency,
      discountPercent: discountPercent,
      thumbnailUrl: thumbnailUrl,
      videoMp4Url: videoMp4Url,
      videoHlsUrl: videoHlsUrl,
      affiliateUrl: affiliateUrl,
      dealScore: dealScore,
      aiVerdict: aiVerdict,
      fakeDiscountRisk: fakeDiscountRisk,
      status: status,
      provider: provider,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      saves: saves ?? this.saves,
      reports: reports ?? this.reports,
      hotVotes: hotVotes ?? this.hotVotes,
      coldVotes: coldVotes ?? this.coldVotes,
      hotScore: hotScore ?? this.hotScore,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt,
    );
  }

  String get bestVideoUrl {
    if (videoMp4Url.trim().startsWith('http')) return videoMp4Url.trim();

    final hls = videoHlsUrl ?? '';
    if (hls.trim().startsWith('http')) return hls.trim();

    return '';
  }

  bool get hasDiscount {
    return oldPrice != null && oldPrice! > currentPrice;
  }

  String get priceLabel {
    return '${currentPrice.toStringAsFixed(2)} $currency';
  }

  String get oldPriceLabel {
    if (oldPrice == null) return '';
    return '${oldPrice!.toStringAsFixed(2)} $currency';
  }

  String get discountLabel {
    if (discountPercent <= 0) return '';
    return '-$discountPercent%';
  }

  String get scoreLabel {
    return '$dealScore/100';
  }

  bool get hasAffiliate {
    return affiliateUrl.trim().startsWith('http');
  }

  bool get isFakeRiskHigh {
    final risk = fakeDiscountRisk.toLowerCase();
    return risk.contains('high') || risk.contains('alto');
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

  static bool _bool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class SmartReelComment {
  final String id;
  final String reelId;
  final String userId;
  final String userName;
  final String username;
  final String userAvatarUrl;
  final String text;
  final DateTime? createdAt;

  const SmartReelComment({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.userName,
    required this.username,
    required this.userAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory SmartReelComment.fromJson(Map<String, dynamic> json) {
    return SmartReelComment(
      id: json['id']?.toString() ?? '',
      reelId: json['reel_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Creator',
      username: json['username']?.toString() ?? '',
      userAvatarUrl: json['user_avatar_url']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
