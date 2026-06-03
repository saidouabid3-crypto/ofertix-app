enum PriceTruthStatus { realDeal, suspicious, normal, noHistory, unknown }

enum DataQuality { high, medium, low }

class PriceTruthResult {
  final PriceTruthStatus status;
  final int confidence;
  final double currentPrice;
  final double oldPrice;
  final double? bestPrice;
  final double? averagePrice;
  final double? discountPercent;
  final List<String> suspiciousReasons;
  final DataQuality dataQuality;
  final int historyPoints;
  final String currency;

  const PriceTruthResult({
    required this.status,
    required this.confidence,
    required this.currentPrice,
    required this.oldPrice,
    this.bestPrice,
    this.averagePrice,
    this.discountPercent,
    this.suspiciousReasons = const [],
    required this.dataQuality,
    required this.historyPoints,
    required this.currency,
  });
}
