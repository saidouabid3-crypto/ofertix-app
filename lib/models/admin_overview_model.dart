class AdminOverviewModel {
  final int totalUsers;
  final int totalReels;
  final int pendingReels;
  final int reportedReels;
  final int hiddenReels;
  final int rejectedReels;
  final int totalSellItems;
  final int pendingSellItems;
  final int reportedSellItems;
  final int totalReports;
  final int openReports;
  final int systemErrors;
  final int aiErrors;
  final int failedUploads;
  final int totalProducts;

  const AdminOverviewModel({
    this.totalUsers = 0,
    this.totalReels = 0,
    this.pendingReels = 0,
    this.reportedReels = 0,
    this.hiddenReels = 0,
    this.rejectedReels = 0,
    this.totalSellItems = 0,
    this.pendingSellItems = 0,
    this.reportedSellItems = 0,
    this.totalReports = 0,
    this.openReports = 0,
    this.systemErrors = 0,
    this.aiErrors = 0,
    this.failedUploads = 0,
    this.totalProducts = 0,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> j) {
    return AdminOverviewModel(
      totalUsers: _i(j['totalUsers']),
      totalReels: _i(j['totalReels']),
      pendingReels: _i(j['pendingReels']),
      reportedReels: _i(j['reportedReels']),
      hiddenReels: _i(j['hiddenReels']),
      rejectedReels: _i(j['rejectedReels']),
      totalSellItems: _i(j['totalSellItems']),
      pendingSellItems: _i(j['pendingSellItems']),
      reportedSellItems: _i(j['reportedSellItems']),
      totalReports: _i(j['totalReports']),
      openReports: _i(j['openReports']),
      systemErrors: _i(j['systemErrors']),
      aiErrors: _i(j['aiErrors']),
      failedUploads: _i(j['failedUploads']),
      totalProducts: _i(j['totalProducts']),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
