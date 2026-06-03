/// Canonical 18-category taxonomy (Ofertix Elite).
class EliteCategories {
  EliteCategories._();

  static const List<String> all = [
    'fashion',
    'electronics',
    'phones',
    'computers',
    'home',
    'beauty',
    'sports',
    'kids',
    'gaming',
    'food',
    'supermarket',
    'pharmacy',
    'travel',
    'tools',
    'pets',
    'automotive',
    'jewelry',
    'general',
  ];

  static bool isValid(String id) => all.contains(id.toLowerCase());

  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'general';
    final key = raw.toLowerCase().trim();
    if (all.contains(key)) return key;
    return 'general';
  }
}
