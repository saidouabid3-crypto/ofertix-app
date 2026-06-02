import '../models/market_profile.dart';

class MarketService {
  MarketService._();

  static final MarketService instance = MarketService._();

  static const List<MarketProfile> markets = [
    MarketProfile(
      code: 'es',
      name: 'Spain',
      nativeName: 'España',
      flag: '🇪🇸',
      currency: 'EUR',
      defaultLanguage: 'es',
      languages: ['es', 'en', 'ar', 'fr'],
      stores: [
        'Amazon ES',
        'Miravia',
        'Carrefour ES',
        'MediaMarkt',
        'El Corte Inglés',
        'PCComponentes',
      ],
      status: 'active',
    ),
    MarketProfile(
      code: 'ma',
      name: 'Morocco',
      nativeName: 'المغرب',
      flag: '🇲🇦',
      currency: 'MAD',
      defaultLanguage: 'ar',
      languages: ['ar', 'fr', 'es', 'en'],
      stores: [
        'Jumia MA',
        'Avito',
        'Marjane',
        'Electroplanet',
      ],
      status: 'active',
    ),
    MarketProfile(
      code: 'dz',
      name: 'Algeria',
      nativeName: 'الجزائر',
      flag: '🇩🇿',
      currency: 'DZD',
      defaultLanguage: 'ar',
      languages: ['ar', 'fr', 'en'],
      stores: [
        'Ouedkniss',
        'Jumia-like local',
        'Local stores',
      ],
      status: 'active',
    ),
    MarketProfile(
      code: 'fr',
      name: 'France',
      nativeName: 'France',
      flag: '🇫🇷',
      currency: 'EUR',
      defaultLanguage: 'fr',
      languages: ['fr', 'en', 'ar'],
      stores: ['Amazon FR', 'Cdiscount', 'Fnac', 'Carrefour FR', 'Darty'],
      status: 'active',
    ),
    MarketProfile(
      code: 'pt',
      name: 'Portugal',
      nativeName: 'Portugal',
      flag: '🇵🇹',
      currency: 'EUR',
      defaultLanguage: 'pt',
      languages: ['pt', 'en', 'es'],
      stores: ['Amazon ES shipsTo PT', 'Worten', 'Continente', 'Fnac PT'],
      status: 'active',
    ),
    MarketProfile(
      code: 'it',
      name: 'Italy',
      nativeName: 'Italia',
      flag: '🇮🇹',
      currency: 'EUR',
      defaultLanguage: 'it',
      languages: ['it', 'en'],
      stores: ['Amazon IT', 'MediaWorld', 'eBay IT', 'Unieuro'],
      status: 'active',
    ),
    MarketProfile(
      code: 'de',
      name: 'Germany',
      nativeName: 'Deutschland',
      flag: '🇩🇪',
      currency: 'EUR',
      defaultLanguage: 'de',
      languages: ['de', 'en'],
      stores: ['Amazon DE', 'MediaMarkt DE', 'Saturn', 'Otto'],
      status: 'active',
    ),
    MarketProfile(
      code: 'uk',
      name: 'United Kingdom',
      nativeName: 'United Kingdom',
      flag: '🇬🇧',
      currency: 'GBP',
      defaultLanguage: 'en',
      languages: ['en'],
      stores: ['Amazon UK', 'Argos', 'Currys', 'eBay UK'],
      status: 'active',
    ),
    MarketProfile(
      code: 'us',
      name: 'United States',
      nativeName: 'United States',
      flag: '🇺🇸',
      currency: 'USD',
      defaultLanguage: 'en',
      languages: ['en', 'es'],
      stores: ['Amazon US', 'Walmart', 'Best Buy', 'Target', 'eBay US'],
      status: 'active',
    ),
    MarketProfile(
      code: 'ca',
      name: 'Canada',
      nativeName: 'Canada',
      flag: '🇨🇦',
      currency: 'CAD',
      defaultLanguage: 'en',
      languages: ['en', 'fr'],
      stores: [
        'Amazon CA',
        'Walmart CA',
        'Best Buy CA',
        'Canadian Tire',
        'eBay CA',
      ],
      status: 'active',
    ),
    MarketProfile(
      code: 'eg',
      name: 'Egypt',
      nativeName: 'مصر',
      flag: '🇪🇬',
      currency: 'EGP',
      defaultLanguage: 'ar',
      languages: ['ar', 'en'],
      stores: ['Amazon EG', 'Jumia EG', 'Noon EG', 'B.TECH'],
      status: 'active',
    ),
    MarketProfile(
      code: 'sa',
      name: 'Saudi Arabia',
      nativeName: 'السعودية',
      flag: '🇸🇦',
      currency: 'SAR',
      defaultLanguage: 'ar',
      languages: ['ar', 'en'],
      stores: ['Amazon SA', 'Noon SA', 'Jarir', 'Extra'],
      status: 'active',
    ),
    MarketProfile(
      code: 'ae',
      name: 'United Arab Emirates',
      nativeName: 'الإمارات',
      flag: '🇦🇪',
      currency: 'AED',
      defaultLanguage: 'ar',
      languages: ['ar', 'en'],
      stores: ['Amazon AE', 'Noon AE', 'Sharaf DG', 'Carrefour AE'],
      status: 'active',
    ),
    MarketProfile(
      code: 'mx',
      name: 'Mexico',
      nativeName: 'México',
      flag: '🇲🇽',
      currency: 'MXN',
      defaultLanguage: 'es',
      languages: ['es', 'en'],
      stores: ['Amazon MX', 'Mercado Libre MX', 'Walmart MX', 'Coppel'],
      status: 'active',
    ),
  ];

  String normalize(String code) {
    final c = code.trim().toLowerCase().replaceAll('_', '-');
    switch (c) {
      case 'gb':
        return 'uk';
      case 'usa':
      case 'united-states':
        return 'us';
      case 'canada':
        return 'ca';
      case 'spain':
      case 'españa':
      case 'espana':
        return 'es';
      case 'morocco':
      case 'maroc':
        return 'ma';
      case 'algeria':
      case 'algérie':
        return 'dz';
      default:
        return c.isEmpty ? 'es' : c;
    }
  }

  bool isSupported(String code) =>
      markets.any((m) => m.code == normalize(code));

  MarketProfile market(String code) {
    final normalized = normalize(code);
    return markets.firstWhere(
      (m) => m.code == normalized,
      orElse: () => markets.first,
    );
  }

  String currency(String code) => market(code).currency;
  String defaultLanguage(String code) => market(code).defaultLanguage;
  String flag(String code) => market(code).flag;
  String name(String code) => market(code).name;
}
