import 'product.dart';

class HomeFacet {
  final String name;
  final int count;
  final String subtitle;

  const HomeFacet({
    required this.name,
    required this.count,
    required this.subtitle,
  });

  factory HomeFacet.fromMap(Map<String, dynamic> map) => HomeFacet(
    name: map['name']?.toString() ?? '',
    count: Product.toInt(map['count']),
    subtitle: map['subtitle']?.toString() ?? '',
  );
}

class HomeAiStatus {
  final int strongDeals;
  final int riskyDealsHidden;
  final int betterToWait;
  final int cheaperAlternativesFound;

  const HomeAiStatus({
    required this.strongDeals,
    required this.riskyDealsHidden,
    required this.betterToWait,
    required this.cheaperAlternativesFound,
  });

  factory HomeAiStatus.fromMap(Map<String, dynamic> map) => HomeAiStatus(
    strongDeals: Product.toInt(map['strongDeals']),
    riskyDealsHidden: Product.toInt(map['riskyDealsHidden']),
    betterToWait: Product.toInt(map['betterToWait']),
    cheaperAlternativesFound: Product.toInt(map['cheaperAlternativesFound']),
  );
}

class HomeFeed {
  final String country;
  final String currency;
  final HomeAiStatus aiStatus;
  final List<Product> heroDeals;
  final List<Product> hotDeals;
  final List<Product> globalOnline;
  final List<Product> topRated;
  final List<Product> bestSellers;
  final List<Product> under10;
  final List<Product> under25;
  final List<Product> recentlyAdded;
  final List<Product> surpriseDeals;
  final List<Product> recommended;
  // Discovery sections (Batch 14A)
  final List<Product> verifiedDeals;
  final List<Product> bestDiscountToday;
  final List<Product> freshArrivals;
  final List<Product> trendingNow;
  final List<Product> notSeenRecently;
  final List<Product> forYouToday;
  final String seedDay;
  final String variant;
  final List<HomeFacet> stores;
  final List<HomeFacet> categories;
  final List<Product> products;

  const HomeFeed({
    required this.country,
    required this.currency,
    required this.aiStatus,
    required this.heroDeals,
    required this.hotDeals,
    required this.globalOnline,
    required this.topRated,
    required this.bestSellers,
    required this.under10,
    required this.under25,
    required this.recentlyAdded,
    required this.surpriseDeals,
    required this.recommended,
    this.verifiedDeals = const [],
    this.bestDiscountToday = const [],
    this.freshArrivals = const [],
    this.trendingNow = const [],
    this.notSeenRecently = const [],
    this.forYouToday = const [],
    this.seedDay = '',
    this.variant = 'A',
    required this.stores,
    required this.categories,
    required this.products,
  });

  factory HomeFeed.empty() => const HomeFeed(
    country: 'es',
    currency: 'EUR',
    aiStatus: HomeAiStatus(
      strongDeals: 0,
      riskyDealsHidden: 0,
      betterToWait: 0,
      cheaperAlternativesFound: 0,
    ),
    heroDeals: [],
    hotDeals: [],
    globalOnline: [],
    topRated: [],
    bestSellers: [],
    under10: [],
    under25: [],
    recentlyAdded: [],
    surpriseDeals: [],
    recommended: [],
    stores: [],
    categories: [],
    products: [],
  );

  factory HomeFeed.fromMap(Map<String, dynamic> map) {
    final sections = map['sections'] is Map
        ? Map<String, dynamic>.from(map['sections'])
        : <String, dynamic>{};
    final sectionDedupe = _HomeFeedProductDedupe();

    List<Product> parseProducts(dynamic raw, {_HomeFeedProductDedupe? dedupe}) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where(_isVisibleHomeProduct)
          .where((e) => dedupe?.add(e) ?? true)
          .map((e) => Product.fromMap(e, e['id']?.toString() ?? ''))
          .toList();
    }

    List<HomeFacet> parseFacets(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => HomeFacet.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.name.isNotEmpty)
          .toList();
    }

    return HomeFeed(
      country: map['country']?.toString() ?? 'es',
      currency: map['currency']?.toString() ?? 'EUR',
      seedDay: map['seedDay']?.toString() ?? '',
      variant: map['variant']?.toString() ?? 'A',
      aiStatus: HomeAiStatus.fromMap(
        map['aiStatus'] is Map
            ? Map<String, dynamic>.from(map['aiStatus'])
            : const {},
      ),
      heroDeals: parseProducts(sections['heroDeals'], dedupe: sectionDedupe),
      hotDeals: parseProducts(sections['hotDeals'], dedupe: sectionDedupe),
      globalOnline: parseProducts(
        sections['globalOnline'],
        dedupe: sectionDedupe,
      ),
      topRated: parseProducts(sections['topRated'], dedupe: sectionDedupe),
      bestSellers: parseProducts(
        sections['bestSellers'],
        dedupe: sectionDedupe,
      ),
      under10: parseProducts(sections['under10'], dedupe: sectionDedupe),
      under25: parseProducts(sections['under25'], dedupe: sectionDedupe),
      recentlyAdded: parseProducts(
        sections['recentlyAdded'],
        dedupe: sectionDedupe,
      ),
      surpriseDeals: parseProducts(
        sections['surpriseDeals'],
        dedupe: sectionDedupe,
      ),
      recommended: parseProducts(
        sections['recommended'],
        dedupe: sectionDedupe,
      ),
      verifiedDeals: parseProducts(
        sections['verifiedDeals'],
        dedupe: sectionDedupe,
      ),
      bestDiscountToday: parseProducts(
        sections['bestDiscountToday'],
        dedupe: sectionDedupe,
      ),
      freshArrivals: parseProducts(
        sections['freshArrivals'],
        dedupe: sectionDedupe,
      ),
      trendingNow: parseProducts(
        sections['trendingNow'],
        dedupe: sectionDedupe,
      ),
      notSeenRecently: parseProducts(
        sections['notSeenRecently'],
        dedupe: sectionDedupe,
      ),
      forYouToday: parseProducts(
        sections['forYouToday'],
        dedupe: sectionDedupe,
      ),
      stores: parseFacets(map['stores']),
      categories: parseFacets(map['categories']),
      products: parseProducts(
        map['products'],
        dedupe: _HomeFeedProductDedupe(),
      ),
    );
  }
}

bool _isVisibleHomeProduct(Map<String, dynamic> map) {
  final status = (map['status'] ?? '').toString().trim().toLowerCase();
  if (const {
    'hidden',
    'removed',
    'rejected',
    'blocked',
    'quarantined',
  }.contains(status)) {
    return false;
  }
  if (map['visibleToUsers'] == false ||
      map['publicVisible'] == false ||
      map['active'] == false ||
      map['isActive'] == false ||
      map['isExpired'] == true) {
    return false;
  }
  final dhgateText = [
    map['store'],
    map['source'],
    map['programName'],
    map['programNames'],
    map['catalogSource'],
    map['importSource'],
    map['affiliateUrl'],
    map['productUrl'],
  ].join(' ').toLowerCase();
  return !dhgateText.contains('dhgate');
}

class _HomeFeedProductDedupe {
  final Set<String> _seen = <String>{};

  bool add(Map<String, dynamic> map) {
    final keys = _identityKeys(map);
    if (keys.any(_seen.contains)) return false;
    _seen.addAll(keys);
    return true;
  }

  List<String> _identityKeys(Map<String, dynamic> map) {
    final keys = <String>[];
    void addText(String prefix, dynamic value) {
      final text = value?.toString().trim().toLowerCase() ?? '';
      if (text.isNotEmpty) keys.add('$prefix:$text');
    }

    addText('id', map['id'] ?? map['productId'] ?? map['product_id']);
    addText(
      'url',
      _canonicalHomeUrl(
        map['affiliateUrl'] ??
            map['affiliate_url'] ??
            map['productUrl'] ??
            map['product_url'] ??
            map['originalUrl'] ??
            map['url'] ??
            map['link'],
      ),
    );
    addText(
      'sku',
      map['sku'] ??
          map['SKU'] ??
          map['itemSku'] ??
          map['itemSKU'] ??
          map['externalId'] ??
          map['offerId'],
    );
    addText('fp', map['fingerprint']);
    return keys.toSet().toList();
  }

  String _canonicalHomeUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return raw.toLowerCase();
    }
    final cleanQuery = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => key.toLowerCase().startsWith('utm_'));
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          query: cleanQuery.isEmpty
              ? ''
              : Uri(queryParameters: cleanQuery).query,
          fragment: '',
        )
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }
}

class ProductDetailAi {
  final Product product;
  final Map<String, dynamic> verdict;
  final Map<String, dynamic> dealDNA;
  final List<Product> similarProducts;
  final List<Product> sameStoreProducts;
  final List<Product> cheaperAlternatives;
  final List<Product> topRatedAlternatives;
  final List<Product> bundleBuilder;

  const ProductDetailAi({
    required this.product,
    required this.verdict,
    required this.dealDNA,
    required this.similarProducts,
    required this.sameStoreProducts,
    required this.cheaperAlternatives,
    required this.topRatedAlternatives,
    required this.bundleBuilder,
  });

  factory ProductDetailAi.fromMap(Map<String, dynamic> map, Product fallback) {
    final sections = map['sections'] is Map
        ? Map<String, dynamic>.from(map['sections'])
        : <String, dynamic>{};
    List<Product> parseProducts(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map(
            (e) => Product.fromMap(
              Map<String, dynamic>.from(e),
              e['id']?.toString() ?? '',
            ),
          )
          .toList();
    }

    return ProductDetailAi(
      product: map['product'] is Map
          ? Product.fromMap(
              Map<String, dynamic>.from(map['product']),
              map['product']['id']?.toString() ?? fallback.id,
            )
          : fallback,
      verdict: map['aiVerdict'] is Map
          ? Map<String, dynamic>.from(map['aiVerdict'])
          : const {},
      dealDNA: map['dealDNA'] is Map
          ? Map<String, dynamic>.from(map['dealDNA'])
          : const {},
      similarProducts: parseProducts(sections['similarProducts']),
      sameStoreProducts: parseProducts(sections['sameStoreProducts']),
      cheaperAlternatives: parseProducts(sections['cheaperAlternatives']),
      topRatedAlternatives: parseProducts(sections['topRatedAlternatives']),
      bundleBuilder: parseProducts(sections['bundleBuilder']),
    );
  }
}
