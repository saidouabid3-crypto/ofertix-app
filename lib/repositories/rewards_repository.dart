import '../services/rewards_service.dart';

class RewardsRepository {
  Future<int> getCoins() {
    return RewardsService.getCoins();
  }

  Future<void> addCoins(int coins) {
    return RewardsService.addCoins(coins);
  }
}
