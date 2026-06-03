import '../../repositories/rewards_repository.dart';

class RewardsFeatureRepository {
  final RewardsRepository _repository = RewardsRepository();

  Future<void> addCoins(int coins) {
    return _repository.addCoins(coins);
  }
}
