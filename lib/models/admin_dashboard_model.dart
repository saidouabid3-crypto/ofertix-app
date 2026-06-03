class AdminTopProductModel {
  final String id;
  final String name;
  final String store;
  final int clicks;
  final double revenue;
  final String countryCode;

  const AdminTopProductModel({
    required this.id,
    required this.name,
    required this.store,
    required this.clicks,
    required this.revenue,
    required this.countryCode,
  });

  factory AdminTopProductModel.fromJson(Map<String, dynamic> json) {
    return AdminTopProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      store: json['store']?.toString() ?? '',
      clicks: _toInt(json['clicks']),
      revenue: _toDouble(json['revenue']),
      countryCode: json['countryCode']?.toString() ?? 'global',
    );
  }
}

class AdminConnectorStatusModel {
  final String source;
  final String countryCode;
  final bool enabled;
  final String lastStatus;
  final String lastError;
  final String? lastSyncAt;

  const AdminConnectorStatusModel({
    required this.source,
    required this.countryCode,
    required this.enabled,
    required this.lastStatus,
    required this.lastError,
    required this.lastSyncAt,
  });

  factory AdminConnectorStatusModel.fromJson(Map<String, dynamic> json) {
    return AdminConnectorStatusModel(
      source: json['source']?.toString() ?? 'unknown',
      countryCode: json['countryCode']?.toString() ?? 'global',
      enabled: json['enabled'] == true,
      lastStatus: json['lastStatus']?.toString() ?? 'not_configured',
      lastError: json['lastError']?.toString() ?? '',
      lastSyncAt: json['lastSyncAt']?.toString(),
    );
  }
}

class AdminAiQueryLogModel {
  final String id;
  final String? subject;
  final String? uid;
  final int count;
  final bool blocked;
  final String? createdAt;

  const AdminAiQueryLogModel({
    required this.id,
    this.subject,
    this.uid,
    required this.count,
    required this.blocked,
    this.createdAt,
  });

  factory AdminAiQueryLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAiQueryLogModel(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString(),
      uid: json['uid']?.toString(),
      count: _toInt(json['count']),
      blocked: json['blocked'] == true,
      createdAt: json['createdAt']?.toString(),
    );
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

  factory AdminScrapeFailureModel.fromJson(Map<String, dynamic> json) {
    return AdminScrapeFailureModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString(),
      source: json['source']?.toString(),
      error: json['error']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminFlaggedProductModel {
  final String id;
  final String? name;
  final String? store;
  final String? adminIssue;
  final String? countryCode;

  const AdminFlaggedProductModel({
    required this.id,
    this.name,
    this.store,
    this.adminIssue,
    this.countryCode,
  });

  factory AdminFlaggedProductModel.fromJson(Map<String, dynamic> json) {
    return AdminFlaggedProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      store: json['store']?.toString(),
      adminIssue: json['adminIssue']?.toString(),
      countryCode: json['countryCode']?.toString(),
    );
  }
}

class AdminPendingLocalReviewModel {
  final String id;
  final String? title;
  final String? storeId;
  final String? merchantId;
  final String? countryCode;
  final String? createdAt;

  const AdminPendingLocalReviewModel({
    required this.id,
    this.title,
    this.storeId,
    this.merchantId,
    this.countryCode,
    this.createdAt,
  });

  factory AdminPendingLocalReviewModel.fromJson(Map<String, dynamic> json) {
    return AdminPendingLocalReviewModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      storeId: json['storeId']?.toString(),
      merchantId: json['merchantId']?.toString(),
      countryCode: json['countryCode']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

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

  factory AdminSystemErrorModel.fromJson(Map<String, dynamic> json) {
    return AdminSystemErrorModel(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString(),
      message: json['message']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminDashboardModel {
  final bool live;
  final int totalUsers;
  final int totalClicks;
  final int totalOrders;
  final double revenue;
  final int totalProducts;
  final int totalReels;
  final int totalMarketplaceItems;
  final int openReports;
  final List<String> topSearches;
  final List<AdminTopProductModel> topProducts;
  final List<AdminConnectorStatusModel> connectors;
  final List<AdminAiQueryLogModel> recentAiQueries;
  final List<AdminScrapeFailureModel> failedScrapings;
  final List<AdminFlaggedProductModel> flaggedProducts;
  final List<AdminPendingLocalReviewModel> pendingLocalReviews;
  final List<AdminSystemErrorModel> systemErrors;

  const AdminDashboardModel({
    required this.live,
    required this.totalUsers,
    required this.totalClicks,
    required this.totalOrders,
    required this.revenue,
    required this.totalProducts,
    required this.totalReels,
    required this.totalMarketplaceItems,
    required this.openReports,
    required this.topSearches,
    required this.topProducts,
    required this.connectors,
    required this.recentAiQueries,
    required this.failedScrapings,
    required this.flaggedProducts,
    required this.pendingLocalReviews,
    required this.systemErrors,
  });

  factory AdminDashboardModel.empty() {
    return const AdminDashboardModel(
      live: false,
      totalUsers: 0,
      totalClicks: 0,
      totalOrders: 0,
      revenue: 0,
      totalProducts: 0,
      totalReels: 0,
      totalMarketplaceItems: 0,
      openReports: 0,
      topSearches: [],
      topProducts: [],
      connectors: [],
      recentAiQueries: [],
      failedScrapings: [],
      flaggedProducts: [],
      pendingLocalReviews: [],
      systemErrors: [],
    );
  }

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      live: json['live'] == true,
      totalUsers: _toInt(json['totalUsers']),
      totalClicks: _toInt(json['totalClicks']),
      totalOrders: _toInt(json['totalOrders']),
      revenue: _toDouble(json['revenue']),
      totalProducts: _toInt(json['totalProducts']),
      totalReels: _toInt(json['totalReels']),
      totalMarketplaceItems: _toInt(json['totalMarketplaceItems']),
      openReports: _toInt(json['openReports']),
      topSearches: _toStringList(json['topSearches']),
      topProducts: _toMapList(json['topProducts'])
          .map(AdminTopProductModel.fromJson)
          .toList(),
      connectors: _toMapList(json['connectors'])
          .map(AdminConnectorStatusModel.fromJson)
          .toList(),
      recentAiQueries: _toMapList(json['recentAiQueries'])
          .map(AdminAiQueryLogModel.fromJson)
          .toList(),
      failedScrapings: _toMapList(json['failedScrapings'])
          .map(AdminScrapeFailureModel.fromJson)
          .toList(),
      flaggedProducts: _toMapList(json['flaggedProducts'])
          .map(AdminFlaggedProductModel.fromJson)
          .toList(),
      pendingLocalReviews: _toMapList(json['pendingLocalReviews'])
          .map(AdminPendingLocalReviewModel.fromJson)
          .toList(),
      systemErrors: _toMapList(json['systemErrors'])
          .map(AdminSystemErrorModel.fromJson)
          .toList(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? 0;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}
