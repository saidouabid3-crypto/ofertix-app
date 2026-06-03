class MarketplaceItem {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String city;
  final String country;
  final String sellerCountryCode;
  final List<String> availableCountries;
  final List<String> shipsTo;
  final bool pickupOnly;
  final String condition;
  final List<String> images;
  final String category;
  final bool isActive;
  final bool isFeatured;
  final bool isSponsored;
  final int views;
  final int favorites;
  final DateTime? createdAt;

  const MarketplaceItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.city,
    required this.country,
    required this.sellerCountryCode,
    required this.availableCountries,
    required this.shipsTo,
    required this.pickupOnly,
    required this.condition,
    required this.images,
    required this.category,
    required this.isActive,
    required this.isFeatured,
    required this.isSponsored,
    required this.views,
    required this.favorites,
    required this.createdAt,
  });

  factory MarketplaceItem.fromMap(Map<String, dynamic> map, String id) {
    final sellerCountry =
        (map['sellerCountryCode'] ??
                map['seller_country_code'] ??
                map['country'] ??
                'es')
            .toString()
            .toLowerCase();
    return MarketplaceItem(
      id: id,
      sellerId:
          map['sellerId']?.toString() ?? map['seller_id']?.toString() ?? '',
      sellerName:
          map['sellerName']?.toString() ??
          map['seller_name']?.toString() ??
          'Vendedor Ofertix',
      title: map['title']?.toString() ?? 'Producto',
      description: map['description']?.toString() ?? '',
      price: _toDouble(map['price']),
      currency: map['currency']?.toString() ?? 'EUR',
      city: map['city']?.toString() ?? '',
      country: map['country']?.toString().toLowerCase() ?? sellerCountry,
      sellerCountryCode: sellerCountry,
      availableCountries: _toList(
        map['availableCountries'] ?? map['available_countries'],
      )..add(sellerCountry),
      shipsTo: _toList(map['shipsTo'] ?? map['ships_to']),
      pickupOnly: _toBool(map['pickupOnly'] ?? map['pickup_only'] ?? true),
      condition: map['condition']?.toString() ?? 'used_good',
      images: _toList(map['images']),
      category: map['category']?.toString() ?? 'General',
      isActive: _toBool(map['isActive'] ?? map['is_active'] ?? true),
      isFeatured: _toBool(map['isFeatured'] ?? map['is_featured']),
      isSponsored: _toBool(map['isSponsored'] ?? map['is_sponsored']),
      views: _toInt(map['views']),
      favorites: _toInt(map['favorites']),
      createdAt: _toDate(map['createdAt'] ?? map['created_at']),
    );
  }
  Map<String, dynamic> toMap() => {
    'sellerId': sellerId,
    'sellerName': sellerName,
    'title': title,
    'description': description,
    'price': price,
    'currency': currency,
    'city': city,
    'country': country,
    'sellerCountryCode': sellerCountryCode,
    'availableCountries': availableCountries.toSet().toList(),
    'shipsTo': shipsTo.toSet().toList(),
    'pickupOnly': pickupOnly,
    'condition': condition,
    'images': images,
    'category': category,
    'isActive': isActive,
    'isFeatured': isFeatured,
    'isSponsored': isSponsored,
    'views': views,
    'favorites': favorites,
    'createdAt': createdAt?.toIso8601String(),
  };
  bool isAvailableForCountry(String code) {
    final c = code.toLowerCase();
    if (c == 'global') return true;
    if (pickupOnly) return sellerCountryCode == c;
    return sellerCountryCode == c ||
        availableCountries.contains(c) ||
        shipsTo.contains(c);
  }

  String get mainImage => images.isEmpty ? '' : images.first;
  bool get hasImage => mainImage.isNotEmpty;
  String get formattedPrice =>
      '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} $currency';
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(
          value.toString().replaceAll('€', '').replaceAll(',', '.').trim(),
        ) ??
        0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String)
      return [
        'true',
        '1',
        'yes',
        'si',
        'sí',
      ].contains(value.toLowerCase().trim());
    return false;
  }

  static List<String> _toList(dynamic value) {
    if (value is List)
      return value
          .map((e) => e.toString().toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    if (value is String && value.isNotEmpty)
      return value
          .split(',')
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    return <String>[];
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      if (value.toString().contains('Timestamp')) return value.toDate();
    } catch (_) {}
    return DateTime.tryParse(value.toString());
  }
}
