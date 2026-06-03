class Money {
  final double amount;
  final String currency;
  const Money({required this.amount, required this.currency});
  factory Money.fromJson(dynamic json, {String fallbackCurrency = 'EUR'}) {
    if (json is! Map<String, dynamic>)
      return Money(amount: 0, currency: fallbackCurrency);
    return Money(
      amount: _toDouble(json['amount']),
      currency:
          (json['currency']?.toString().trim().toUpperCase().isNotEmpty ??
              false)
          ? json['currency'].toString().trim().toUpperCase()
          : fallbackCurrency,
    );
  }
  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};
  String format() =>
      '${amount.toStringAsFixed(amount >= 100 ? 0 : 2)} $currency';
}

class ProductInput {
  final String title, store, storeCountry, sellerLanguage, baseCurrency, specs;
  final double currentPrice;
  final double? oldPrice, shippingPrice, rating;
  final int? estimatedDeliveryDays, reviewCount;
  final String? imageUrl, productUrl;
  const ProductInput({
    required this.title,
    required this.store,
    required this.storeCountry,
    required this.sellerLanguage,
    required this.currentPrice,
    required this.oldPrice,
    required this.baseCurrency,
    required this.shippingPrice,
    required this.estimatedDeliveryDays,
    required this.specs,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.productUrl,
  });
  factory ProductInput.empty() => const ProductInput(
    title: '',
    store: 'Unknown',
    storeCountry: 'US',
    sellerLanguage: 'en',
    currentPrice: 0,
    oldPrice: null,
    baseCurrency: 'EUR',
    shippingPrice: null,
    estimatedDeliveryDays: null,
    specs: '',
    rating: null,
    reviewCount: null,
    imageUrl: null,
    productUrl: null,
  );
  factory ProductInput.fromJson(Map<String, dynamic> j) => ProductInput(
    title: j['title']?.toString() ?? '',
    store: j['store']?.toString() ?? 'Unknown',
    storeCountry: j['storeCountry']?.toString() ?? 'US',
    sellerLanguage: j['sellerLanguage']?.toString() ?? 'en',
    currentPrice: _toDouble(j['currentPrice']),
    oldPrice: j['oldPrice'] == null ? null : _toDouble(j['oldPrice']),
    baseCurrency: j['baseCurrency']?.toString() ?? 'EUR',
    shippingPrice: j['shippingPrice'] == null
        ? null
        : _toDouble(j['shippingPrice']),
    estimatedDeliveryDays: j['estimatedDeliveryDays'] == null
        ? null
        : _toInt(j['estimatedDeliveryDays']),
    specs: j['specs']?.toString() ?? '',
    rating: j['rating'] == null ? null : _toDouble(j['rating']),
    reviewCount: j['reviewCount'] == null ? null : _toInt(j['reviewCount']),
    imageUrl: j['imageUrl']?.toString(),
    productUrl: j['productUrl']?.toString(),
  );
  Map<String, dynamic> toJson() => {
    'title': title,
    'store': store,
    'storeCountry': storeCountry,
    'sellerLanguage': sellerLanguage,
    'currentPrice': currentPrice,
    'oldPrice': oldPrice,
    'baseCurrency': baseCurrency,
    'shippingPrice': shippingPrice,
    'estimatedDeliveryDays': estimatedDeliveryDays,
    'specs': specs,
    'rating': rating,
    'reviewCount': reviewCount,
    'imageUrl': imageUrl,
    'productUrl': productUrl,
  };
}

class UserContext {
  final String country, currency, language;
  const UserContext({
    required this.country,
    required this.currency,
    required this.language,
  });
  Map<String, dynamic> toJson() => {
    'country': country,
    'currency': currency,
    'language': language,
  };
}

class GlobalDealAnalysis {
  final MetaCard meta;
  final VerdictCardData verdictCard;
  final DiscountCurrencyCardData discountCurrencyCard;
  final HumanSpecsCardData humanSpecsCard;
  final GlobalAlternativeCardData globalAlternativeCard;
  final NegotiationData negotiation;
  const GlobalDealAnalysis({
    required this.meta,
    required this.verdictCard,
    required this.discountCurrencyCard,
    required this.humanSpecsCard,
    required this.globalAlternativeCard,
    required this.negotiation,
  });
  factory GlobalDealAnalysis.fromJson(Map<String, dynamic> j) {
    final meta = MetaCard.fromJson(_map(j['meta']));
    return GlobalDealAnalysis(
      meta: meta,
      verdictCard: VerdictCardData.fromJson(_map(j['verdictCard'])),
      discountCurrencyCard: DiscountCurrencyCardData.fromJson(
        _map(j['discountCurrencyCard']),
        fallbackCurrency: meta.userCurrency,
      ),
      humanSpecsCard: HumanSpecsCardData.fromJson(_map(j['humanSpecsCard'])),
      globalAlternativeCard: GlobalAlternativeCardData.fromJson(
        _map(j['globalAlternativeCard']),
        fallbackCurrency: meta.userCurrency,
      ),
      negotiation: NegotiationData.fromJson(
        _map(j['negotiation']),
        fallbackCurrency: meta.userCurrency,
      ),
    );
  }
}

class MetaCard {
  final String userLanguage,
      userCountry,
      userCurrency,
      store,
      storeCountry,
      sellerLanguage;
  final int confidence;
  const MetaCard({
    required this.userLanguage,
    required this.userCountry,
    required this.userCurrency,
    required this.store,
    required this.storeCountry,
    required this.sellerLanguage,
    required this.confidence,
  });
  factory MetaCard.fromJson(Map<String, dynamic> j) => MetaCard(
    userLanguage: j['userLanguage']?.toString() ?? 'es',
    userCountry: j['userCountry']?.toString() ?? 'ES',
    userCurrency: j['userCurrency']?.toString() ?? 'EUR',
    store: j['store']?.toString() ?? 'Unknown',
    storeCountry: j['storeCountry']?.toString() ?? 'US',
    sellerLanguage: j['sellerLanguage']?.toString() ?? 'en',
    confidence: _toInt(j['confidence']).clamp(0, 100),
  );
}

class VerdictCardData {
  final String command, title, oneLine, riskLevel, color, explanation;
  final int score;
  const VerdictCardData({
    required this.command,
    required this.title,
    required this.oneLine,
    required this.score,
    required this.riskLevel,
    required this.color,
    required this.explanation,
  });
  factory VerdictCardData.fromJson(Map<String, dynamic> j) => VerdictCardData(
    command: j['command']?.toString() ?? 'VERIFY_FIRST',
    title: j['title']?.toString() ?? 'Verify first',
    oneLine: j['oneLine']?.toString() ?? '',
    score: _toInt(j['score']).clamp(0, 100),
    riskLevel: j['riskLevel']?.toString() ?? 'MEDIUM',
    color: j['color']?.toString() ?? 'YELLOW',
    explanation: j['explanation']?.toString() ?? '',
  );
}

class DiscountCurrencyCardData {
  final int advertisedDiscountPercent,
      realisticDiscountPercent,
      fakeDiscountRisk,
      estimatedTaxesConfidence;
  final Money storePrice,
      convertedProductPrice,
      estimatedShipping,
      estimatedTaxes,
      totalLandedCost,
      realSaving;
  final String explanation;
  const DiscountCurrencyCardData({
    required this.advertisedDiscountPercent,
    required this.realisticDiscountPercent,
    required this.fakeDiscountRisk,
    required this.storePrice,
    required this.convertedProductPrice,
    required this.estimatedShipping,
    required this.estimatedTaxes,
    required this.estimatedTaxesConfidence,
    required this.totalLandedCost,
    required this.realSaving,
    required this.explanation,
  });
  factory DiscountCurrencyCardData.fromJson(
    Map<String, dynamic> j, {
    required String fallbackCurrency,
  }) => DiscountCurrencyCardData(
    advertisedDiscountPercent: _toInt(
      j['advertisedDiscountPercent'],
    ).clamp(0, 100),
    realisticDiscountPercent: _toInt(
      j['realisticDiscountPercent'],
    ).clamp(0, 100),
    fakeDiscountRisk: _toInt(j['fakeDiscountRisk']).clamp(0, 100),
    storePrice: Money.fromJson(
      j['storePrice'],
      fallbackCurrency: fallbackCurrency,
    ),
    convertedProductPrice: Money.fromJson(
      j['convertedProductPrice'],
      fallbackCurrency: fallbackCurrency,
    ),
    estimatedShipping: Money.fromJson(
      j['estimatedShipping'],
      fallbackCurrency: fallbackCurrency,
    ),
    estimatedTaxes: Money.fromJson(
      j['estimatedTaxes'],
      fallbackCurrency: fallbackCurrency,
    ),
    estimatedTaxesConfidence: _toInt(
      j['estimatedTaxesConfidence'],
    ).clamp(0, 100),
    totalLandedCost: Money.fromJson(
      j['totalLandedCost'],
      fallbackCurrency: fallbackCurrency,
    ),
    realSaving: Money.fromJson(
      j['realSaving'],
      fallbackCurrency: fallbackCurrency,
    ),
    explanation: j['explanation']?.toString() ?? '',
  );
}

class HumanSpecsCardData {
  final String summary;
  final List<HumanSpecItem> items;
  const HumanSpecsCardData({required this.summary, required this.items});
  factory HumanSpecsCardData.fromJson(Map<String, dynamic> j) =>
      HumanSpecsCardData(
        summary: j['summary']?.toString() ?? '',
        items: j['items'] is List
            ? (j['items'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => HumanSpecItem.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
            : const [],
      );
}

class HumanSpecItem {
  final String spec, humanMeaning, importance;
  const HumanSpecItem({
    required this.spec,
    required this.humanMeaning,
    required this.importance,
  });
  factory HumanSpecItem.fromJson(Map<String, dynamic> j) => HumanSpecItem(
    spec: j['spec']?.toString() ?? '',
    humanMeaning: j['humanMeaning']?.toString() ?? '',
    importance: j['importance']?.toString() ?? 'MEDIUM',
  );
}

class GlobalAlternativeCardData {
  final String title, store, whyBetter, shippingAdvantage, url;
  final Money estimatedTotalCost;
  final int confidence;
  const GlobalAlternativeCardData({
    required this.title,
    required this.store,
    required this.estimatedTotalCost,
    required this.whyBetter,
    required this.shippingAdvantage,
    required this.url,
    required this.confidence,
  });
  factory GlobalAlternativeCardData.fromJson(
    Map<String, dynamic> j, {
    required String fallbackCurrency,
  }) => GlobalAlternativeCardData(
    title: j['title']?.toString() ?? '',
    store: j['store']?.toString() ?? '',
    estimatedTotalCost: Money.fromJson(
      j['estimatedTotalCost'],
      fallbackCurrency: fallbackCurrency,
    ),
    whyBetter: j['whyBetter']?.toString() ?? '',
    shippingAdvantage: j['shippingAdvantage']?.toString() ?? '',
    url: j['url']?.toString() ?? '',
    confidence: _toInt(j['confidence']).clamp(0, 100),
  );
}

class NegotiationData {
  final bool shouldShowButton;
  final Money targetPrice;
  final String sellerLanguage, reason, script;
  const NegotiationData({
    required this.shouldShowButton,
    required this.targetPrice,
    required this.sellerLanguage,
    required this.reason,
    required this.script,
  });
  factory NegotiationData.fromJson(
    Map<String, dynamic> j, {
    required String fallbackCurrency,
  }) => NegotiationData(
    shouldShowButton: j['shouldShowButton'] == true,
    targetPrice: Money.fromJson(
      j['targetPrice'],
      fallbackCurrency: fallbackCurrency,
    ),
    sellerLanguage: j['sellerLanguage']?.toString() ?? 'en',
    reason: j['reason']?.toString() ?? '',
    script: j['script']?.toString() ?? '',
  );
}

Map<String, dynamic> _map(dynamic v) => v is Map<String, dynamic>
    ? v
    : v is Map
    ? Map<String, dynamic>.from(v)
    : <String, dynamic>{};
double _toDouble(dynamic v) => v is num
    ? v.toDouble()
    : v is String
    ? double.tryParse(v.replaceAll(',', '.')) ?? 0
    : 0;
int _toInt(dynamic v) => v is num
    ? v.round()
    : v is String
    ? double.tryParse(v)?.round() ?? 0
    : 0;
