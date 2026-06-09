class AdminSourceTrustModel {
  final String id;
  final String? source;
  final String? store;
  final String? domain;
  final int sourceTrustScore;
  final String status;
  final int totalImported;
  final int totalFailed;
  final int totalUpdated;
  final int totalDuplicates;
  final int totalMissingImage;
  final int totalMissingLink;
  final int totalMissingPrice;
  final int totalQuarantined;
  final int totalNeedsReview;
  final int successfulBatches;
  final int failedBatches;
  final String? lastImportAt;
  final String? lastSuccessfulImportAt;
  final String? lastFailedImportAt;
  final List<String> reasons;
  final String? updatedAt;

  const AdminSourceTrustModel({
    required this.id,
    this.source,
    this.store,
    this.domain,
    this.sourceTrustScore = 100,
    this.status = 'ok',
    this.totalImported = 0,
    this.totalFailed = 0,
    this.totalUpdated = 0,
    this.totalDuplicates = 0,
    this.totalMissingImage = 0,
    this.totalMissingLink = 0,
    this.totalMissingPrice = 0,
    this.totalQuarantined = 0,
    this.totalNeedsReview = 0,
    this.successfulBatches = 0,
    this.failedBatches = 0,
    this.lastImportAt,
    this.lastSuccessfulImportAt,
    this.lastFailedImportAt,
    this.reasons = const [],
    this.updatedAt,
  });

  factory AdminSourceTrustModel.fromJson(Map<String, dynamic> j) {
    return AdminSourceTrustModel(
      id: j['id']?.toString() ?? '',
      source: j['source']?.toString(),
      store: j['store']?.toString(),
      domain: j['domain']?.toString(),
      sourceTrustScore: j.containsKey('sourceTrustScore')
          ? _i(j['sourceTrustScore'])
          : 100,
      status: j['status']?.toString() ?? 'ok',
      totalImported: _i(j['totalImported']),
      totalFailed: _i(j['totalFailed']),
      totalUpdated: _i(j['totalUpdated']),
      totalDuplicates: _i(j['totalDuplicates']),
      totalMissingImage: _i(j['totalMissingImage']),
      totalMissingLink: _i(j['totalMissingLink']),
      totalMissingPrice: _i(j['totalMissingPrice']),
      totalQuarantined: _i(j['totalQuarantined']),
      totalNeedsReview: _i(j['totalNeedsReview']),
      successfulBatches: _i(j['successfulBatches']),
      failedBatches: _i(j['failedBatches']),
      lastImportAt: j['lastImportAt']?.toString(),
      lastSuccessfulImportAt: j['lastSuccessfulImportAt']?.toString(),
      lastFailedImportAt: j['lastFailedImportAt']?.toString(),
      reasons: _strList(j['reasons']),
      updatedAt: j['updatedAt']?.toString(),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<String> _strList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).toList();
  }

  String get displayName => source ?? store ?? domain ?? id;

  bool get isAtRisk => status == 'risky' || status == 'blocked';
}

class AdminSourceTrustListModel {
  final List<AdminSourceTrustModel> items;
  final int total;

  const AdminSourceTrustListModel({this.items = const [], this.total = 0});

  factory AdminSourceTrustListModel.fromJson(Map<String, dynamic> j) {
    final list = j['items'];
    return AdminSourceTrustListModel(
      items: list is List
          ? list
                .whereType<Map<String, dynamic>>()
                .map(AdminSourceTrustModel.fromJson)
                .toList()
          : [],
      total: AdminSourceTrustModel._i(j['total']),
    );
  }
}
