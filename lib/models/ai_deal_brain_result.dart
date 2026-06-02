class AiDealBrainResult {
  final bool success;
  final String mode;
  final String verdict;
  final int score;
  final String summary;
  final String brutalTruth;
  final DealDna dealDna;
  final List<String> reasons;
  final List<String> risks;
  final PriceAdvice priceAdvice;
  final BudgetAdvice budgetAdvice;
  final AntiImpulseAdvice antiImpulseAdvice;
  final List<String> alternatives;
  final List<Map<String, dynamic>> dailyHunt;
  final double confidence;
  final String language;
  final String country;
  final String currency;
  final String provider;
  final String model;
  final String createdAt;

  const AiDealBrainResult({
    required this.success,
    required this.mode,
    required this.verdict,
    required this.score,
    required this.summary,
    required this.brutalTruth,
    required this.dealDna,
    required this.reasons,
    required this.risks,
    required this.priceAdvice,
    required this.budgetAdvice,
    required this.antiImpulseAdvice,
    required this.alternatives,
    required this.dailyHunt,
    required this.confidence,
    required this.language,
    required this.country,
    required this.currency,
    required this.provider,
    required this.model,
    required this.createdAt,
  });

  factory AiDealBrainResult.fromMap(Map<String, dynamic> map) {
    return AiDealBrainResult(
      success: map['success'] == true,
      mode: _string(map['mode']),
      verdict: _string(map['verdict'], fallback: 'watch_price'),
      score: _int(map['score']),
      summary: _string(map['summary']),
      brutalTruth: _string(map['brutalTruth']),
      dealDna: DealDna.fromMap(_map(map['dealDNA'])),
      reasons: _list(map['reasons']),
      risks: _list(map['risks']),
      priceAdvice: PriceAdvice.fromMap(_map(map['priceAdvice'])),
      budgetAdvice: BudgetAdvice.fromMap(_map(map['budgetAdvice'])),
      antiImpulseAdvice: AntiImpulseAdvice.fromMap(
        _map(map['antiImpulseAdvice']),
      ),
      alternatives: _list(map['alternatives']),
      dailyHunt: _mapList(map['dailyHunt']),
      confidence: _double(map['confidence']),
      language: _string(map['language']),
      country: _string(map['country']),
      currency: _string(map['currency']),
      provider: _string(map['provider']),
      model: _string(map['model']),
      createdAt: _string(map['createdAt']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 100);
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DealDna {
  final String price;
  final String trust;
  final String discount;
  final String risk;
  final String value;

  const DealDna({
    required this.price,
    required this.trust,
    required this.discount,
    required this.risk,
    required this.value,
  });

  factory DealDna.fromMap(Map<String, dynamic> map) {
    return DealDna(
      price: map['price']?.toString() ?? 'unknown',
      trust: map['trust']?.toString() ?? 'unknown',
      discount: map['discount']?.toString() ?? 'unknown',
      risk: map['risk']?.toString() ?? 'medium',
      value: map['value']?.toString() ?? 'average',
    );
  }
}

class PriceAdvice {
  final bool isGoodPrice;
  final double? estimatedFairPrice;
  final double? youSave;
  final bool shouldWait;
  final String recommendation;

  const PriceAdvice({
    required this.isGoodPrice,
    required this.estimatedFairPrice,
    required this.youSave,
    required this.shouldWait,
    required this.recommendation,
  });

  factory PriceAdvice.fromMap(Map<String, dynamic> map) {
    return PriceAdvice(
      isGoodPrice: map['isGoodPrice'] == true,
      estimatedFairPrice: _nullableDouble(map['estimatedFairPrice']),
      youSave: _nullableDouble(map['youSave']),
      shouldWait: map['shouldWait'] == true,
      recommendation: map['recommendation']?.toString() ?? '',
    );
  }
}

class BudgetAdvice {
  final bool? safeForBudget;
  final String message;

  const BudgetAdvice({required this.safeForBudget, required this.message});

  factory BudgetAdvice.fromMap(Map<String, dynamic> map) {
    final safe = map['safeForBudget'];
    return BudgetAdvice(
      safeForBudget: safe is bool ? safe : null,
      message: map['message']?.toString() ?? '',
    );
  }
}

class AntiImpulseAdvice {
  final bool isImpulseRisk;
  final bool cooldownSuggested;
  final String message;

  const AntiImpulseAdvice({
    required this.isImpulseRisk,
    required this.cooldownSuggested,
    required this.message,
  });

  factory AntiImpulseAdvice.fromMap(Map<String, dynamic> map) {
    return AntiImpulseAdvice(
      isImpulseRisk: map['isImpulseRisk'] == true,
      cooldownSuggested: map['cooldownSuggested'] == true,
      message: map['message']?.toString() ?? '',
    );
  }
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
