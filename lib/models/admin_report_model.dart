class AdminReportModel {
  final String id;
  final String reportType;
  final String? targetId;
  final String? targetTitle;
  final String? reporterId;
  final String? reporterName;
  final String? reason;
  final String status;
  final String? adminNote;
  final String? createdAt;
  final String? updatedAt;

  const AdminReportModel({
    required this.id,
    this.reportType = 'unknown',
    this.targetId,
    this.targetTitle,
    this.reporterId,
    this.reporterName,
    this.reason,
    this.status = 'open',
    this.adminNote,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> j) {
    return AdminReportModel(
      id: j['id']?.toString() ?? '',
      reportType: j['reportType']?.toString() ?? 'unknown',
      targetId: j['targetId']?.toString(),
      targetTitle: j['targetTitle']?.toString(),
      reporterId: j['reporterId']?.toString(),
      reporterName: j['reporterName']?.toString(),
      reason: j['reason']?.toString(),
      status: j['status']?.toString() ?? 'open',
      adminNote: j['adminNote']?.toString(),
      createdAt: j['createdAt']?.toString(),
      updatedAt: j['updatedAt']?.toString(),
    );
  }
}

class AdminReportListModel {
  final List<AdminReportModel> reports;
  final int total;

  const AdminReportListModel({this.reports = const [], this.total = 0});

  factory AdminReportListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['reports'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AdminReportModel.fromJson).toList()
        : <AdminReportModel>[];
    return AdminReportListModel(
      reports: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
