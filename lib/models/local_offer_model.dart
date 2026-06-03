
import 'product.dart';

class LocalOfferModel {
  final String id;
  final String storeId;
  final String storeName;
  final String title;
  final String description;
  final String image;
  final String category;
  final double oldPrice;
  final double newPrice;
  final String currency;
  final int discountPercent;
  final String city;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String whatsapp;
  final String status;
  final String source;
  final String riskLevel;
  final int riskScore;
  final int views;
  final int clicks;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;

  const LocalOfferModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.title,
    required this.description,
    required this.image,
    required this.category,
    required this.oldPrice,
    required this.newPrice,
    required this.currency,
    required this.discountPercent,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.whatsapp,
    required this.status,
    required this.source,
    required this.riskLevel,
    required this.riskScore,
    required this.views,
    required this.clicks,
    required this.startsAt,
    required this.endsAt,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isExpired => endsAt != null && endsAt!.isBefore(DateTime.now());
  bool get hasLocation => latitude != 0 && longitude != 0;
  bool get hasImage => image.trim().isNotEmpty;
  bool get hasDiscount => oldPrice > newPrice && oldPrice > 0;

  factory LocalOfferModel.empty() => const LocalOfferModel(
        id: '',
        storeId: '',
        storeName: '',
        title: '',
        description: '',
        image: '',
        category: 'general',
        oldPrice: 0,
        newPrice: 0,
        currency: 'EUR',
        discountPercent: 0,
        city: '',
        countryCode: 'es',
        latitude: 0,
        longitude: 0,
        whatsapp: '',
        status: 'pending',
        source: 'merchant',
        riskLevel: 'GREEN',
        riskScore: 0,
        views: 0,
        clicks: 0,
        startsAt: null,
        endsAt: null,
        createdAt: null,
      );

  factory LocalOfferModel.fromJson(Map<String, dynamic> json) {
    final oldPrice = Product.toDouble(json['old_price'] ?? json['oldPrice']);
    final newPrice = Product.toDouble(json['new_price'] ?? json['newPrice'] ?? json['price']);
    final calculatedDiscount = oldPrice > 0 && newPrice > 0 && oldPrice > newPrice
        ? (((oldPrice - newPrice) / oldPrice) * 100).round()
        : 0;

    return LocalOfferModel(
      id: (json['id'] ?? json['offer_id'] ?? json['_id'] ?? '').toString(),
      storeId: (json['store_id'] ?? json['storeId'] ?? '').toString(),
      storeName: (json['store_name'] ?? json['storeName'] ?? json['store'] ?? '').toString(),
      title: (json['title'] ?? json['product_name'] ?? json['productName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? json['image_url'] ?? json['media_url'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      oldPrice: oldPrice,
      newPrice: newPrice,
      currency: (json['currency'] ?? 'EUR').toString(),
      discountPercent: Product.toInt(json['discount_percent'] ?? json['discountPercent'] ?? calculatedDiscount),
      city: (json['city'] ?? '').toString(),
      countryCode: (json['country_code'] ?? json['countryCode'] ?? 'es').toString().toLowerCase(),
      latitude: Product.toDouble(json['latitude'] ?? json['lat']),
      longitude: Product.toDouble(json['longitude'] ?? json['lng']),
      whatsapp: (json['whatsapp'] ?? json['whatsapp_number'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      source: (json['source'] ?? 'merchant').toString(),
      riskLevel: (json['risk_level'] ?? json['riskLevel'] ?? 'GREEN').toString().toUpperCase(),
      riskScore: Product.toInt(json['risk_score'] ?? json['riskScore']),
      views: Product.toInt(json['views']),
      clicks: Product.toInt(json['clicks']),
      startsAt: Product.toDate(json['starts_at'] ?? json['startsAt']),
      endsAt: Product.toDate(json['ends_at'] ?? json['endsAt']),
      createdAt: Product.toDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'store_name': storeName,
        'title': title,
        'description': description,
        'image': image,
        'category': category,
        'old_price': oldPrice,
        'new_price': newPrice,
        'currency': currency,
        'discount_percent': discountPercent,
        'city': city,
        'country_code': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        'whatsapp': whatsapp,
        'status': status,
        'source': source,
        'risk_level': riskLevel,
        'risk_score': riskScore,
        'views': views,
        'clicks': clicks,
        if (startsAt != null) 'starts_at': startsAt!.toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt!.toIso8601String(),
      };
}
