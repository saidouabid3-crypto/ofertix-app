class StoreModel {
  final String id;
  final String name;
  final String logo;
  final String website;
  final bool featured;

  const StoreModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.website,
    required this.featured,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      logo: map['logo'] ?? '',
      website: map['website'] ?? '',
      featured: map['featured'] ?? false,
    );
  }
}
