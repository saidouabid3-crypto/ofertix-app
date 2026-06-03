
import 'product.dart';

class LocalStoreModel {
  final String id;
  final String name;
  final String description;
  final String logo;
  final String coverImage;
  final String category;
  final String address;
  final String city;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String phone;
  final String whatsapp;
  final String website;
  final String merchantId;
  final bool verified;
  final bool featured;
  final bool active;
  final int views;
  final int offerCount;
  final Map<String, String> openingHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LocalStoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.logo,
    required this.coverImage,
    required this.category,
    required this.address,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.whatsapp,
    required this.website,
    required this.merchantId,
    required this.verified,
    required this.featured,
    required this.active,
    required this.views,
    required this.offerCount,
    required this.openingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLocation => latitude != 0 && longitude != 0;
  bool get hasWhatsApp => whatsapp.trim().isNotEmpty;
  bool get hasWebsite => website.trim().isNotEmpty;

  factory LocalStoreModel.empty() => const LocalStoreModel(
        id: '',
        name: '',
        description: '',
        logo: '',
        coverImage: '',
        category: '',
        address: '',
        city: '',
        countryCode: 'es',
        latitude: 0,
        longitude: 0,
        phone: '',
        whatsapp: '',
        website: '',
        merchantId: '',
        verified: false,
        featured: false,
        active: true,
        views: 0,
        offerCount: 0,
        openingHours: {},
        createdAt: null,
        updatedAt: null,
      );

  factory LocalStoreModel.fromJson(Map<String, dynamic> json) {
    final hours = <String, String>{};
    final rawHours = json['opening_hours'] ?? json['openingHours'];
    if (rawHours is Map) {
      rawHours.forEach((key, value) {
        if (key != null && value != null) hours[key.toString()] = value.toString();
      });
    }

    return LocalStoreModel(
      id: (json['id'] ?? json['store_id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['store_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      logo: (json['logo'] ?? json['logo_url'] ?? '').toString(),
      coverImage: (json['cover_image'] ?? json['coverImage'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      countryCode: (json['country_code'] ?? json['countryCode'] ?? 'es').toString().toLowerCase(),
      latitude: Product.toDouble(json['latitude'] ?? json['lat']),
      longitude: Product.toDouble(json['longitude'] ?? json['lng']),
      phone: (json['phone'] ?? '').toString(),
      whatsapp: (json['whatsapp'] ?? json['whatsapp_number'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      merchantId: (json['merchant_id'] ?? json['merchantId'] ?? '').toString(),
      verified: Product.toBool(json['verified'] ?? json['is_verified'] ?? json['isVerified']),
      featured: Product.toBool(json['featured'] ?? json['is_featured'] ?? json['isFeatured']),
      active: Product.toBool(json['active'] ?? json['is_active'] ?? true),
      views: Product.toInt(json['views']),
      offerCount: Product.toInt(json['offer_count'] ?? json['offerCount']),
      openingHours: hours,
      createdAt: Product.toDate(json['created_at'] ?? json['createdAt']),
      updatedAt: Product.toDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'logo': logo,
        'cover_image': coverImage,
        'category': category,
        'address': address,
        'city': city,
        'country_code': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'whatsapp': whatsapp,
        'website': website,
        'merchant_id': merchantId,
        'verified': verified,
        'featured': featured,
        'active': active,
        'views': views,
        'offer_count': offerCount,
        'opening_hours': openingHours,
      };

  LocalStoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    String? coverImage,
    String? category,
    String? address,
    String? city,
    String? countryCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? whatsapp,
    String? website,
    String? merchantId,
    bool? verified,
    bool? featured,
    bool? active,
    int? views,
    int? offerCount,
    Map<String, String>? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalStoreModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        logo: logo ?? this.logo,
        coverImage: coverImage ?? this.coverImage,
        category: category ?? this.category,
        address: address ?? this.address,
        city: city ?? this.city,
        countryCode: countryCode ?? this.countryCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        website: website ?? this.website,
        merchantId: merchantId ?? this.merchantId,
        verified: verified ?? this.verified,
        featured: featured ?? this.featured,
        active: active ?? this.active,
        views: views ?? this.views,
        offerCount: offerCount ?? this.offerCount,
        openingHours: openingHours ?? this.openingHours,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
