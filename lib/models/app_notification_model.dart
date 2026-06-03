import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType { priceDrop, aiAlert, watchlistUpdate, unknown }

class AppNotificationModel {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String productId;
  final String productName;
  final double? currentPrice;
  final double? targetPrice;
  final String currency;
  final String productImage;
  final String affiliateUrl;
  final String source;
  final bool read;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.productId,
    required this.productName,
    this.currentPrice,
    this.targetPrice,
    required this.currency,
    required this.productImage,
    required this.affiliateUrl,
    required this.source,
    required this.read,
    required this.createdAt,
  });

  factory AppNotificationModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotificationModel(
      id: doc.id,
      userId: map['userId']?.toString() ?? '',
      type: _parseType(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      body: (map['body'] ?? map['message'])?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: (map['productName'] ?? map['name'])?.toString() ?? '',
      currentPrice: _parseDouble(map['currentPrice'] ?? map['price']),
      targetPrice: _parseDouble(map['targetPrice']),
      currency: map['currency']?.toString() ?? 'EUR',
      productImage: (map['productImage'] ?? map['image'])?.toString() ?? '',
      affiliateUrl: map['affiliateUrl']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      read: map['read'] == true,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  AppNotificationModel copyWith({bool? read}) => AppNotificationModel(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    productId: productId,
    productName: productName,
    currentPrice: currentPrice,
    targetPrice: targetPrice,
    currency: currency,
    productImage: productImage,
    affiliateUrl: affiliateUrl,
    source: source,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  static AppNotificationType _parseType(String? raw) {
    switch (raw) {
      case 'price_drop':
        return AppNotificationType.priceDrop;
      case 'ai_alert':
        return AppNotificationType.aiAlert;
      case 'watchlist_update':
        return AppNotificationType.watchlistUpdate;
      default:
        return AppNotificationType.unknown;
    }
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
