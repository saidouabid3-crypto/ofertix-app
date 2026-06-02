class AIBrainResponseModel {
  final String id;
  final String intent;
  final String verdict;
  final int score;
  final int confidence;
  final String summary;
  final List<String> suggestions;
  final List<String> alternatives;
  final List<String> specsExplained;
  final List<String> reasons;
  final String riskLevel;
  final String fakeDiscountRisk;
  final String priceSignal;
  final String bestAction;
  final double savingsEstimate;
  final double? fairPriceEstimate;
  final String modelUsed;

  const AIBrainResponseModel({
    required this.id,
    required this.intent,
    required this.verdict,
    required this.score,
    required this.confidence,
    required this.summary,
    required this.suggestions,
    required this.alternatives,
    required this.specsExplained,
    required this.reasons,
    required this.riskLevel,
    required this.fakeDiscountRisk,
    required this.priceSignal,
    required this.bestAction,
    required this.savingsEstimate,
    required this.fairPriceEstimate,
    required this.modelUsed,
  });

  factory AIBrainResponseModel.fromJson(Map<String, dynamic> json) {
    return AIBrainResponseModel(
      id: json['id']?.toString() ?? '',
      intent: json['intent']?.toString() ?? 'shopping_advice',
      verdict: json['verdict']?.toString() ?? 'compare',
      score: _int(json['score'], fallback: 50),
      confidence: _int(json['confidence'], fallback: 70),
      summary: json['summary']?.toString() ?? '',
      suggestions: _list(json['suggestions']),
      alternatives: _list(json['alternatives']),
      specsExplained: _list(json['specs_explained'] ?? json['specsExplained']),
      reasons: _list(json['reasons']),
      riskLevel: json['risk_level']?.toString() ?? 'low',
      fakeDiscountRisk: json['fake_discount_risk']?.toString() ?? 'unknown',
      priceSignal: json['price_signal']?.toString() ?? 'unknown',
      bestAction: json['best_action']?.toString() ?? 'compare',
      savingsEstimate: _double(json['savings_estimate']),
      fairPriceEstimate: json['fair_price_estimate'] == null
          ? null
          : _double(json['fair_price_estimate']),
      modelUsed: json['model_used']?.toString() ?? 'rules_plus_ai_optional',
    );
  }

  static List<String> _list(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _double(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
