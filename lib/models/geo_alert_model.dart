class NearbyDealModel {
  final String id;
  final String productId;
  final String productTitle;
  final String store;
  final double price;
  final String currency;
  final int distanceMeters;
  final String message;

  const NearbyDealModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.store,
    required this.price,
    required this.currency,
    required this.distanceMeters,
    required this.message,
  });

  factory NearbyDealModel.fromJson(Map<String, dynamic> json) {
    return NearbyDealModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productTitle: json['product_title']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      price: _double(json['price']),
      currency: json['currency']?.toString() ?? 'EUR',
      distanceMeters: _int(json['distance_meters']),
      message: json['message']?.toString() ?? '',
    );
  }

  static int _int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _double(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
