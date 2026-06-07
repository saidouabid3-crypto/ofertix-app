class CatalogGovernanceConfig {
  final bool publicFilteringEnabled;
  final bool smartRankingEnabled;
  final bool hideQuarantined;
  final bool hideHiddenDuplicates;
  final bool hideRejected;
  final bool hideExplicitPublicInvisible;
  final bool hideMissingLink;
  final bool hideMissingImage;
  final bool hideMissingPrice;
  final bool demoteNeedsReview;
  final bool demoteLimitedInfo;
  final bool strictMode;
  final String? updatedAt;
  final String? updatedBy;

  const CatalogGovernanceConfig({
    this.publicFilteringEnabled = false,
    this.smartRankingEnabled = true,
    this.hideQuarantined = true,
    this.hideHiddenDuplicates = true,
    this.hideRejected = true,
    this.hideExplicitPublicInvisible = true,
    this.hideMissingLink = false,
    this.hideMissingImage = false,
    this.hideMissingPrice = false,
    this.demoteNeedsReview = true,
    this.demoteLimitedInfo = true,
    this.strictMode = false,
    this.updatedAt,
    this.updatedBy,
  });

  factory CatalogGovernanceConfig.fromJson(Map<String, dynamic> j) {
    bool b(String k, bool d) {
      final v = j[k];
      if (v is bool) return v;
      return d;
    }

    return CatalogGovernanceConfig(
      publicFilteringEnabled: b('publicFilteringEnabled', false),
      smartRankingEnabled: b('smartRankingEnabled', true),
      hideQuarantined: b('hideQuarantined', true),
      hideHiddenDuplicates: b('hideHiddenDuplicates', true),
      hideRejected: b('hideRejected', true),
      hideExplicitPublicInvisible: b('hideExplicitPublicInvisible', true),
      hideMissingLink: b('hideMissingLink', false),
      hideMissingImage: b('hideMissingImage', false),
      hideMissingPrice: b('hideMissingPrice', false),
      demoteNeedsReview: b('demoteNeedsReview', true),
      demoteLimitedInfo: b('demoteLimitedInfo', true),
      strictMode: b('strictMode', false),
      updatedAt: j['updatedAt']?.toString(),
      updatedBy: j['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'publicFilteringEnabled': publicFilteringEnabled,
    'smartRankingEnabled': smartRankingEnabled,
    'hideQuarantined': hideQuarantined,
    'hideHiddenDuplicates': hideHiddenDuplicates,
    'hideRejected': hideRejected,
    'hideExplicitPublicInvisible': hideExplicitPublicInvisible,
    'hideMissingLink': hideMissingLink,
    'hideMissingImage': hideMissingImage,
    'hideMissingPrice': hideMissingPrice,
    'demoteNeedsReview': demoteNeedsReview,
    'demoteLimitedInfo': demoteLimitedInfo,
    'strictMode': strictMode,
  };
}

class CatalogPreviewModel {
  final CatalogGovernanceConfig config;
  final int totalProductsScanned;
  final int visibleCount;
  final int hiddenCount;
  final int trustedCount;
  final int needsReviewCount;
  final int quarantinedCount;
  final int priceReviewCount;
  final int missingLinkCount;
  final int missingImageCount;
  final int hiddenDuplicateCount;
  final Map<String, int> hiddenByReason;
  final String? generatedAt;
  final String? error;

  const CatalogPreviewModel({
    required this.config,
    this.totalProductsScanned = 0,
    this.visibleCount = 0,
    this.hiddenCount = 0,
    this.trustedCount = 0,
    this.needsReviewCount = 0,
    this.quarantinedCount = 0,
    this.priceReviewCount = 0,
    this.missingLinkCount = 0,
    this.missingImageCount = 0,
    this.hiddenDuplicateCount = 0,
    this.hiddenByReason = const {},
    this.generatedAt,
    this.error,
  });

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  factory CatalogPreviewModel.fromJson(Map<String, dynamic> j) {
    final rawConfig = j['config'];
    final config = rawConfig is Map
        ? CatalogGovernanceConfig.fromJson(Map<String, dynamic>.from(rawConfig))
        : const CatalogGovernanceConfig();

    final rawReasons = j['hiddenByReason'];
    final Map<String, int> reasons = {};
    if (rawReasons is Map) {
      rawReasons.forEach((k, v) => reasons[k.toString()] = _i(v));
    }

    return CatalogPreviewModel(
      config: config,
      totalProductsScanned: _i(j['totalProductsScanned']),
      visibleCount: _i(j['visibleCount']),
      hiddenCount: _i(j['hiddenCount']),
      trustedCount: _i(j['trustedCount']),
      needsReviewCount: _i(j['needsReviewCount']),
      quarantinedCount: _i(j['quarantinedCount']),
      priceReviewCount: _i(j['priceReviewCount']),
      missingLinkCount: _i(j['missingLinkCount']),
      missingImageCount: _i(j['missingImageCount']),
      hiddenDuplicateCount: _i(j['hiddenDuplicateCount']),
      hiddenByReason: reasons,
      generatedAt: j['generatedAt']?.toString(),
      error: j['error']?.toString(),
    );
  }
}
