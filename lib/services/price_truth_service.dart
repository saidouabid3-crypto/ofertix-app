import '../models/price_history_model.dart';
import '../models/price_truth_result.dart';
import '../models/product.dart';
import 'price_history_service.dart';

class PriceTruthService {
  PriceTruthService._();

  static final PriceTruthService instance = PriceTruthService._();

  /// Fetches price history from Firestore and runs the analysis.
  Future<PriceTruthResult> analyze(Product product) async {
    final history = await PriceHistoryService.instance.getHistory(product.id);
    return analyzeWithHistory(product, history);
  }

  /// Pure function — computes truth from product fields + optional history.
  PriceTruthResult analyzeWithHistory(
    Product product,
    List<PriceHistoryModel> history,
  ) {
    // Drop any points with invalid prices before analysis.
    final validHistory = history.where((h) => h.price > 0).toList();

    final current = product.newPrice;
    final old = product.oldPrice;
    final currency = product.currency;
    final hasDiscount = product.hasRealDiscount && product.discount > 0;
    final discountPct =
        (hasDiscount && old > 0) ? ((old - current) / old) * 100 : null;
    final fakeRisk = product.fakeDiscountRisk.toLowerCase().trim();

    if (current <= 0) {
      return PriceTruthResult(
        status: PriceTruthStatus.unknown,
        confidence: 0,
        currentPrice: current,
        oldPrice: old,
        currency: currency,
        dataQuality: DataQuality.low,
        historyPoints: validHistory.length,
      );
    }

    // ── With sufficient history ──────────────────────────────────────────────
    if (validHistory.length >= 3) {
      final prices = validHistory.map((h) => h.price).toList();
      final lowest = prices.reduce((a, b) => a < b ? a : b);
      final average = prices.reduce((a, b) => a + b) / prices.length;
      final quality =
          validHistory.length >= 10 ? DataQuality.high : DataQuality.medium;

      if (hasDiscount) {
        // Current price is at or near all-time low — real deal.
        if (current <= lowest * 1.05) {
          return PriceTruthResult(
            status: PriceTruthStatus.realDeal,
            confidence: (validHistory.length >= 10 ? 90 : 78).clamp(0, 100),
            currentPrice: current,
            oldPrice: old,
            bestPrice: lowest,
            averagePrice: average,
            discountPercent: discountPct,
            dataQuality: quality,
            historyPoints: validHistory.length,
            currency: currency,
          );
        }
        // At least 10 % below historical average — real saving.
        if (current <= average * 0.90) {
          return PriceTruthResult(
            status: PriceTruthStatus.realDeal,
            confidence: 68,
            currentPrice: current,
            oldPrice: old,
            bestPrice: lowest,
            averagePrice: average,
            discountPercent: discountPct,
            dataQuality: quality,
            historyPoints: validHistory.length,
            currency: currency,
          );
        }
        // "Old price" is within 15 % of the average — the discount is cosmetic.
        if (old > 0 && old <= average * 1.15) {
          return PriceTruthResult(
            status: PriceTruthStatus.suspicious,
            confidence: 62,
            currentPrice: current,
            oldPrice: old,
            bestPrice: lowest,
            averagePrice: average,
            discountPercent: discountPct,
            suspiciousReasons: const ['nearAverage'],
            dataQuality: quality,
            historyPoints: validHistory.length,
            currency: currency,
          );
        }
      }

      // No meaningful discount or none of the suspicious conditions met.
      return PriceTruthResult(
        status: PriceTruthStatus.normal,
        confidence: 55,
        currentPrice: current,
        oldPrice: old,
        bestPrice: lowest,
        averagePrice: average,
        discountPercent: discountPct,
        dataQuality: quality,
        historyPoints: validHistory.length,
        currency: currency,
      );
    }

    // ── No history — heuristic fallback ─────────────────────────────────────
    // Backend FakeDiscountService already classified extreme discounts (≥ 80 %)
    // as "high" risk. Use that signal when history is absent.
    if (fakeRisk == 'high' && hasDiscount) {
      return PriceTruthResult(
        status: PriceTruthStatus.suspicious,
        confidence: 40,
        currentPrice: current,
        oldPrice: old,
        discountPercent: discountPct,
        suspiciousReasons: const ['oldPriceInflated'],
        dataQuality: DataQuality.low,
        historyPoints: validHistory.length,
        currency: currency,
      );
    }

    if (!hasDiscount) {
      return PriceTruthResult(
        status: PriceTruthStatus.normal,
        confidence: 30,
        currentPrice: current,
        oldPrice: old,
        dataQuality: DataQuality.low,
        historyPoints: validHistory.length,
        currency: currency,
      );
    }

    return PriceTruthResult(
      status: PriceTruthStatus.noHistory,
      confidence: validHistory.isEmpty ? 10 : 20,
      currentPrice: current,
      oldPrice: old,
      discountPercent: discountPct,
      suspiciousReasons: const ['noHistory'],
      dataQuality: DataQuality.low,
      historyPoints: validHistory.length,
      currency: currency,
    );
  }
}
