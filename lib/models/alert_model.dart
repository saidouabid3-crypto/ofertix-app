class AlertModel {
  final String id;
  final String productId;
  final double targetPrice;

  const AlertModel({
    required this.id,
    required this.productId,
    required this.targetPrice,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      productId: map['productId'] ?? '',
      targetPrice: (map['targetPrice'] ?? 0).toDouble(),
    );
  }
}
