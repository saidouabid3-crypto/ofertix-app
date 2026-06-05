class AdminModerationItemModel {
  final String id;
  final String? title;
  final String? description;
  final String status;
  final String? creatorId;
  final String? creatorName;
  final String? creatorUsername;
  final String? creatorAvatarUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? imageUrl;
  final double? price;
  final String? currency;
  final String? store;
  final String? category;
  final int reportsCount;
  final String? createdAt;
  final String itemType;

  const AdminModerationItemModel({
    required this.id,
    this.title,
    this.description,
    this.status = 'approved',
    this.creatorId,
    this.creatorName,
    this.creatorUsername,
    this.creatorAvatarUrl,
    this.thumbnailUrl,
    this.videoUrl,
    this.imageUrl,
    this.price,
    this.currency,
    this.store,
    this.category,
    this.reportsCount = 0,
    this.createdAt,
    this.itemType = 'reel',
  });

  factory AdminModerationItemModel.fromJson(Map<String, dynamic> j) {
    return AdminModerationItemModel(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString(),
      description: j['description']?.toString(),
      status: j['status']?.toString() ?? 'approved',
      creatorId: j['creatorId']?.toString(),
      creatorName: j['creatorName']?.toString(),
      creatorUsername: j['creatorUsername']?.toString(),
      creatorAvatarUrl: j['creatorAvatarUrl']?.toString(),
      thumbnailUrl: j['thumbnailUrl']?.toString(),
      videoUrl: j['videoUrl']?.toString(),
      imageUrl: j['imageUrl']?.toString(),
      price: _d(j['price']),
      currency: j['currency']?.toString(),
      store: j['store']?.toString(),
      category: j['category']?.toString(),
      reportsCount: _i(j['reportsCount']),
      createdAt: j['createdAt']?.toString(),
      itemType: j['itemType']?.toString() ?? 'reel',
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AdminModerationListModel {
  final List<AdminModerationItemModel> items;
  final int total;

  const AdminModerationListModel({this.items = const [], this.total = 0});

  factory AdminModerationListModel.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'];
    final list = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(AdminModerationItemModel.fromJson)
            .toList()
        : <AdminModerationItemModel>[];
    return AdminModerationListModel(
      items: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
