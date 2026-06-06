class AdminImportBatchModel {
  final String batchId;
  final String? source;
  final String? sourceType;
  final String? store;
  final String? startedAt;
  final String? finishedAt;
  final String? status;
  final bool dryRun;
  final int imported;
  final int created;
  final int updated;
  final int skipped;
  final int failed;
  final int approved;
  final int needsReview;
  final int quarantined;
  final int duplicateCandidates;
  final int missingImage;
  final int missingLink;
  final int missingPrice;
  final int missingCurrency;
  final int singleImageOnly;
  final int noGallery;
  final int duplicateImages;
  final int qualityWarnings;
  final int? sourceTrustScore;
  final List<String> errors;
  final List<String> warnings;
  final int? durationMs;
  final String? createdBy;

  const AdminImportBatchModel({
    required this.batchId,
    this.source,
    this.sourceType,
    this.store,
    this.startedAt,
    this.finishedAt,
    this.status,
    this.dryRun = false,
    this.imported = 0,
    this.created = 0,
    this.updated = 0,
    this.skipped = 0,
    this.failed = 0,
    this.approved = 0,
    this.needsReview = 0,
    this.quarantined = 0,
    this.duplicateCandidates = 0,
    this.missingImage = 0,
    this.missingLink = 0,
    this.missingPrice = 0,
    this.missingCurrency = 0,
    this.singleImageOnly = 0,
    this.noGallery = 0,
    this.duplicateImages = 0,
    this.qualityWarnings = 0,
    this.sourceTrustScore,
    this.errors = const [],
    this.warnings = const [],
    this.durationMs,
    this.createdBy,
  });

  factory AdminImportBatchModel.fromJson(Map<String, dynamic> j) {
    return AdminImportBatchModel(
      batchId: j['batchId']?.toString() ?? j['id']?.toString() ?? '',
      source: j['source']?.toString(),
      sourceType: j['sourceType']?.toString(),
      store: j['store']?.toString(),
      startedAt: j['startedAt']?.toString(),
      finishedAt: j['finishedAt']?.toString(),
      status: j['status']?.toString(),
      dryRun: j['dryRun'] == true,
      imported: _i(j['imported']),
      created: _i(j['created']),
      updated: _i(j['updated']),
      skipped: _i(j['skipped']),
      failed: _i(j['failed']),
      approved: _i(j['approved']),
      needsReview: _i(j['needsReview']),
      quarantined: _i(j['quarantined']),
      duplicateCandidates: _i(j['duplicateCandidates']),
      missingImage: _i(j['missingImage']),
      missingLink: _i(j['missingLink']),
      missingPrice: _i(j['missingPrice']),
      missingCurrency: _i(j['missingCurrency']),
      singleImageOnly: _i(j['singleImageOnly']),
      noGallery: _i(j['noGallery']),
      duplicateImages: _i(j['duplicateImages']),
      qualityWarnings: _i(j['qualityWarnings']),
      sourceTrustScore: j['sourceTrustScore'] != null ? _i(j['sourceTrustScore']) : null,
      errors: _strList(j['errors']),
      warnings: _strList(j['warnings']),
      durationMs: j['durationMs'] != null ? _i(j['durationMs']) : null,
      createdBy: j['createdBy']?.toString(),
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

  bool get hasWarnings =>
      missingImage > 0 ||
      missingLink > 0 ||
      missingPrice > 0 ||
      quarantined > 0 ||
      duplicateCandidates > 0;
}

class AdminImportBatchListModel {
  final List<AdminImportBatchModel> batches;
  final int total;

  const AdminImportBatchListModel({this.batches = const [], this.total = 0});

  factory AdminImportBatchListModel.fromJson(Map<String, dynamic> j) {
    final list = j['batches'];
    return AdminImportBatchListModel(
      batches: list is List
          ? list.whereType<Map<String, dynamic>>().map(AdminImportBatchModel.fromJson).toList()
          : [],
      total: AdminImportBatchModel._i(j['total']),
    );
  }
}
