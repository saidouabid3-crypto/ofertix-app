class MarketProfile {
  const MarketProfile({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.currency,
    required this.defaultLanguage,
    required this.languages,
    required this.stores,
    required this.status,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String currency;
  final String defaultLanguage;
  final List<String> languages;
  final List<String> stores;
  final String status;

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'nativeName': nativeName,
    'flag': flag,
    'currency': currency,
    'defaultLanguage': defaultLanguage,
    'languages': languages,
    'stores': stores,
    'status': status,
  };
}
