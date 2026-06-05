class AdminSystemErrorModel {
  final String id;
  final String? path;
  final String? message;
  final String? createdAt;

  const AdminSystemErrorModel({
    required this.id,
    this.path,
    this.message,
    this.createdAt,
  });

  factory AdminSystemErrorModel.fromJson(Map<String, dynamic> j) {
    return AdminSystemErrorModel(
      id: j['id']?.toString() ?? '',
      path: j['path']?.toString(),
      message: j['message']?.toString(),
      createdAt: j['createdAt']?.toString(),
    );
  }
}

class AdminImportLogModel {
  final String id;
  final String? source;
  final String? status;
  final int itemsImported;
  final int errors;
  final String? createdAt;

  const AdminImportLogModel({
    required this.id,
    this.source,
    this.status,
    this.itemsImported = 0,
    this.errors = 0,
    this.createdAt,
  });

  factory AdminImportLogModel.fromJson(Map<String, dynamic> j) {
    return AdminImportLogModel(
      id: j['id']?.toString() ?? '',
      source: j['source']?.toString(),
      status: j['status']?.toString(),
      itemsImported: _i(j['itemsImported']),
      errors: _i(j['errors']),
      createdAt: j['createdAt']?.toString(),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class AdminScrapeFailureModel {
  final String id;
  final String? url;
  final String? source;
  final String? error;
  final String? createdAt;

  const AdminScrapeFailureModel({
    required this.id,
    this.url,
    this.source,
    this.error,
    this.createdAt,
  });

  factory AdminScrapeFailureModel.fromJson(Map<String, dynamic> j) {
    return AdminScrapeFailureModel(
      id: j['id']?.toString() ?? '',
      url: j['url']?.toString(),
      source: j['source']?.toString(),
      error: j['error']?.toString(),
      createdAt: j['createdAt']?.toString(),
    );
  }
}

class AdminAiErrorModel {
  final String id;
  final String? subject;
  final String? uid;
  final bool blocked;
  final String? createdAt;

  const AdminAiErrorModel({
    required this.id,
    this.subject,
    this.uid,
    this.blocked = false,
    this.createdAt,
  });

  factory AdminAiErrorModel.fromJson(Map<String, dynamic> j) {
    return AdminAiErrorModel(
      id: j['id']?.toString() ?? '',
      subject: j['subject']?.toString(),
      uid: j['uid']?.toString(),
      blocked: j['blocked'] == true,
      createdAt: j['createdAt']?.toString(),
    );
  }
}

class AdminSystemHealthModel {
  final List<AdminSystemErrorModel> systemErrors;
  final List<AdminImportLogModel> importLogs;
  final List<AdminAiErrorModel> aiErrors;
  final List<AdminScrapeFailureModel> failedScrapings;

  const AdminSystemHealthModel({
    this.systemErrors = const [],
    this.importLogs = const [],
    this.aiErrors = const [],
    this.failedScrapings = const [],
  });

  factory AdminSystemHealthModel.fromJson(Map<String, dynamic> j) {
    return AdminSystemHealthModel(
      systemErrors: _parseList(j['systemErrors'], AdminSystemErrorModel.fromJson),
      importLogs: _parseList(j['importLogs'], AdminImportLogModel.fromJson),
      aiErrors: _parseList(j['aiErrors'], AdminAiErrorModel.fromJson),
      failedScrapings: _parseList(j['failedScrapings'], AdminScrapeFailureModel.fromJson),
    );
  }

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) factory) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(factory).toList();
  }
}
