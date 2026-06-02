import '../core/errors/app_exception.dart';
import '../models/ai_deal_brain_result.dart';
import '../models/product.dart';
import 'ai_service.dart';
import 'settings_service.dart';

/// In-memory cache for card-level AI verdicts (POST /api/ai/card-verdict).
///
/// Design rules:
///  - Hard session limit of [_sessionLimit] total fetches — never floods the feed.
///  - Max [_maxConcurrent] simultaneous in-flight requests.
///  - Once AI_NOT_CONFIGURED is returned the cache disables itself for the
///    session so no further requests are attempted.
///  - Failed products are recorded and never retried within the session.
///  - No fake results are ever inserted. The cache only stores real backend data.
class CardVerdictCache {
  CardVerdictCache._();

  static final CardVerdictCache instance = CardVerdictCache._();

  /// Hard cap on total card-verdict requests per app session.
  static const int _sessionLimit = 10;

  /// Max concurrent in-flight requests (backpressure guard).
  static const int _maxConcurrent = 3;

  final Map<String, AiDealBrainResult> _results = {};
  final Set<String> _failed = {};
  final Set<String> _inFlight = {};

  bool _disabled = false;
  int _sessionCount = 0;

  /// True after AI_NOT_CONFIGURED is received — no further requests this session.
  bool get isDisabled => _disabled;

  /// Returns a cached result if available, otherwise null.
  AiDealBrainResult? cached(String productId) => _results[productId];

  bool _canFetch(String productId) {
    if (_disabled) return false;
    if (_results.containsKey(productId)) return false;
    if (_failed.contains(productId)) return false;
    if (_inFlight.contains(productId)) return false;
    if (_inFlight.length >= _maxConcurrent) return false;
    if (_sessionCount >= _sessionLimit) return false;
    return true;
  }

  static bool _isEligible(Product product) {
    return product.id.isNotEmpty &&
        product.name.trim().isNotEmpty &&
        product.newPrice > 0;
  }

  /// Returns a cached result immediately if available; otherwise fetches from
  /// the backend respecting all rate limits. Returns null on any error.
  Future<AiDealBrainResult?> getOrFetch(Product product) async {
    // Return immediately if already cached.
    final existing = _results[product.id];
    if (existing != null) return existing;

    // Skip products that don't have enough data for a meaningful verdict.
    if (!_isEligible(product)) return null;

    // Respect all rate-limit rules.
    if (!_canFetch(product.id)) return null;

    _inFlight.add(product.id);
    _sessionCount++;
    try {
      final country = await SettingsService.instance.getCountry();
      final currency = await SettingsService.instance.getCurrency();
      final language = await SettingsService.instance.getLanguage();

      final result = await AiService.instance.cardVerdict(
        product: product,
        countryCode: country,
        currency: currency,
        language: language,
      );
      _results[product.id] = result;
      return result;
    } on PaymentRequiredException {
      _failed.add(product.id);
      return null;
    } on AppException catch (e) {
      if (e.code == 'AI_NOT_CONFIGURED') {
        // Disable all future fetches silently for this session.
        _disabled = true;
      }
      _failed.add(product.id);
      return null;
    } catch (_) {
      _failed.add(product.id);
      return null;
    } finally {
      _inFlight.remove(product.id);
    }
  }
}
