import 'environment.dart';

/// Central source of truth for all backend URLs.
///
/// WHY: the old code repeated the Render URL in many services/screens. That
/// makes production changes risky. Keep the Render fallback, but allow API_URL
/// from .env for staging/prod without touching source code. No other file may
/// hardcode a host; they must read [ApiConfig.baseUrl].
class ApiConfig {
  ApiConfig._();

  /// The default production host used when API_URL is not configured.
  /// Exposed so callers never need to repeat the literal string.
  static const String productionFallback = 'https://ofertix-api.onrender.com';

  static String get baseUrl {
    final configured = Environment.apiUrl.trim();
    final raw = configured.isEmpty ? productionFallback : configured;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Uri uri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    final cleanQuery = <String, String>{};
    queryParameters?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isNotEmpty) cleanQuery[key] = text;
    });

    return Uri.parse('$baseUrl$normalizedEndpoint').replace(
      queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
    );
  }
}
