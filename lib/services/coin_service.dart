import 'package:shared_preferences/shared_preferences.dart';

class CoinService {
  static int _coins = 0;

  static bool _loaded = false;

  static Future<void> loadCoins() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    _coins = prefs.getInt('coins') ?? 120;

    _loaded = true;
  }

  static int getCoins() {
    return _coins;
  }

  static Future<void> addCoins(int amount) async {
    await loadCoins();

    _coins += amount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
  }

  static Future<void> removeCoins(int amount) async {
    await loadCoins();

    _coins -= amount;

    if (_coins < 0) {
      _coins = 0;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
  }

  static Future<void> resetCoins() async {
    _coins = 120;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
  }
}
