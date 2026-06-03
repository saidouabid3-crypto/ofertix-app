class CountryUtils {
  static String normalize(String code) {
    return code.trim().toUpperCase();
  }

  static String normalizeForDb(String code) {
    return code.trim().toLowerCase();
  }

  static bool isGlobal(String country) {
    return country.toLowerCase() == 'global';
  }
}
