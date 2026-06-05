class AdminLogEntryModel {
  final String id;
  final String adminUid;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String? beforeStatus;
  final String? afterStatus;
  final String? reason;
  final String? note;
  final String? createdAt;

  const AdminLogEntryModel({
    required this.id,
    this.adminUid = '',
    this.adminEmail = '',
    this.action = '',
    this.targetType = '',
    this.targetId = '',
    this.beforeStatus,
    this.afterStatus,
    this.reason,
    this.note,
    this.createdAt,
  });

  factory AdminLogEntryModel.fromJson(Map<String, dynamic> j) {
    return AdminLogEntryModel(
      id: j['id']?.toString() ?? '',
      adminUid: j['adminUid']?.toString() ?? '',
      adminEmail: j['adminEmail']?.toString() ?? '',
      action: j['action']?.toString() ?? '',
      targetType: j['targetType']?.toString() ?? '',
      targetId: j['targetId']?.toString() ?? '',
      beforeStatus: j['beforeStatus']?.toString(),
      afterStatus: j['afterStatus']?.toString(),
      reason: j['reason']?.toString(),
      note: j['note']?.toString(),
      createdAt: j['createdAt']?.toString(),
    );
  }
}

class AdminLogListModel {
  final List<AdminLogEntryModel> logs;
  final int total;

  const AdminLogListModel({this.logs = const [], this.total = 0});

  factory AdminLogListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['logs'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AdminLogEntryModel.fromJson).toList()
        : <AdminLogEntryModel>[];
    return AdminLogListModel(
      logs: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
