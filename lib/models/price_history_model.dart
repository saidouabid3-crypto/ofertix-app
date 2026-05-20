class PriceHistoryModel {
  final double price;
  final DateTime date;

  const PriceHistoryModel({required this.price, required this.date});

  factory PriceHistoryModel.fromMap(Map<String, dynamic> map) {
    return PriceHistoryModel(
      price: (map['price'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}
