class AdminProductQualityItemModel {
  final String id;
  final String? name;
  final String? store;
  final double? price;
  final String? imageUrl;
  final String? affiliateUrl;
  final String? status;
  final String? issue;
  final String? countryCode;

  const AdminProductQualityItemModel({
    required this.id,
    this.name,
    this.store,
    this.price,
    this.imageUrl,
    this.affiliateUrl,
    this.status,
    this.issue,
    this.countryCode,
  });

  factory AdminProductQualityItemModel.fromJson(Map<String, dynamic> j) {
    return AdminProductQualityItemModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString(),
      store: j['store']?.toString(),
      price: _d(j['price']),
      imageUrl: j['imageUrl']?.toString(),
      affiliateUrl: j['affiliateUrl']?.toString(),
      status: j['status']?.toString(),
      issue: j['issue']?.toString(),
      countryCode: j['countryCode']?.toString(),
    );
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AdminProductQualityListModel {
  final List<AdminProductQualityItemModel> items;
  final int total;

  const AdminProductQualityListModel({this.items = const [], this.total = 0});

  factory AdminProductQualityListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    final list = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(AdminProductQualityItemModel.fromJson)
            .toList()
        : <AdminProductQualityItemModel>[];
    return AdminProductQualityListModel(
      items: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
