class CacheService {
  static final Map<String, dynamic> _cache = {};

  static void set(String key, dynamic value) {
    _cache[key] = value;
  }

  static T? get<T>(String key) {
    final value = _cache[key];
    if (value is T) return value;
    return null;
  }

  static void remove(String key) {
    _cache.remove(key);
  }

  static void clear() {
    _cache.clear();
  }
}
