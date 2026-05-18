class Product {
  final String id;
  final String name;
  final String image;

  final double oldPrice;
  final double newPrice;

  final int discount;

  final String store;
  final String category;
  final String endDate;
  final String description;

  final String affiliateUrl;

  final bool isHot;

  // 🌍 الدولة
  final String country;

  // 📍 GPS
  final double lat;
  final double lng;

  // 🌐 Online / Local Store
  final bool isOnline;

  // ⭐ إضافات احترافية
  final int views;
  final int clicks;
  final int sales;

  final bool featured;
  final bool sponsored;

  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.oldPrice,
    required this.newPrice,
    required this.discount,
    required this.store,
    required this.category,
    required this.endDate,
    required this.description,
    required this.affiliateUrl,
    required this.isHot,
    required this.country,
    required this.lat,
    required this.lng,
    required this.isOnline,
    required this.views,
    required this.clicks,
    required this.sales,
    required this.featured,
    required this.sponsored,
    required this.createdAt,
  });

  // =========================
  // SMART PARSERS
  // =========================

  static double toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value.replaceAll(',', '.').replaceAll('€', '').trim(),
          ) ??
          0.0;
    }

    return 0.0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.replaceAll('%', '').trim()) ?? 0;
    }

    return 0;
  }

  static bool toBool(dynamic value) {
    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value == '1' ||
          value.toLowerCase() == 'yes';
    }

    if (value is num) {
      return value == 1;
    }

    return false;
  }

  static DateTime? toDate(dynamic value) {
    try {
      if (value == null) return null;

      if (value is DateTime) return value;

      if (value.toString().contains('Timestamp')) {
        return value.toDate();
      }

      return DateTime.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  // =========================
  // FIREBASE FACTORY
  // =========================

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    final name = map['name']?.toString() ?? 'No Title';

    final image = map['image']?.toString() ?? '';

    final store = map['store']?.toString() ?? 'Unknown Store';

    final category = map['category']?.toString() ?? 'General';

    final endDate = map['endDate']?.toString() ?? '';

    final description = map['description']?.toString() ?? '';

    final affiliateUrl = map['affiliateUrl']?.toString() ?? '';

    final country = map['country']?.toString().toLowerCase() ?? 'global';

    final newPrice = toDouble(map['newPrice'] ?? map['price']);

    final oldPrice = toDouble(map['oldPrice']);

    int finalDiscount = toInt(map['discount']);

    // 🧠 AI Auto Discount
    if (finalDiscount == 0 && oldPrice > 0 && oldPrice > newPrice) {
      finalDiscount = (((oldPrice - newPrice) / oldPrice) * 100).round();
    }

    final latitude = toDouble(map['lat']);
    final longitude = toDouble(map['lng']);

    // 🌐 Smart online detection
    bool autoIsOnline = (latitude == 0.0 && longitude == 0.0);

    if (map.containsKey('isOnline')) {
      autoIsOnline = toBool(map['isOnline']);
    }

    return Product(
      id: documentId,

      name: name,
      image: image,

      oldPrice: oldPrice,
      newPrice: newPrice,

      discount: finalDiscount,

      store: store,
      category: category,
      endDate: endDate,
      description: description,

      affiliateUrl: affiliateUrl,

      isHot: toBool(map['isHot']),

      country: country,

      lat: latitude,
      lng: longitude,

      isOnline: autoIsOnline,

      views: toInt(map['views']),
      clicks: toInt(map['clicks']),
      sales: toInt(map['sales']),

      featured: toBool(map['featured']),
      sponsored: toBool(map['sponsored']),

      createdAt: toDate(map['createdAt']),
    );
  }

  // =========================
  // HELPERS
  // =========================

  double get savings {
    if (oldPrice <= 0) return 0.0;
    return oldPrice - newPrice;
  }

  bool get hasRealDiscount {
    return oldPrice > newPrice;
  }

  bool get isTrending {
    return views > 1000 || clicks > 150;
  }

  bool get isNearbyStore {
    return !isOnline && lat != 0.0 && lng != 0.0;
  }

  bool get isGlobal {
    return country == 'global';
  }

  // =========================
  // FIREBASE EXPORT
  // =========================

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,

      'oldPrice': oldPrice,
      'newPrice': newPrice,

      'discount': discount,

      'store': store,
      'category': category,
      'endDate': endDate,
      'description': description,

      'affiliateUrl': affiliateUrl,

      'isHot': isHot,

      'country': country,

      'lat': lat,
      'lng': lng,

      'isOnline': isOnline,

      'views': views,
      'clicks': clicks,
      'sales': sales,

      'featured': featured,
      'sponsored': sponsored,

      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
