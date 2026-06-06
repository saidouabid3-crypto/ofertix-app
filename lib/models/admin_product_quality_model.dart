class ProductMediaQualityModel {
  final String? mainImage;
  final List<String> gallery;
  final int validImageCount;
  final int duplicateImageCount;
  final bool hasMultipleImages;

  const ProductMediaQualityModel({
    this.mainImage,
    this.gallery = const [],
    this.validImageCount = 0,
    this.duplicateImageCount = 0,
    this.hasMultipleImages = false,
  });

  factory ProductMediaQualityModel.fromJson(Map<String, dynamic> j) {
    final rawGallery = j['gallery'];
    final gallery = rawGallery is List ? rawGallery.whereType<String>().toList() : <String>[];
    return ProductMediaQualityModel(
      mainImage: j['mainImage']?.toString(),
      gallery: gallery,
      validImageCount: _i(j['validImageCount']),
      duplicateImageCount: _i(j['duplicateImageCount']),
      hasMultipleImages: j['hasMultipleImages'] == true,
    );
  }

  static int _i(dynamic v) => v is int ? v : (v is double ? v.toInt() : 0);
}

class ProductLinkHealthModel {
  final bool hasAffiliateUrl;
  final bool hasProductUrl;
  final String? primaryUrl;
  final bool isValidHttpUrl;

  const ProductLinkHealthModel({
    this.hasAffiliateUrl = false,
    this.hasProductUrl = false,
    this.primaryUrl,
    this.isValidHttpUrl = false,
  });

  factory ProductLinkHealthModel.fromJson(Map<String, dynamic> j) {
    return ProductLinkHealthModel(
      hasAffiliateUrl: j['hasAffiliateUrl'] == true,
      hasProductUrl: j['hasProductUrl'] == true,
      primaryUrl: j['primaryUrl']?.toString(),
      isValidHttpUrl: j['isValidHttpUrl'] == true,
    );
  }
}

class ProductTrustScanSummaryModel {
  final int scanned;
  final int wouldUpdate;
  final int updated;
  final int missingImage;
  final int missingLink;
  final int missingPrice;
  final int singleImageOnly;
  final int duplicates;
  final int quarantined;
  final int needsReview;
  final int trusted;
  final bool dryRun;

  const ProductTrustScanSummaryModel({
    this.scanned = 0,
    this.wouldUpdate = 0,
    this.updated = 0,
    this.missingImage = 0,
    this.missingLink = 0,
    this.missingPrice = 0,
    this.singleImageOnly = 0,
    this.duplicates = 0,
    this.quarantined = 0,
    this.needsReview = 0,
    this.trusted = 0,
    this.dryRun = true,
  });

  factory ProductTrustScanSummaryModel.fromJson(Map<String, dynamic> j) {
    return ProductTrustScanSummaryModel(
      scanned: _i(j['scanned']),
      wouldUpdate: _i(j['wouldUpdate']),
      updated: _i(j['updated']),
      missingImage: _i(j['missingImage']),
      missingLink: _i(j['missingLink']),
      missingPrice: _i(j['missingPrice']),
      singleImageOnly: _i(j['singleImageOnly']),
      duplicates: _i(j['duplicates']),
      quarantined: _i(j['quarantined']),
      needsReview: _i(j['needsReview']),
      trusted: _i(j['trusted']),
      dryRun: j['dryRun'] != false,
    );
  }

  static int _i(dynamic v) => v is int ? v : (v is double ? v.toInt() : 0);
}

class AdminProductQualityItemModel {
  final String id;
  final String? name;
  final String? store;
  final double? price;
  final String? imageUrl;
  final String? affiliateUrl;
  final String? status;
  final String? issue;
  final String? countryCode;
  // Trust engine fields
  final int? qualityScore;
  final String? trustStatus;
  final List<String> qualityFlags;
  final ProductMediaQualityModel? mediaQuality;
  final ProductLinkHealthModel? linkHealth;
  final String? priceConfidence;
  final String? qualityUpdatedAt;

  const AdminProductQualityItemModel({
    required this.id,
    this.name,
    this.store,
    this.price,
    this.imageUrl,
    this.affiliateUrl,
    this.status,
    this.issue,
    this.countryCode,
    this.qualityScore,
    this.trustStatus,
    this.qualityFlags = const [],
    this.mediaQuality,
    this.linkHealth,
    this.priceConfidence,
    this.qualityUpdatedAt,
  });

  factory AdminProductQualityItemModel.fromJson(Map<String, dynamic> j) {
    final rawFlags = j['qualityFlags'];
    final flags = rawFlags is List ? rawFlags.whereType<String>().toList() : <String>[];

    ProductMediaQualityModel? media;
    final rawMedia = j['mediaQuality'];
    if (rawMedia is Map<String, dynamic>) {
      media = ProductMediaQualityModel.fromJson(rawMedia);
    }

    ProductLinkHealthModel? link;
    final rawLink = j['linkHealth'];
    if (rawLink is Map<String, dynamic>) {
      link = ProductLinkHealthModel.fromJson(rawLink);
    }

    return AdminProductQualityItemModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString(),
      store: j['store']?.toString(),
      price: _d(j['price']),
      imageUrl: j['imageUrl']?.toString(),
      affiliateUrl: j['affiliateUrl']?.toString(),
      status: j['status']?.toString(),
      issue: j['issue']?.toString(),
      countryCode: j['countryCode']?.toString(),
      qualityScore: j['qualityScore'] is int ? j['qualityScore'] as int : null,
      trustStatus: j['trustStatus']?.toString(),
      qualityFlags: flags,
      mediaQuality: media,
      linkHealth: link,
      priceConfidence: j['priceConfidence']?.toString(),
      qualityUpdatedAt: j['qualityUpdatedAt']?.toString(),
    );
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AdminProductQualityListModel {
  final List<AdminProductQualityItemModel> items;
  final int total;

  const AdminProductQualityListModel({this.items = const [], this.total = 0});

  factory AdminProductQualityListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AdminProductQualityItemModel.fromJson).toList()
        : <AdminProductQualityItemModel>[];
    return AdminProductQualityListModel(
      items: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
