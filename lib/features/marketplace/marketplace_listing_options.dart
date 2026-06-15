import '../../core/constants/app_countries.dart';

class MarketplaceListingOptions {
  MarketplaceListingOptions._();

  static const categories = [
    'electronics',
    'fashion',
    'home',
    'sports',
    'beauty',
    'toys',
    'books',
    'automotive',
    'other',
  ];

  static const conditions = ['new', 'like_new', 'good', 'fair', 'poor'];
  static const deliveryMethods = ['pickup', 'shipping', 'both'];

  static const popularCities = <String, List<String>>{
    'ES': [
      'Madrid',
      'Barcelona',
      'Valencia',
      'Seville',
      'Zaragoza',
      'Malaga',
      'Murcia',
      'Palma',
      'Bilbao',
      'Alicante',
    ],
    'FR': [
      'Paris',
      'Marseille',
      'Lyon',
      'Toulouse',
      'Nice',
      'Nantes',
      'Montpellier',
      'Strasbourg',
      'Bordeaux',
      'Lille',
    ],
    'MA': [
      'Casablanca',
      'Rabat',
      'Marrakesh',
      'Fes',
      'Tangier',
      'Agadir',
      'Meknes',
      'Oujda',
      'Kenitra',
      'Tetouan',
    ],
    'PT': [
      'Lisbon',
      'Porto',
      'Braga',
      'Coimbra',
      'Funchal',
      'Aveiro',
      'Faro',
      'Setubal',
    ],
    'IT': [
      'Rome',
      'Milan',
      'Naples',
      'Turin',
      'Palermo',
      'Genoa',
      'Bologna',
      'Florence',
      'Bari',
      'Catania',
    ],
    'DE': [
      'Berlin',
      'Hamburg',
      'Munich',
      'Cologne',
      'Frankfurt',
      'Stuttgart',
      'Dusseldorf',
      'Leipzig',
      'Dortmund',
      'Essen',
    ],
    'OTHER': [],
  };

  static const _marketplaceCountryCodes = {
    'ES',
    'FR',
    'MA',
    'PT',
    'IT',
    'DE',
    'OTHER',
  };

  static List<Map<String, String>> get countries => AppCountries.supported
      .where((country) => _marketplaceCountryCodes.contains(country['code']))
      .toList(growable: false);

  static String currencyFor(String countryCode) =>
      AppCountries.currencyFor(countryCode);
}
