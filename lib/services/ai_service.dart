import '../core/config/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/ai_deal_brain_result.dart';
import '../models/product.dart';
import 'api_service.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  final ApiService _api = ApiService.instance;

  Future<AiShoppingResult> analyzeShoppingQuery({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    double? latitude,
    double? longitude,
    List<Map<String, String>> history = const [],
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return AiShoppingResult.empty();
    }

    try {
      final response = await _api.post(
        ApiEndpoints.aiSearch,
        body: {
          'query': cleanQuery,
          'countryCode': countryCode,
          'currency': currency,
          'language': language,
          'latitude': latitude,
          'longitude': longitude,
          'history': history,
        },
      );

      if (response is Map) {
        return AiShoppingResult.fromMap(
          Map<String, dynamic>.from(response),
          fallbackQuery: cleanQuery,
        );
      }

      throw const AppException(
        'ai.error.notConfigured',
        code: 'AI_NOT_CONFIGURED',
      );
    } on PaymentRequiredException {
      rethrow;
    } on NetworkException catch (e) {
      if (e.message == 'AI_NOT_CONFIGURED') {
        throw const AppException(
          'ai.error.notConfigured',
          code: 'AI_NOT_CONFIGURED',
        );
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'ai.error.notConfigured',
        code: 'AI_NOT_CONFIGURED',
        cause: e,
      );
    }
  }

  /// Reactive NDJSON stream: emits partial answer tokens then final payload.
  Stream<AiStreamEvent> analyzeShoppingQueryStream({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    double? latitude,
    double? longitude,
    List<Map<String, String>> history = const [],
  }) async* {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      yield AiStreamEvent.done(AiShoppingResult.empty());
      return;
    }

    try {
      await for (final chunk in _api.postNdjsonStream(
        ApiEndpoints.aiSearchStream,
        body: {
          'query': cleanQuery,
          'countryCode': countryCode,
          'currency': currency,
          'language': language,
          'latitude': latitude,
          'longitude': longitude,
          'history': history,
        },
      )) {
        final type = chunk['type']?.toString() ?? '';
        if (type == 'token') {
          yield AiStreamEvent.token(chunk['answer']?.toString() ?? '');
        } else if (type == 'done') {
          final payload = chunk['payload'];
          if (payload is Map) {
            yield AiStreamEvent.done(
              AiShoppingResult.fromMap(
                Map<String, dynamic>.from(payload),
                fallbackQuery: cleanQuery,
              ),
            );
          }
        } else if (type == 'error') {
          yield AiStreamEvent.error(
            chunk['message']?.toString() ?? 'AI failed',
          );
        }
      }
    } on PaymentRequiredException {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    double? latitude,
    double? longitude,
  }) async {
    final result = await analyzeShoppingQuery(
      query: query,
      countryCode: countryCode,
      currency: currency,
      language: language,
      latitude: latitude,
      longitude: longitude,
    );

    return result.products;
  }

  Future<List<Product>> recommendations({
    required String query,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.aiRecommendations,
        body: {
          'query': query.trim(),
          'countryCode': countryCode,
          'currency': currency,
          'language': language,
        },
      );

      return _parseProducts(response);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeProduct({
    required Product product,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.aiAnalyzeProduct,
        body: {
          'productId': product.id,
          'name': product.name,
          'category': product.category,
          'store': product.store,
          'price': product.newPrice,
          'oldPrice': product.oldPrice,
          'discount': product.discount,
          'countryCode': countryCode,
          'currency': currency,
          'language': language,
        },
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  Future<AiDealBrainResult> chat({
    required String message,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    List<Map<String, String>> history = const [],
  }) async {
    return _postDealBrain(ApiEndpoints.aiChat, {
      'message': message.trim(),
      'country': countryCode,
      'currency': currency,
      'language': language,
      'history': history,
    });
  }

  Future<AiDealBrainResult> analyzeProductDealBrain({
    required Product product,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
  }) async {
    return _postDealBrain(ApiEndpoints.aiAnalyzeProduct, {
      'country': countryCode,
      'currency': currency,
      'language': language,
      'product': product.toMap(),
    });
  }

  Future<AiDealBrainResult> askBeforeBuying({
    required String input,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    String? store,
    double? currentPrice,
    double? oldPrice,
    String? title,
    String? specs,
  }) async {
    return _postDealBrain(ApiEndpoints.aiAskBeforeBuying, {
      'input': input.trim(),
      'country': countryCode,
      'currency': currency,
      'language': language,
      'store': store,
      'currentPrice': currentPrice,
      'oldPrice': oldPrice,
      'title': title,
      'specs': specs,
    });
  }

  Future<AiDealBrainResult> dailyHunt({
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
    List<String> interests = const [],
    double? budget,
  }) async {
    return _postDealBrain(ApiEndpoints.aiDailyHunt, {
      'country': countryCode,
      'currency': currency,
      'language': language,
      'interests': interests,
      'budget': budget,
    });
  }

  Future<AiDealBrainResult> cardVerdict({
    required Product product,
    String countryCode = 'global',
    String currency = 'EUR',
    String language = 'auto',
  }) async {
    return _postDealBrain(ApiEndpoints.aiCardVerdict, {
      'country': countryCode,
      'currency': currency,
      'language': language,
      'product': product.toMap(),
    });
  }

  Future<AiDealBrainResult> _postDealBrain(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _api.post(
        endpoint,
        body: body,
        timeout: const Duration(seconds: 45),
      );
      if (response is Map<String, dynamic>) {
        return AiDealBrainResult.fromMap(response);
      }
      if (response is Map) {
        return AiDealBrainResult.fromMap(Map<String, dynamic>.from(response));
      }
      throw const AppException(
        'ai.error.notConfigured',
        code: 'AI_NOT_CONFIGURED',
      );
    } on PaymentRequiredException {
      rethrow;
    } on NetworkException catch (e) {
      if (e.message == 'AI_NOT_CONFIGURED') {
        throw const AppException(
          'ai.error.notConfigured',
          code: 'AI_NOT_CONFIGURED',
        );
      }
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'ai.error.notConfigured',
        code: 'AI_NOT_CONFIGURED',
        cause: e,
      );
    }
  }

  List<Product> _parseProducts(dynamic response) {
    if (response is List) {
      return response.map<Product>((item) {
        final map = Map<String, dynamic>.from(item);

        return Product.fromMap(map, map['id']?.toString() ?? '');
      }).toList();
    }

    if (response is Map && response['products'] is List) {
      final items = List<Map<String, dynamic>>.from(response['products']);

      return items.map<Product>((item) {
        return Product.fromMap(item, item['id']?.toString() ?? '');
      }).toList();
    }

    return [];
  }
}

class AiStreamEvent {
  final String? token;
  final AiShoppingResult? result;
  final String? error;

  const AiStreamEvent._({this.token, this.result, this.error});

  factory AiStreamEvent.token(String value) => AiStreamEvent._(token: value);

  factory AiStreamEvent.done(AiShoppingResult value) =>
      AiStreamEvent._(result: value);

  factory AiStreamEvent.error(String value) => AiStreamEvent._(error: value);

  bool get isToken => token != null;
  bool get isDone => result != null;
  bool get isError => error != null;
}

class AiShoppingResult {
  final String answer;
  final String searchQuery;
  final List<String> productQueries;
  final String intent;
  final bool onlineOnly;
  final bool localOnly;
  final bool nearby;
  final double? maxPrice;
  final String? category;
  final String sortBy;
  final List<String> suggestions;
  final List<String> buyingTips;
  final bool needsProducts;
  final List<Product> products;

  const AiShoppingResult({
    required this.answer,
    required this.searchQuery,
    required this.productQueries,
    required this.intent,
    required this.onlineOnly,
    required this.localOnly,
    required this.nearby,
    required this.maxPrice,
    required this.category,
    required this.sortBy,
    required this.suggestions,
    required this.buyingTips,
    required this.needsProducts,
    required this.products,
  });

  factory AiShoppingResult.empty() {
    return const AiShoppingResult(
      answer: '',
      searchQuery: '',
      productQueries: [],
      intent: 'empty',
      onlineOnly: false,
      localOnly: false,
      nearby: false,
      maxPrice: null,
      category: null,
      sortBy: 'best',
      suggestions: [],
      buyingTips: [],
      needsProducts: false,
      products: [],
    );
  }

  factory AiShoppingResult.basic(String query) {
    return AiShoppingResult(
      answer: '',
      searchQuery: query,
      productQueries: [query],
      intent: 'search',
      onlineOnly: false,
      localOnly: false,
      nearby: false,
      maxPrice: null,
      category: null,
      sortBy: 'best',
      suggestions: const [],
      buyingTips: const [],
      needsProducts: true,
      products: const [],
    );
  }

  factory AiShoppingResult.fromMap(
    Map<String, dynamic> map, {
    required String fallbackQuery,
  }) {
    final rawSearchQuery = _string(map['searchQuery']);
    final searchQuery = rawSearchQuery.isNotEmpty
        ? rawSearchQuery
        : fallbackQuery;

    final rawProductQueries = _stringList(map['productQueries']);
    final productQueries = rawProductQueries.isNotEmpty
        ? _unique(rawProductQueries)
        : _unique([searchQuery]);

    final intent = _string(map['intent']).isNotEmpty
        ? _string(map['intent'])
        : 'search';

    final needsProducts =
        map['needsProducts'] == true || productQueries.isNotEmpty;

    return AiShoppingResult(
      answer: _string(map['answer']),
      searchQuery: searchQuery,
      productQueries: productQueries,
      intent: intent,
      onlineOnly: map['onlineOnly'] == true,
      localOnly: map['localOnly'] == true,
      nearby: map['nearby'] == true,
      maxPrice: _toDoubleOrNull(map['maxPrice']),
      category: _nullableString(map['category']),
      sortBy: _string(map['sortBy']).isNotEmpty
          ? _string(map['sortBy'])
          : 'best',
      suggestions: _stringList(map['suggestions']),
      buyingTips: _stringList(map['buyingTips']),
      needsProducts: needsProducts,
      products: _productsFromMap(map),
    );
  }

  static String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty && item != 'null')
        .toList();
  }

  static List<String> _unique(List<String> values) {
    final result = <String>[];

    for (final value in values) {
      final clean = value.trim();

      if (clean.isEmpty) continue;

      if (!result.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        result.add(clean);
      }
    }

    return result;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }

  static List<Product> _productsFromMap(Map<String, dynamic> map) {
    final value = map['products'];

    if (value is! List) return [];

    final products = <Product>[];

    for (final item in value) {
      if (item is! Map) continue;

      final productMap = Map<String, dynamic>.from(item);

      products.add(
        Product.fromMap(productMap, productMap['id']?.toString() ?? ''),
      );
    }

    return products;
  }
}
