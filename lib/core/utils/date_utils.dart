class AppDateUtils {
  static String todayIso() {
    return DateTime.now().toIso8601String();
  }

  static bool isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }
}
