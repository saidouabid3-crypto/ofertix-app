import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../models/ai_deal_brain_result.dart';
import '../../models/product.dart';
import '../../services/ai_service.dart';
import '../../services/product_service.dart';
import '../../services/settings_service.dart';

enum AIMessageRole { user, assistant }

class AIChatMessage {
  final AIMessageRole role;
  final String text;
  final List<String> suggestions;
  final List<String> buyingTips;
  final List<Product> products;
  final bool expectedProducts;

  const AIChatMessage({
    required this.role,
    required this.text,
    this.suggestions = const [],
    this.buyingTips = const [],
    this.products = const [],
    this.expectedProducts = false,
  });

  bool get isUser => role == AIMessageRole.user;
}

class AIAssistantProvider extends ChangeNotifier {
  final AiService _aiService = AiService.instance;
  final ProductService _productService = ProductService.instance;
  final SettingsService _settings = SettingsService.instance;

  static const int _maxMessages = 30;

  bool isLoading = false;
  String? error;

  String answer = '';
  String lastQuery = '';
  String detectedSearchQuery = '';
  String intent = 'chat';
  String sortBy = 'best';
  bool needsProducts = false;

  List<String> suggestions = [];
  List<String> buyingTips = [];
  List<Product> results = [];

  final List<AIChatMessage> messages = [];

  bool get hasMessages => messages.isNotEmpty;

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || isLoading) return;

    final history = _historyForBackend();

    isLoading = true;
    error = null;
    answer = '';
    lastQuery = cleanQuery;
    detectedSearchQuery = cleanQuery;
    intent = 'chat';
    sortBy = 'best';
    needsProducts = false;
    suggestions = [];
    buyingTips = [];
    results = [];

    messages.add(AIChatMessage(role: AIMessageRole.user, text: cleanQuery));
    _trimMessages();
    notifyListeners();

    try {
      final countryCode = await _settings.getCountry();
      final currency = await _settings.getCurrency();
      final language = await _settings.getLanguage();

      final ai = await _aiService.chat(
        message: cleanQuery,
        countryCode: countryCode,
        currency: currency,
        language: language,
        history: history,
      );

      answer = _answerFrom(ai);
      intent = ai.mode;
      needsProducts = _looksLikeProductIntent(cleanQuery);
      suggestions = _cleanList(ai.alternatives, limit: 6);
      buyingTips = _cleanList([
        ai.priceAdvice.recommendation,
        ai.antiImpulseAdvice.message,
        ...ai.risks,
      ], limit: 5);

      if (needsProducts) {
        results = await _searchProducts(
          queries: [cleanQuery, ...ai.alternatives],
          countryCode: countryCode,
        );
      }

      messages.add(
        AIChatMessage(
          role: AIMessageRole.assistant,
          text: answer,
          suggestions: suggestions,
          buyingTips: buyingTips,
          products: results,
          expectedProducts: needsProducts,
        ),
      );
    } on PaymentRequiredException catch (e) {
      isLoading = false;
      error = e.message;
      _trimMessages();
      notifyListeners();
      rethrow;
    } on AppException catch (e) {
      error = e.code == 'AI_NOT_CONFIGURED'
          ? 'ai.error.notConfigured'
          : 'ai.error.unavailable';
      messages.add(AIChatMessage(role: AIMessageRole.assistant, text: error!));
    } catch (_) {
      error = 'ai.error.unavailable';
      messages.add(
        const AIChatMessage(
          role: AIMessageRole.assistant,
          text: 'ai.error.unavailable',
        ),
      );
    }

    _trimMessages();
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectSuggestion(String suggestion) async => search(suggestion);

  List<Map<String, String>> _historyForBackend() {
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;
    return recentMessages
        .where((message) => message.text.trim().isNotEmpty)
        .map((message) {
          return {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text.trim(),
          };
        })
        .toList();
  }

  Future<List<Product>> _searchProducts({
    required List<String> queries,
    required String countryCode,
  }) async {
    for (final query in _uniqueQueries(queries)) {
      try {
        final products = await _productService.searchProducts(
          query,
          countryCode: countryCode,
        );
        if (products.isNotEmpty) return products.take(12).toList();
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  String _answerFrom(AiDealBrainResult result) {
    final parts = [
      result.summary,
      result.brutalTruth,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    return parts.isEmpty ? 'ai.error.unavailable' : parts.join('\n\n');
  }

  bool _looksLikeProductIntent(String query) {
    final q = query.toLowerCase();
    return q.contains('buy') ||
        q.contains('deal') ||
        q.contains('offer') ||
        q.contains('price') ||
        q.contains('compare') ||
        q.contains('product') ||
        q.contains('compr') ||
        q.contains('oferta') ||
        q.contains('precio') ||
        q.contains('acheter') ||
        q.contains('prix') ||
        q.contains('شراء') ||
        q.contains('ثمن');
  }

  List<String> _uniqueQueries(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isEmpty) continue;
      if (!result.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        result.add(clean);
      }
    }
    return result.take(8).toList();
  }

  List<String> _cleanList(List<String> values, {required int limit}) {
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isEmpty) continue;
      if (!result.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        result.add(clean);
      }
    }
    return result.take(limit).toList();
  }

  void _trimMessages() {
    if (messages.length <= _maxMessages) return;
    final latest = messages.sublist(messages.length - _maxMessages);
    messages
      ..clear()
      ..addAll(latest);
  }

  void clear() {
    isLoading = false;
    error = null;
    answer = '';
    lastQuery = '';
    detectedSearchQuery = '';
    intent = 'chat';
    sortBy = 'best';
    needsProducts = false;
    suggestions = [];
    buyingTips = [];
    results = [];
    messages.clear();
    notifyListeners();
  }
}
