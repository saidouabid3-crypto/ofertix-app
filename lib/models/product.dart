class Product {
  final String id;
  final String name;
  final String fullTitle;
  final String image;
  final String mainImage;
  final List<String> images;
  final double oldPrice;
  final double newPrice;
  final int discount;
  final String store;
  final String category;
  final String categoryGroup;
  final String description;
  final String affiliateUrl;
  final bool isHot;
  final String country;
  final String countryCode;
  final List<String> availableCountries;
  final List<String> shipsTo;
  final String currency;
  final double lat;
  final double lng;
  final bool isOnline;
  final int views;
  final int clicks;
  final int sales;
  final bool featured;
  final bool sponsored;
  final bool isExpired;
  final bool isExplicitlyGlobal;
  final DateTime? createdAt;

  // Ofertix Product Standard v1
  final double rating;
  final int reviewCount;
  final int soldCount;
  final int dealScore;
  final int trustScore;
  final int qualityScore;
  final int riskScore;
  final String aiVerdict;
  final String aiVerdictLabel;
  final String fakeDiscountRisk;
  final Map<String, dynamic> dealDNA;
  final String priceAccuracy;
  final String priceSource;
  final bool finalPriceInStore;
  final String priceNote;
  final double shippingPrice;
  final bool freeShipping;
  final String estimatedDelivery;
  final String couponText;
  final bool hasCoupon;
  final List<dynamic> variants;
  final String fingerprint;

  // Trust fields from Batch 13A/13D catalog governance
  final String? trustStatus;
  final String? priceConfidence;
  final String? admissionStatus;
  final String? riskLevel;
  final List<String> qualityFlags;
  final List<String> qualityReasons;
  final bool? publicVisible;
  final double? catalogRankScore;
  final double? sourceTrustScoreAtImport;
  final Map<String, dynamic>? mediaQuality;
  final Map<String, dynamic>? linkHealth;

  const Product({
    required this.id,
    required this.name,
    required this.fullTitle,
    required this.image,
    required this.mainImage,
    required this.images,
    required this.oldPrice,
    required this.newPrice,
    required this.discount,
    required this.store,
    required this.category,
    required this.categoryGroup,
    required this.description,
    required this.affiliateUrl,
    required this.isHot,
    required this.country,
    required this.countryCode,
    required this.availableCountries,
    required this.shipsTo,
    required this.currency,
    required this.lat,
    required this.lng,
    required this.isOnline,
    required this.views,
    required this.clicks,
    required this.sales,
    required this.featured,
    required this.sponsored,
    this.isExpired = false,
    this.isExplicitlyGlobal = false,
    required this.createdAt,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.dealScore,
    required this.trustScore,
    required this.qualityScore,
    required this.riskScore,
    required this.aiVerdict,
    required this.aiVerdictLabel,
    required this.fakeDiscountRisk,
    required this.dealDNA,
    required this.priceAccuracy,
    required this.priceSource,
    required this.finalPriceInStore,
    required this.priceNote,
    required this.shippingPrice,
    required this.freeShipping,
    required this.estimatedDelivery,
    required this.couponText,
    required this.hasCoupon,
    required this.variants,
    required this.fingerprint,
    this.trustStatus,
    this.priceConfidence,
    this.admissionStatus,
    this.riskLevel,
    this.qualityFlags = const [],
    this.qualityReasons = const [],
    this.publicVisible,
    this.catalogRankScore,
    this.sourceTrustScoreAtImport,
    this.mediaQuality,
    this.linkHealth,
  });

  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      var raw = value
          .replaceAll('€', '')
          .replaceAll(r'$', '')
          .replaceAll('EUR', '')
          .replaceAll('USD', '')
          .replaceAll('%', '')
          .trim();
      if (raw.contains(',') && raw.contains('.')) {
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        raw = raw.replaceAll(',', '.');
      }
      return double.tryParse(raw) ?? 0.0;
    }
    return 0.0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String)
      return int.tryParse(value.replaceAll('%', '').trim()) ??
          toDouble(value).round();
    return 0;
  }

  static bool toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes' || v == 'active';
    }
    if (value is num) return value == 1;
    return false;
  }

  static List<String> toList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,|;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
  }

  static DateTime? toDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value.toString().contains('Timestamp')) return value.toDate();
      return DateTime.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    final rawName =
        map['name']?.toString() ?? map['title']?.toString() ?? 'Product';
    final fullTitle =
        map['fullTitle']?.toString() ?? map['title']?.toString() ?? rawName;
    // Aggregate all possible image field variants — deduplication happens below.
    final rawImages = <String>{};
    for (final key in [
      'images', 'imageUrls', 'image_urls', 'gallery',
      'galleryImages', 'gallery_images',
      'productImages', 'product_images',
      'media', 'photos', 'pictures',
    ]) {
      rawImages.addAll(toList(map[key]));
    }
    final image =
        (map['mainImage'] ??
                map['image'] ??
                map['imageUrl'] ??
                map['image_url'] ??
                '')
            .toString();
    final images = <String>[
      if (image.trim().isNotEmpty) image.trim(),
      ...rawImages,
    ].where((e) => e.startsWith('http')).toSet().toList();
    final mainImage = images.isNotEmpty ? images.first : image;
    final country =
        (map['countryCode'] ??
                map['country_code'] ??
                map['country'] ??
                'global')
            .toString()
            .toLowerCase();
    final available = toList(
      map['availableCountries'] ?? map['available_countries'],
    ).map((e) => e.toLowerCase()).toList();
    final ships = toList(
      map['shipsTo'] ?? map['ships_to'],
    ).map((e) => e.toLowerCase()).toList();
    final newPrice = toDouble(
      map['newPrice'] ??
          map['price'] ??
          map['sale_price'] ??
          map['currentPrice'],
    );
    final oldPrice = toDouble(
      map['oldPrice'] ?? map['old_price'] ?? map['original_price'],
    );
    int finalDiscount = toInt(map['discount']);
    if (finalDiscount == 0 && oldPrice > 0 && oldPrice > newPrice) {
      finalDiscount = (((oldPrice - newPrice) / oldPrice) * 100).round();
    }
    final lat = toDouble(map['lat']);
    final lng = toDouble(map['lng']);
    var online = lat == 0 && lng == 0;
    if (map.containsKey('isOnline')) online = toBool(map['isOnline']);
    final dnaRaw = map['dealDNA'];

    return Product(
      id: documentId.isNotEmpty ? documentId : (map['id']?.toString() ?? ''),
      name: rawName,
      fullTitle: fullTitle,
      image: mainImage,
      mainImage: mainImage,
      images: images,
      oldPrice: oldPrice,
      newPrice: newPrice,
      discount: finalDiscount,
      store: map['store']?.toString() ?? map['source']?.toString() ?? 'Store',
      category: map['category']?.toString() ?? 'General',
      categoryGroup:
          map['categoryGroup']?.toString() ??
          map['category']?.toString() ??
          'General',
      description: map['description']?.toString() ?? fullTitle,
      affiliateUrl:
          map['affiliateUrl']?.toString() ??
          map['affiliate_url']?.toString() ??
          map['affiliateURL']?.toString() ??
          map['productUrl']?.toString() ??
          map['product_url']?.toString() ??
          map['productURL']?.toString() ??
          map['sourceUrl']?.toString() ??
          map['source_url']?.toString() ??
          map['originalUrl']?.toString() ??
          map['original_url']?.toString() ??
          map['storeUrl']?.toString() ??
          map['store_url']?.toString() ??
          map['link']?.toString() ??
          map['url']?.toString() ??
          '',
      isHot: toBool(map['isHot']) || toInt(map['dealScore']) >= 75,
      country: country,
      countryCode: country,
      availableCountries: available,
      shipsTo: ships,
      currency: map['currency']?.toString() ?? 'EUR',
      lat: lat,
      lng: lng,
      isOnline: online,
      views: toInt(map['views']),
      clicks: toInt(map['clicks']),
      sales: toInt(map['sales'] ?? map['soldCount'] ?? map['sold']),
      featured: toBool(map['featured']) || toInt(map['trustScore']) >= 75,
      sponsored: toBool(map['sponsored']),
      isExpired: toBool(map['isExpired'] ?? map['is_expired']),
      isExplicitlyGlobal: toBool(
        map['isExplicitlyGlobal'] ?? map['is_explicitly_global'],
      ),
      createdAt: toDate(map['createdAt']),
      rating: toDouble(map['rating'] ?? map['averageRating']),
      reviewCount: toInt(
        map['reviewCount'] ?? map['reviews'] ?? map['reviewsCount'],
      ),
      soldCount: toInt(map['soldCount'] ?? map['sold'] ?? map['sales']),
      dealScore: toInt(map['dealScore']),
      trustScore: toInt(map['trustScore']),
      qualityScore: toInt(map['qualityScore']),
      riskScore: toInt(map['riskScore']),
      aiVerdict: map['aiVerdict']?.toString() ?? 'wait',
      aiVerdictLabel: map['aiVerdictLabel']?.toString() ?? 'Wait',
      fakeDiscountRisk: map['fakeDiscountRisk']?.toString() ?? 'unknown',
      dealDNA: dnaRaw is Map ? Map<String, dynamic>.from(dnaRaw) : const {},
      priceAccuracy: map['priceAccuracy']?.toString() ?? 'estimated',
      priceSource: map['priceSource']?.toString() ?? 'feed',
      finalPriceInStore: map.containsKey('finalPriceInStore')
          ? toBool(map['finalPriceInStore'])
          : true,
      priceNote:
          map['priceNote']?.toString() ??
          'Precio aprox. · precio final en tienda',
      shippingPrice: toDouble(map['shippingPrice'] ?? map['shipping_price']),
      freeShipping: toBool(map['freeShipping'] ?? map['free_shipping']),
      estimatedDelivery:
          map['estimatedDelivery']?.toString() ??
          map['deliveryTime']?.toString() ??
          '',
      couponText:
          map['couponText']?.toString() ??
          map['coupon']?.toString() ??
          map['promoCode']?.toString() ??
          '',
      hasCoupon:
          toBool(map['hasCoupon']) ||
          ((map['couponText'] ?? map['coupon'] ?? map['promoCode'])
                  ?.toString()
                  .trim()
                  .isNotEmpty ??
              false),
      variants: map['variants'] is List
          ? List<dynamic>.from(map['variants'])
          : const [],
      fingerprint: map['fingerprint']?.toString() ?? '',
      trustStatus: map['trustStatus']?.toString(),
      priceConfidence: map['priceConfidence']?.toString(),
      admissionStatus: map['admissionStatus']?.toString(),
      riskLevel: map['riskLevel']?.toString(),
      qualityFlags: toList(map['qualityFlags']),
      qualityReasons: toList(map['qualityReasons']),
      publicVisible: map.containsKey('publicVisible')
          ? toBool(map['publicVisible'])
          : null,
      catalogRankScore: map['catalogRankScore'] != null
          ? toDouble(map['catalogRankScore'])
          : null,
      sourceTrustScoreAtImport: map['sourceTrustScoreAtImport'] != null
          ? toDouble(map['sourceTrustScoreAtImport'])
          : null,
      mediaQuality: map['mediaQuality'] is Map
          ? Map<String, dynamic>.from(map['mediaQuality'] as Map)
          : null,
      linkHealth: map['linkHealth'] is Map
          ? Map<String, dynamic>.from(map['linkHealth'] as Map)
          : null,
    );
  }

  bool isAvailableForCountry(String code) {
    if (isExpired) return false;

    final c = code.toLowerCase();
    if (c == 'global') return true;

    if (isExplicitlyGlobal) {
      return shipsTo.contains(c) || availableCountries.contains(c);
    }

    if (countryCode == 'global') return false;

    return countryCode == c;
  }

  double get savings => oldPrice <= 0 ? 0.0 : oldPrice - newPrice;
  bool get hasRealDiscount => oldPrice > newPrice;
  bool get isTrending =>
      views > 1000 || clicks > 150 || soldCount > 500 || reviewCount > 300;
  bool get isNearbyStore => !isOnline && lat != 0.0 && lng != 0.0;
  bool get isGlobal => countryCode == 'global';
  bool get hasImage => image.isNotEmpty;
  bool get hasValidPrice => newPrice > 0;
  bool get hasAffiliateLink => affiliateUrl.isNotEmpty;
  bool get hasMultipleImages => images.length > 1;
  String get priceLabel =>
      priceAccuracy == 'live' ? 'product.priceCurrent' : 'product.approxPrice';
  String get ratingLabel => rating > 0 ? rating.toStringAsFixed(1) : '—';
  String get reviewLabel => reviewCount >= 1000
      ? '${(reviewCount / 1000).toStringAsFixed(1)}k'
      : reviewCount.toString();
  String get soldLabel => soldCount >= 1000
      ? '${(soldCount / 1000).toStringAsFixed(1)}k'
      : soldCount.toString();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'fullTitle': fullTitle,
    'image': image,
    'mainImage': mainImage,
    'images': images,
    'oldPrice': oldPrice,
    'newPrice': newPrice,
    'discount': discount,
    'store': store,
    'category': category,
    'categoryGroup': categoryGroup,
    'description': description,
    'affiliateUrl': affiliateUrl,
    'isHot': isHot,
    'country': countryCode,
    'countryCode': countryCode,
    'availableCountries': availableCountries,
    'shipsTo': shipsTo,
    'currency': currency,
    'lat': lat,
    'lng': lng,
    'isOnline': isOnline,
    'views': views,
    'clicks': clicks,
    'sales': sales,
    'featured': featured,
    'sponsored': sponsored,
    'createdAt': createdAt?.toIso8601String(),
    'rating': rating,
    'reviewCount': reviewCount,
    'soldCount': soldCount,
    'dealScore': dealScore,
    'trustScore': trustScore,
    'qualityScore': qualityScore,
    'riskScore': riskScore,
    'aiVerdict': aiVerdict,
    'aiVerdictLabel': aiVerdictLabel,
    'fakeDiscountRisk': fakeDiscountRisk,
    'dealDNA': dealDNA,
    'priceAccuracy': priceAccuracy,
    'priceSource': priceSource,
    'finalPriceInStore': finalPriceInStore,
    'priceNote': priceNote,
    'shippingPrice': shippingPrice,
    'freeShipping': freeShipping,
    'estimatedDelivery': estimatedDelivery,
    'couponText': couponText,
    'hasCoupon': hasCoupon,
    'variants': variants,
    'fingerprint': fingerprint,
    if (trustStatus != null) 'trustStatus': trustStatus,
    if (priceConfidence != null) 'priceConfidence': priceConfidence,
    if (admissionStatus != null) 'admissionStatus': admissionStatus,
    if (riskLevel != null) 'riskLevel': riskLevel,
    'qualityFlags': qualityFlags,
    'qualityReasons': qualityReasons,
    if (publicVisible != null) 'publicVisible': publicVisible,
    if (catalogRankScore != null) 'catalogRankScore': catalogRankScore,
    if (sourceTrustScoreAtImport != null)
      'sourceTrustScoreAtImport': sourceTrustScoreAtImport,
    if (mediaQuality != null) 'mediaQuality': mediaQuality,
    if (linkHealth != null) 'linkHealth': linkHealth,
  };
}

typedef ProductModel = Product;
