class DealVerdictReason {
  final String type;
  final String code;
  final String message;

  const DealVerdictReason({
    required this.type,
    required this.code,
    required this.message,
  });

  factory DealVerdictReason.fromMap(Map<String, dynamic> map) {
    return DealVerdictReason(
      type: map['type']?.toString() ?? 'warning',
      code: map['code']?.toString() ?? 'unknown',
      message: map['message']?.toString() ?? '',
    );
  }
}

class DealVerdict {
  final String verdict;
  final int confidence;
  final String riskLevel;
  final int discountRiskScore;
  final String discountRiskLabel;
  final String summary;
  final List<DealVerdictReason> reasons;
  final List<String> warnings;
  final List<String> actionHints;
  final Map<String, dynamic> signals;

  const DealVerdict({
    required this.verdict,
    required this.confidence,
    required this.riskLevel,
    required this.discountRiskScore,
    required this.discountRiskLabel,
    required this.summary,
    required this.reasons,
    required this.warnings,
    required this.actionHints,
    required this.signals,
  });

  factory DealVerdict.fromMap(Map<String, dynamic> map) {
    int number(dynamic value) {
      if (value is num) return value.round().clamp(0, 100).toInt();
      return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 100).toInt();
    }

    List<String> strings(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final rawReasons = map['reasons'];
    return DealVerdict(
      verdict: map['verdict']?.toString() ?? 'check_store',
      confidence: number(map['confidence']),
      riskLevel: map['riskLevel']?.toString() ?? 'medium',
      discountRiskScore: number(map['discountRiskScore']),
      discountRiskLabel: map['discountRiskLabel']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      reasons: rawReasons is List
          ? rawReasons.whereType<Map>().map((reason) {
              return DealVerdictReason.fromMap(
                Map<String, dynamic>.from(reason),
              );
            }).toList()
          : const [],
      warnings: strings(map['warnings']),
      actionHints: strings(map['actionHints']),
      signals: map['signals'] is Map
          ? Map<String, dynamic>.from(map['signals'] as Map)
          : const {},
    );
  }
}
