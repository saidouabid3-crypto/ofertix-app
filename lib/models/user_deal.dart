import 'package:cloud_firestore/cloud_firestore.dart';

class UserDeal {
  final String id;

  final String userId;
  final String createdBy;
  final String userName;

  final String title;
  final String description;
  final String store;
  final String city;
  final String countryCode;
  final String currency;

  final double price;
  final double oldPrice;
  final int discount;

  final String mediaType;

  // Video fields
  final String videoUrl;
  final String videoUrlOriginal;
  final String videoUrlOptimized;
  final String thumbnailUrl;
  final String cloudinaryPublicId;
  final int durationSeconds;

  final String link;
  final String whatsapp;

  final bool isActive;
  final String status;
  final bool isVerified;
  final bool isPromoted;

  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final int sharesCount;
  final int viewsCount;
  final int clicksCount;
  final int whatsappClicksCount;
  final int reportsCount;

  final double aiScore;
  final String aiLabel;
  final String riskLevel;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const UserDeal({
    required this.id,
    required this.userId,
    required this.createdBy,
    required this.userName,
    required this.title,
    required this.description,
    required this.store,
    required this.city,
    required this.countryCode,
    required this.currency,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.mediaType,
    required this.videoUrl,
    this.videoUrlOriginal = '',
    this.videoUrlOptimized = '',
    required this.thumbnailUrl,
    required this.cloudinaryPublicId,
    required this.durationSeconds,
    required this.link,
    required this.whatsapp,
    required this.isActive,
    required this.status,
    required this.isVerified,
    required this.isPromoted,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.sharesCount,
    required this.viewsCount,
    required this.clicksCount,
    required this.whatsappClicksCount,
    required this.reportsCount,
    required this.aiScore,
    required this.aiLabel,
    required this.riskLevel,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  bool get hasLink => link.trim().isNotEmpty;
  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;
  bool get hasDiscount => discount > 0 && oldPrice > price;

  String get bestVideoUrl {
    final optimized = videoUrlOptimized.trim();
    if (optimized.isNotEmpty) return optimized;

    final normal = videoUrl.trim();
    if (normal.isNotEmpty) return normal;

    return videoUrlOriginal.trim();
  }

  bool get isVideo => mediaType == 'video' && bestVideoUrl.trim().isNotEmpty;
  bool get isPublished => isActive && status == 'published';

  factory UserDeal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserDeal.fromMap(doc.data() ?? {}, doc.id);
  }

  factory UserDeal.fromMap(Map<String, dynamic> data, String id) {
    final price = _toDouble(data['price']);
    final oldPrice = _toDouble(data['oldPrice']);

    final calculatedDiscount = oldPrice > price && oldPrice > 0
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : 0;

    final userId =
        data['userId']?.toString() ?? data['createdBy']?.toString() ?? 'guest';

    final videoUrlOptimized = data['videoUrlOptimized']?.toString() ?? '';
    final videoUrlOriginal = data['videoUrlOriginal']?.toString() ?? '';
    final videoUrl = data['videoUrl']?.toString() ?? videoUrlOptimized;

    return UserDeal(
      id: id,

      userId: userId,
      createdBy: data['createdBy']?.toString() ?? userId,
      userName: data['userName']?.toString() ?? 'Usuario',

      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      store: data['store']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      countryCode: data['countryCode']?.toString() ?? 'ES',
      currency: data['currency']?.toString() ?? 'EUR',

      price: price,
      oldPrice: oldPrice,
      discount: _toInt(data['discount']) > 0
          ? _toInt(data['discount'])
          : calculatedDiscount,

      mediaType: data['mediaType']?.toString() ?? 'video',

      videoUrl: videoUrl,
      videoUrlOriginal: videoUrlOriginal,
      videoUrlOptimized: videoUrlOptimized,
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      cloudinaryPublicId: data['cloudinaryPublicId']?.toString() ?? '',
      durationSeconds: _toInt(data['durationSeconds']),

      link:
          data['link']?.toString() ??
          data['buyLink']?.toString() ??
          data['affiliateUrl']?.toString() ??
          '',
      whatsapp: data['whatsapp']?.toString() ?? '',

      isActive: data['isActive'] == true || data['active'] == true,
      status:
          data['status']?.toString() ??
          ((data['isActive'] == true || data['active'] == true)
              ? 'published'
              : 'draft'),
      isVerified: data['isVerified'] == true,
      isPromoted: data['isPromoted'] == true,

      likesCount: _toInt(data['likesCount']),
      commentsCount: _toInt(data['commentsCount']),
      savesCount: _toInt(data['savesCount']),
      sharesCount: _toInt(data['sharesCount']),
      viewsCount: _toInt(data['viewsCount']),
      clicksCount: _toInt(data['clicksCount']),
      whatsappClicksCount: _toInt(data['whatsappClicksCount']),
      reportsCount: _toInt(data['reportsCount']),

      aiScore: _toDouble(data['aiScore']),
      aiLabel: data['aiLabel']?.toString() ?? '',
      riskLevel: data['riskLevel']?.toString() ?? 'unknown',

      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      deletedAt: _toDate(data['deletedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdBy': createdBy,
      'userName': userName,

      'title': title,
      'description': description,
      'store': store,
      'city': city,
      'countryCode': countryCode,
      'currency': currency,

      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,

      'mediaType': mediaType,

      // Important: feed should use optimized video.
      'videoUrl': bestVideoUrl,
      'videoUrlOriginal': videoUrlOriginal,
      'videoUrlOptimized': videoUrlOptimized,
      'thumbnailUrl': thumbnailUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'durationSeconds': durationSeconds,

      'link': link,
      'buyLink': link,
      'whatsapp': whatsapp,

      'isActive': isActive,
      'active': isActive,
      'status': status,
      'isVerified': isVerified,
      'isPromoted': isPromoted,

      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'savesCount': savesCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'clicksCount': clicksCount,
      'whatsappClicksCount': whatsappClicksCount,
      'reportsCount': reportsCount,

      'aiScore': aiScore,
      'aiLabel': aiLabel,
      'riskLevel': riskLevel,

      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
