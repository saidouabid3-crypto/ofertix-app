class CashbackModel {
  final String store;
  final double percent;

  const CashbackModel({required this.store, required this.percent});

  factory CashbackModel.fromMap(Map<String, dynamic> map) {
    return CashbackModel(
      store: map['store'] ?? '',
      percent: (map['percent'] ?? 0).toDouble(),
    );
  }
}
