class AdminDuplicateProductModel {
  final String id;
  final String? name;
  final String? imageUrl;
  final int galleryCount;
  final double? price;
  final String? currency;
  final String? store;
  final String? primaryUrl;
  final bool hasAffiliateUrl;
  final bool hasProductUrl;
  final int? qualityScore;
  final String? trustStatus;
  final String? priceConfidence;
  final String? duplicateStatus;
  final List<String> duplicateReasons;
  final int duplicateScore;
  final String? status;
  final String? updatedAt;

  const AdminDuplicateProductModel({
    required this.id,
    this.name,
    this.imageUrl,
    this.galleryCount = 0,
    this.price,
    this.currency,
    this.store,
    this.primaryUrl,
    this.hasAffiliateUrl = false,
    this.hasProductUrl = false,
    this.qualityScore,
    this.trustStatus,
    this.priceConfidence,
    this.duplicateStatus,
    this.duplicateReasons = const [],
    this.duplicateScore = 0,
    this.status,
    this.updatedAt,
  });

  factory AdminDuplicateProductModel.fromJson(Map<String, dynamic> j) {
    final rawReasons = j['duplicateReasons'];
    final reasons = rawReasons is List ? rawReasons.whereType<String>().toList() : <String>[];
    return AdminDuplicateProductModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString(),
      imageUrl: j['imageUrl']?.toString(),
      galleryCount: _i(j['galleryCount']),
      price: _d(j['price']),
      currency: j['currency']?.toString(),
      store: j['store']?.toString(),
      primaryUrl: j['primaryUrl']?.toString(),
      hasAffiliateUrl: j['hasAffiliateUrl'] == true,
      hasProductUrl: j['hasProductUrl'] == true,
      qualityScore: j['qualityScore'] is int ? j['qualityScore'] as int : null,
      trustStatus: j['trustStatus']?.toString(),
      priceConfidence: j['priceConfidence']?.toString(),
      duplicateStatus: j['duplicateStatus']?.toString(),
      duplicateReasons: reasons,
      duplicateScore: _i(j['duplicateScore']),
      status: j['status']?.toString(),
      updatedAt: j['updatedAt']?.toString(),
    );
  }

  static int _i(dynamic v) => v is int ? v : (v is double ? v.toInt() : 0);
  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AdminDuplicateGroupModel {
  final String groupId;
  final String? reasonSummary;
  final int highestScore;
  final List<AdminDuplicateProductModel> products;

  const AdminDuplicateGroupModel({
    required this.groupId,
    this.reasonSummary,
    this.highestScore = 0,
    this.products = const [],
  });

  factory AdminDuplicateGroupModel.fromJson(Map<String, dynamic> j) {
    final rawProducts = j['products'];
    final products = rawProducts is List
        ? rawProducts.whereType<Map<String, dynamic>>().map(AdminDuplicateProductModel.fromJson).toList()
        : <AdminDuplicateProductModel>[];
    return AdminDuplicateGroupModel(
      groupId: j['groupId']?.toString() ?? '',
      reasonSummary: j['reasonSummary']?.toString(),
      highestScore: j['highestScore'] is int ? j['highestScore'] as int : 0,
      products: products,
    );
  }
}

class AdminDuplicateGroupListModel {
  final List<AdminDuplicateGroupModel> groups;
  final int total;

  const AdminDuplicateGroupListModel({this.groups = const [], this.total = 0});

  factory AdminDuplicateGroupListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['groups'];
    final groups = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AdminDuplicateGroupModel.fromJson).toList()
        : <AdminDuplicateGroupModel>[];
    return AdminDuplicateGroupListModel(
      groups: groups,
      total: j['total'] is int ? j['total'] as int : groups.length,
    );
  }
}

class AdminDuplicateScanSummaryModel {
  final int scanned;
  final int groupsFound;
  final int candidateProducts;
  final int wouldUpdate;
  final int updated;
  final bool dryRun;

  const AdminDuplicateScanSummaryModel({
    this.scanned = 0,
    this.groupsFound = 0,
    this.candidateProducts = 0,
    this.wouldUpdate = 0,
    this.updated = 0,
    this.dryRun = true,
  });

  factory AdminDuplicateScanSummaryModel.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v is int ? v : (v is double ? v.toInt() : 0);
    return AdminDuplicateScanSummaryModel(
      scanned: asInt(j['scanned']),
      groupsFound: asInt(j['groupsFound']),
      candidateProducts: asInt(j['candidateProducts']),
      wouldUpdate: asInt(j['wouldUpdate']),
      updated: asInt(j['updated']),
      dryRun: j['dryRun'] != false,
    );
  }
}
