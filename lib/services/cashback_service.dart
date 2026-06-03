class CashbackService {
  static double calculate({required double price, required double percent}) {
    if (price <= 0 || percent <= 0) return 0;
    return price * percent / 100;
  }
}
