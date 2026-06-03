import 'package:cloud_firestore/cloud_firestore.dart';

enum OfertixAdPlacement { homeTop, sellTop, reelsVideo }

enum OfertixAdType { banner, sponsoredProduct, video }

class OfertixAdModel {
  const OfertixAdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.placement,
    required this.type,
    required this.trackingUrl,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.impressionUrl,
    required this.countryCode,
    required this.priority,
    required this.isActive,
    required this.clicks,
    required this.impressions,
    required this.createdAt,
    required this.updatedAt,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String title;
  final String description;
  final OfertixAdPlacement placement;
  final OfertixAdType type;
  final String trackingUrl;
  final String mediaUrl;
  final String thumbnailUrl;
  final String impressionUrl;
  final String countryCode;
  final int priority;
  final bool isActive;
  final int clicks;
  final int impressions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startAt;
  final DateTime? endAt;

  bool get isVideo => type == OfertixAdType.video;

  double get ctr {
    if (impressions <= 0) return 0;
    return (clicks / impressions) * 100;
  }

  bool get isLiveNow {
    final now = DateTime.now();
    if (!isActive) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  factory OfertixAdModel.empty(OfertixAdPlacement placement) {
    final now = DateTime.now();
    return OfertixAdModel(
      id: '',
      title: '',
      description: '',
      placement: placement,
      type: placement == OfertixAdPlacement.reelsVideo
          ? OfertixAdType.video
          : OfertixAdType.banner,
      trackingUrl: '',
      mediaUrl: '',
      thumbnailUrl: '',
      impressionUrl: '',
      countryCode: 'es',
      priority: 10,
      isActive: true,
      clicks: 0,
      impressions: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory OfertixAdModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return OfertixAdModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      placement: parsePlacement(data['placement']),
      type: parseType(data['type']),
      trackingUrl: data['trackingUrl']?.toString() ?? '',
      mediaUrl: data['mediaUrl']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      impressionUrl: data['impressionUrl']?.toString() ?? '',
      countryCode: (data['countryCode']?.toString() ?? 'global').toLowerCase(),
      priority: _toInt(data['priority'], fallback: 10),
      isActive: data['isActive'] == true,
      clicks: _toInt(data['clicks']),
      impressions: _toInt(data['impressions']),
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(data['updatedAt']) ?? DateTime.now(),
      startAt: _toDate(data['startAt']),
      endAt: _toDate(data['endAt']),
    );
  }

  Map<String, dynamic> toFirestore({required bool creating}) {
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'placement': placementKey(placement),
      'type': typeKey(type),
      'trackingUrl': trackingUrl.trim(),
      'mediaUrl': mediaUrl.trim(),
      'thumbnailUrl': thumbnailUrl.trim(),
      'impressionUrl': impressionUrl.trim(),
      'countryCode': countryCode.trim().isEmpty
          ? 'global'
          : countryCode.trim().toLowerCase(),
      'priority': priority,
      'isActive': isActive,
      'updatedAt': now,
      if (creating) 'createdAt': now,
      if (creating) 'clicks': clicks,
      if (creating) 'impressions': impressions,
      if (startAt != null) 'startAt': Timestamp.fromDate(startAt!),
      if (endAt != null) 'endAt': Timestamp.fromDate(endAt!),
    };
    return data;
  }

  Map<String, dynamic> clearDateFieldsPatch() {
    return <String, dynamic>{
      if (startAt == null) 'startAt': FieldValue.delete(),
      if (endAt == null) 'endAt': FieldValue.delete(),
    };
  }

  OfertixAdModel copyWith({
    String? id,
    String? title,
    String? description,
    OfertixAdPlacement? placement,
    OfertixAdType? type,
    String? trackingUrl,
    String? mediaUrl,
    String? thumbnailUrl,
    String? impressionUrl,
    String? countryCode,
    int? priority,
    bool? isActive,
    int? clicks,
    int? impressions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startAt,
    DateTime? endAt,
    bool clearStartAt = false,
    bool clearEndAt = false,
  }) {
    return OfertixAdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      placement: placement ?? this.placement,
      type: type ?? this.type,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      impressionUrl: impressionUrl ?? this.impressionUrl,
      countryCode: countryCode ?? this.countryCode,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      clicks: clicks ?? this.clicks,
      impressions: impressions ?? this.impressions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startAt: clearStartAt ? null : startAt ?? this.startAt,
      endAt: clearEndAt ? null : endAt ?? this.endAt,
    );
  }

  static OfertixAdPlacement parsePlacement(dynamic value) {
    switch (value?.toString()) {
      case 'sell_top':
        return OfertixAdPlacement.sellTop;
      case 'reels_video':
        return OfertixAdPlacement.reelsVideo;
      case 'home_top':
      default:
        return OfertixAdPlacement.homeTop;
    }
  }

  static OfertixAdType parseType(dynamic value) {
    switch (value?.toString()) {
      case 'sponsored_product':
        return OfertixAdType.sponsoredProduct;
      case 'video':
        return OfertixAdType.video;
      case 'banner':
      default:
        return OfertixAdType.banner;
    }
  }

  static String placementKey(OfertixAdPlacement value) {
    switch (value) {
      case OfertixAdPlacement.homeTop:
        return 'home_top';
      case OfertixAdPlacement.sellTop:
        return 'sell_top';
      case OfertixAdPlacement.reelsVideo:
        return 'reels_video';
    }
  }

  static String typeKey(OfertixAdType value) {
    switch (value) {
      case OfertixAdType.banner:
        return 'banner';
      case OfertixAdType.sponsoredProduct:
        return 'sponsored_product';
      case OfertixAdType.video:
        return 'video';
    }
  }

  static String placementLabel(OfertixAdPlacement value) {
    switch (value) {
      case OfertixAdPlacement.homeTop:
        return 'Home banner';
      case OfertixAdPlacement.sellTop:
        return 'Sell sponsored';
      case OfertixAdPlacement.reelsVideo:
        return 'Reels video';
    }
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
