class AdminUserViewModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String photoUrl;
  final String role;
  final bool isAdmin;
  final bool isVerified;
  final bool sellerVerified;
  final bool isBanned;
  final int reportsCount;
  final int reelsCount;
  final int sellItemsCount;
  final int followersCount;
  final String? createdAt;

  const AdminUserViewModel({
    required this.uid,
    this.email = '',
    this.displayName = '',
    this.username = '',
    this.photoUrl = '',
    this.role = 'user',
    this.isAdmin = false,
    this.isVerified = false,
    this.sellerVerified = false,
    this.isBanned = false,
    this.reportsCount = 0,
    this.reelsCount = 0,
    this.sellItemsCount = 0,
    this.followersCount = 0,
    this.createdAt,
  });

  factory AdminUserViewModel.fromJson(Map<String, dynamic> j) {
    return AdminUserViewModel(
      uid: j['uid']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      displayName: j['displayName']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      photoUrl: j['photoUrl']?.toString() ?? '',
      role: j['role']?.toString() ?? 'user',
      isAdmin: j['isAdmin'] == true,
      isVerified: j['isVerified'] == true,
      sellerVerified: j['sellerVerified'] == true,
      isBanned: j['isBanned'] == true,
      reportsCount: _i(j['reportsCount']),
      reelsCount: _i(j['reelsCount']),
      sellItemsCount: _i(j['sellItemsCount']),
      followersCount: _i(j['followersCount']),
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

class AdminUserListModel {
  final List<AdminUserViewModel> users;
  final int total;

  const AdminUserListModel({this.users = const [], this.total = 0});

  factory AdminUserListModel.fromJson(Map<String, dynamic> j) {
    final raw = j['users'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AdminUserViewModel.fromJson).toList()
        : <AdminUserViewModel>[];
    return AdminUserListModel(
      users: list,
      total: j['total'] is int ? j['total'] as int : list.length,
    );
  }
}
