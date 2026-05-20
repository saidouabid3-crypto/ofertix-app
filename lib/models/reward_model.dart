class RewardModel {
  final int coins;
  final String type;

  const RewardModel({required this.coins, required this.type});

  factory RewardModel.fromMap(Map<String, dynamic> map) {
    return RewardModel(coins: map['coins'] ?? 0, type: map['type'] ?? '');
  }
}
