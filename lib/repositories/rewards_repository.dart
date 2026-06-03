import '../services/rewards_service.dart';

class RewardsRepository {
  Future<void> addCoins(int coins) {
    return RewardsService.addCoins(coins);
  }
}
