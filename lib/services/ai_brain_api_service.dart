import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/global_deal_model.dart';

/// AI Deal Brain Pro client.
///
/// Migrated onto the unified [ApiService] transport so that the user's active
/// locale is injected automatically through the global network spine.
///
/// The `baseUrl` parameter is retained for source compatibility but ignored.
/// The host is always resolved by ApiConfig through ApiService.
class AiBrainApiException implements Exception {
  final String message;
  final int? statusCode;

  const AiBrainApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AiBrainApiException($statusCode): $message';
}

class AiBrainApiService {
  AiBrainApiService({
    @Deprecated('Ignored. Host is resolved from ApiConfig.') String? baseUrl,
    Duration timeout = const Duration(seconds: 45),
  }) : _timeout = timeout;

  final Duration _timeout;
  final ApiService _api = ApiService.instance;

  Future<ProductInput> extractUrl({
    required String url,
    required String userCountry,
    required String userCurrency,
    required String language,
  }) async {
    final json = await _postJson(ApiEndpoints.aiDealBrainExtractUrl, {
      'url': url,
      'userCountry': userCountry,
      'userCurrency': userCurrency,
      'language': language,
    });

    return ProductInput.fromJson(json);
  }

  Future<GlobalDealAnalysis> analyzeGlobal({
    required ProductInput product,
    required UserContext user,
  }) async {
    final json = await _postJson(ApiEndpoints.aiDealBrainAnalyzeGlobal, {
      'product': product.toJson(),
      'user': user.toJson(),
    });

    return GlobalDealAnalysis.fromJson(json);
  }

  Future<GlobalDealAnalysis> analyzeUrl({
    required String url,
    required String userCountry,
    required String userCurrency,
    required String language,
  }) async {
    final json = await _postJson(ApiEndpoints.aiDealBrainAnalyzeUrl, {
      'url': url,
      'userCountry': userCountry,
      'userCurrency': userCurrency,
      'language': language,
    });

    return GlobalDealAnalysis.fromJson(json);
  }

  Future<String> generateNegotiationScript({
    required ProductInput product,
    required GlobalDealAnalysis analysis,
  }) async {
    final json = await _postJson(ApiEndpoints.aiDealBrainNegotiate, {
      'productTitle': product.title,
      'store': product.store,
      'sellerLanguage': analysis.negotiation.sellerLanguage,
      'userLanguage': analysis.meta.userLanguage,
      'userCountry': analysis.meta.userCountry,
      'currentTotalCost': analysis.discountCurrencyCard.totalLandedCost
          .toJson(),
      'targetPrice': analysis.negotiation.targetPrice.toJson(),
      'reason': analysis.negotiation.reason,
    });

    return json['script']?.toString() ?? analysis.negotiation.script;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final decoded = await _api.post(path, body: body, timeout: _timeout);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } on TimeoutAppException {
      throw const AiBrainApiException(
        'The AI service took too long to respond. Try again.',
      );
    } on NetworkException catch (e) {
      throw AiBrainApiException(e.message, statusCode: e.statusCode);
    } on AppException catch (e) {
      throw AiBrainApiException(e.message);
    } catch (e) {
      throw AiBrainApiException('Network error: $e');
    }
  }
}
