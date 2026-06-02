import '../models/ai_brain_model.dart';
import '../models/ai_deal_brain_result.dart';
import 'ai_service.dart';
import 'settings_service.dart';

class AIBrainService {
  AIBrainService._();

  static final AIBrainService instance = AIBrainService._();

  final AiService _ai = AiService.instance;
  final SettingsService _settings = SettingsService.instance;

  Future<AIBrainResponseModel> analyzeDeal({
    required String query,
    String? productId,
    String? reelId,
    String? mysteryRewardId,
    String? title,
    double? currentPrice,
    double? oldPrice,
    String? store,
    String? category,
    String? specs,
  }) async {
    final country = await _settings.getCountry();
    final currency = await _settings.getCurrency();
    final language = await _settings.getLanguage();

    final result = await _ai.askBeforeBuying(
      input: query,
      countryCode: country,
      currency: currency,
      language: language,
      store: store,
      currentPrice: currentPrice,
      oldPrice: oldPrice,
      title: title,
      specs: specs,
    );

    return _toLegacyModel(result);
  }

  AIBrainResponseModel _toLegacyModel(AiDealBrainResult result) {
    return AIBrainResponseModel(
      id: result.createdAt,
      intent: result.mode,
      verdict: result.verdict,
      score: result.score,
      confidence: (result.confidence * 100).round().clamp(0, 100),
      summary: result.summary,
      suggestions: [
        result.priceAdvice.recommendation,
        result.antiImpulseAdvice.message,
      ].where((item) => item.trim().isNotEmpty).toList(),
      alternatives: result.alternatives,
      specsExplained: const [],
      reasons: result.reasons,
      riskLevel: result.dealDna.risk,
      fakeDiscountRisk: result.dealDna.discount,
      priceSignal: result.dealDna.price,
      bestAction: result.priceAdvice.shouldWait
          ? 'watch_price'
          : result.verdict,
      savingsEstimate: result.priceAdvice.youSave ?? 0,
      fairPriceEstimate: result.priceAdvice.estimatedFairPrice,
      modelUsed: '${result.provider}/${result.model}',
    );
  }
}
