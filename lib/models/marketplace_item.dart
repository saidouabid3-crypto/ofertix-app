class MarketplaceItem {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerUsername;
  final String sellerAvatarUrl;
  final bool sellerVerified;
  final String title;
  final String description;
  final double price;
  final String currencyCode;
  final String countryCode;
  final String countryName;
  final String city;
  final String postalCode;
  final String area;
  final String approximateLocationLabel;
  final String categoryKey;
  final String conditionKey;
  final String deliveryMethodKey;
  final List<String> images;
  final String coverImage;
  final int imageCount;
  final String sellerCountryCode;
  final List<String> availableCountries;
  final List<String> shipsTo;
  final bool pickupOnly;
  final bool isActive;
  final bool visibleToUsers;
  final bool isFeatured;
  final bool isSponsored;
  final int viewCount;
  final int favoriteCount;
  final int reportCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? archivedAt;
  final String rejectionReason;
  final String status;

  MarketplaceItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerUsername = '',
    this.sellerAvatarUrl = '',
    this.sellerVerified = false,
    required this.title,
    required this.description,
    required this.price,
    String? currencyCode,
    String? currency,
    required this.city,
    String? countryCode,
    String? country,
    this.countryName = '',
    this.postalCode = '',
    this.area = '',
    this.approximateLocationLabel = '',
    String? categoryKey,
    String? category,
    String? conditionKey,
    String? condition,
    this.deliveryMethodKey = 'pickup',
    required this.images,
    String? coverImage,
    int? imageCount,
    required this.sellerCountryCode,
    required this.availableCountries,
    required this.shipsTo,
    required this.pickupOnly,
    required this.isActive,
    this.visibleToUsers = false,
    required this.isFeatured,
    required this.isSponsored,
    int? viewCount,
    int? views,
    int? favoriteCount,
    int? favorites,
    this.reportCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.approvedAt,
    this.rejectedAt,
    this.archivedAt,
    this.rejectionReason = '',
    this.status = '',
  }) : currencyCode = currencyCode ?? currency ?? 'EUR',
       countryCode = countryCode ?? country ?? 'ES',
       categoryKey = categoryKey ?? category ?? 'other',
       conditionKey = conditionKey ?? condition ?? 'good',
       coverImage = coverImage ?? (images.isEmpty ? '' : images.first),
       imageCount = imageCount ?? images.length,
       viewCount = viewCount ?? views ?? 0,
       favoriteCount = favoriteCount ?? favorites ?? 0;

  factory MarketplaceItem.fromMap(Map<String, dynamic> map, String id) {
    final sellerCountry =
        (map['sellerCountryCode'] ??
                map['seller_country_code'] ??
                map['countryCode'] ??
                map['country'] ??
                'es')
            .toString()
            .toLowerCase();
    final images = _toList(map['images'], lowercase: false);
    final legacyImage = (map['coverImage'] ?? map['image'] ?? '').toString();
    if (images.isEmpty && legacyImage.isNotEmpty) images.add(legacyImage);
    final rawStatus = (map['status'] ?? '').toString();
    return MarketplaceItem(
      id: id,
      sellerId:
          map['sellerId']?.toString() ?? map['seller_id']?.toString() ?? '',
      sellerName:
          map['sellerName']?.toString() ?? map['seller_name']?.toString() ?? '',
      sellerUsername: (map['sellerUsername'] ?? map['seller_username'] ?? '')
          .toString(),
      sellerAvatarUrl:
          (map['sellerAvatarUrl'] ??
                  map['seller_avatar_url'] ??
                  map['sellerPhotoUrl'] ??
                  '')
              .toString(),
      sellerVerified:
          map['sellerVerified'] == true || map['seller_verified'] == true,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _toDouble(map['price']),
      currencyCode: (map['currencyCode'] ?? map['currency'] ?? 'EUR')
          .toString()
          .toUpperCase(),
      countryCode: (map['countryCode'] ?? map['country'] ?? sellerCountry)
          .toString()
          .toUpperCase(),
      countryName: (map['countryName'] ?? '').toString(),
      city: map['city']?.toString() ?? '',
      postalCode: (map['postalCode'] ?? '').toString(),
      area: (map['area'] ?? '').toString(),
      approximateLocationLabel: (map['approximateLocationLabel'] ?? '')
          .toString(),
      categoryKey: (map['categoryKey'] ?? map['category'] ?? 'other')
          .toString()
          .toLowerCase(),
      conditionKey: _normalizeCondition(
        map['conditionKey'] ?? map['condition'],
      ),
      deliveryMethodKey: _deliveryMethod(map),
      images: images,
      coverImage: (map['coverImage'] ?? map['image'] ?? '').toString(),
      imageCount: _toInt(map['imageCount'] ?? images.length),
      sellerCountryCode: sellerCountry,
      availableCountries: _toList(
        map['availableCountries'] ?? map['available_countries'],
      )..add(sellerCountry),
      shipsTo: _toList(map['shipsTo'] ?? map['ships_to']),
      pickupOnly: _toBool(map['pickupOnly'] ?? map['pickup_only'] ?? true),
      isActive: _toBool(map['isActive'] ?? map['is_active']),
      visibleToUsers: _toBool(map['visibleToUsers'] ?? map['visible_to_users']),
      isFeatured: _toBool(map['isFeatured'] ?? map['is_featured']),
      isSponsored: _toBool(map['isSponsored'] ?? map['is_sponsored']),
      viewCount: _toInt(map['viewCount'] ?? map['views']),
      favoriteCount: _toInt(map['favoriteCount'] ?? map['favorites']),
      reportCount: _toInt(map['reportCount']),
      createdAt: _toDate(map['createdAt'] ?? map['created_at']),
      updatedAt: _toDate(map['updatedAt'] ?? map['updated_at']),
      editedAt: _toDate(map['editedAt'] ?? map['edited_at']),
      approvedAt: _toDate(map['approvedAt'] ?? map['approved_at']),
      rejectedAt: _toDate(map['rejectedAt'] ?? map['rejected_at']),
      archivedAt: _toDate(map['archivedAt'] ?? map['archived_at']),
      rejectionReason: (map['rejectionReason'] ?? '').toString(),
      status: rawStatus.isNotEmpty
          ? rawStatus.toLowerCase()
          : (_toBool(map['isActive'] ?? map['is_active'])
                ? 'approved'
                : 'pending'),
    );
  }

  Map<String, dynamic> toListingPayload() => {
    'title': title,
    'description': description,
    'price': price,
    'currencyCode': currencyCode,
    'countryCode': countryCode,
    'countryName': countryName,
    'city': city,
    'postalCode': postalCode,
    'area': area,
    'approximateLocationLabel': approximateLocationLabel,
    'categoryKey': categoryKey,
    'conditionKey': conditionKey,
    'deliveryMethodKey': deliveryMethodKey,
    'images': images,
    'coverImage': coverImage,
    'imageCount': images.length,
  };

  Map<String, dynamic> toMap() => {
    ...toListingPayload(),
    'status': status,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerUsername': sellerUsername,
    'sellerAvatarUrl': sellerAvatarUrl,
    'sellerVerified': sellerVerified,
    'country': country,
    'sellerCountryCode': sellerCountryCode,
    'availableCountries': availableCountries.toSet().toList(),
    'shipsTo': shipsTo.toSet().toList(),
    'pickupOnly': pickupOnly,
    'condition': condition,
    'category': category,
    'currency': currency,
    'isActive': isActive,
    'visibleToUsers': visibleToUsers,
    'isFeatured': isFeatured,
    'isSponsored': isSponsored,
    'views': views,
    'favorites': favorites,
    'viewCount': viewCount,
    'favoriteCount': favoriteCount,
    'reportCount': reportCount,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'editedAt': editedAt?.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectedAt': rejectedAt?.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };

  String get currency => currencyCode;
  String get country => countryCode.toLowerCase();
  String get category => categoryKey;
  String get condition => conditionKey;
  int get views => viewCount;
  int get favorites => favoriteCount;
  String get mainImage =>
      coverImage.isNotEmpty ? coverImage : (images.isEmpty ? '' : images.first);
  bool get hasImage => mainImage.isNotEmpty;
  bool get isArchived => status == 'archived';
  bool get canEdit => !{'archived', 'deleted', 'hidden'}.contains(status);

  String get formattedPrice =>
      '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} $currencyCode';

  bool isAvailableForCountry(String code) {
    final normalized = code.toLowerCase();
    if (normalized == 'global') return true;
    if (pickupOnly) return sellerCountryCode == normalized;
    return sellerCountryCode == normalized ||
        availableCountries.contains(normalized) ||
        shipsTo.contains(normalized);
  }

  static String _normalizeCondition(dynamic value) {
    const aliases = {
      'used_like_new': 'like_new',
      'used_good': 'good',
      'used_fair': 'fair',
    };
    final key = (value ?? 'good').toString().toLowerCase();
    return aliases[key] ?? key;
  }

  static String _deliveryMethod(Map<String, dynamic> map) {
    final explicit = (map['deliveryMethodKey'] ?? '').toString().toLowerCase();
    if (explicit.isNotEmpty) return explicit;
    final pickup = _toBool(map['pickupOnly'] ?? map['pickup_only'] ?? true);
    final ships = _toList(map['shipsTo'] ?? map['ships_to']);
    if (pickup && ships.isNotEmpty) return 'both';
    return pickup ? 'pickup' : 'shipping';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          (value ?? '').toString().replaceAll('EUR', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    return {
      'true',
      '1',
      'yes',
      'si',
    }.contains((value ?? '').toString().toLowerCase().trim());
  }

  static List<String> _toList(dynamic value, {bool lowercase = true}) {
    final raw = value is List
        ? value
        : value is String && value.isNotEmpty
        ? value.split(',')
        : const [];
    return raw
        .map((entry) {
          final text = entry.toString().trim();
          return lowercase ? text.toLowerCase() : text;
        })
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return value.toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value.toString());
    }
  }
}
