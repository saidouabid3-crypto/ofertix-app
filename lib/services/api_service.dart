import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_response.dart';
import '../core/network/locale_resolver.dart';

/// Single HTTP transport for Ofertix Elite — locale headers, envelope parsing,
/// typed errors, AI streaming, and payment-required (402) handling.
class ApiService {
  ApiService._({http.Client? client}) : _client = client ?? http.Client();

  static final ApiService instance = ApiService._();

  factory ApiService.withClient(http.Client client) =>
      ApiService._(client: client);

  final http.Client _client;

  static const Duration defaultTimeout = Duration(seconds: 20);

  String? _token;

  void setToken(String? token) =>
      _token = (token?.trim().isEmpty ?? true) ? null : token!.trim();

  void clearToken() => _token = null;

  Map<String, String> _headers({
    bool authorized = false,
    Map<String, String>? extraHeaders,
    bool jsonBody = true,
  }) {
    final headers = <String, String>{
      ...LocaleResolver.instance.headers,
      HttpHeaders.acceptHeader: 'application/json',
      if (jsonBody) HttpHeaders.contentTypeHeader: 'application/json',
      if (authorized && _token != null)
        HttpHeaders.authorizationHeader: 'Bearer $_token',
    };

    if (extraHeaders != null) headers.addAll(extraHeaders);
    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () => _client.get(
        ApiConfig.uri(endpoint, queryParameters),
        headers: _headers(
          authorized: authorized,
          extraHeaders: extraHeaders,
          jsonBody: false,
        ),
      ),
      timeout: timeout,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () => _client.post(
        ApiConfig.uri(endpoint, queryParameters),
        headers: _headers(authorized: authorized, extraHeaders: extraHeaders),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      timeout: timeout,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () => _client.put(
        ApiConfig.uri(endpoint, queryParameters),
        headers: _headers(authorized: authorized, extraHeaders: extraHeaders),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      timeout: timeout,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () => _client.patch(
        ApiConfig.uri(endpoint, queryParameters),
        headers: _headers(authorized: authorized, extraHeaders: extraHeaders),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
      timeout: timeout,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () => _client.delete(
        ApiConfig.uri(endpoint, queryParameters),
        headers: _headers(authorized: authorized, extraHeaders: extraHeaders),
        body: body == null ? null : jsonEncode(body),
      ),
      timeout: timeout,
    );
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    bool authorized = false,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    return _send(
      () async {
        final request = http.MultipartRequest(
          'POST',
          ApiConfig.uri(endpoint),
        );

        request.headers.addAll(
          _headers(
            authorized: authorized,
            extraHeaders: extraHeaders,
            jsonBody: false,
          ),
        );

        request.fields.addAll(fields);
        request.files.addAll(files);

        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      timeout: timeout ?? const Duration(seconds: 120),
    );
  }

  /// NDJSON AI stream (`application/x-ndjson`). Each line is a JSON object.
  Stream<Map<String, dynamic>> postNdjsonStream(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) async* {
    final request = http.Request(
      'POST',
      ApiConfig.uri(endpoint),
    );
    request.headers.addAll(
      _headers(authorized: authorized, extraHeaders: extraHeaders),
    );
    request.body = jsonEncode(body ?? const <String, dynamic>{});

    final streamed = await _client
        .send(request)
        .timeout(timeout ?? const Duration(seconds: 60));

    if (streamed.statusCode == 402) {
      throw _paymentRequiredFromStream(streamed);
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final bodyText = await streamed.stream.bytesToString();
      throw NetworkException(
        'AI stream failed (${streamed.statusCode})',
        statusCode: streamed.statusCode,
        code: 'http_${streamed.statusCode}',
        cause: bodyText,
      );
    }

    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          yield Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        continue;
      }
    }
  }

  PaymentRequiredException _paymentRequiredFromStream(http.StreamedResponse response) {
    // Best-effort parse; stream body may be empty for 402.
    return const PaymentRequiredException(
      'Daily AI limit reached. Upgrade to Ofertix Premium for unlimited queries.',
      code: 'ai_quota_exceeded',
    );
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    try {
      final response = await request().timeout(timeout ?? defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw TimeoutAppException(
        'Connection timeout. Please check your internet and try again.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please try again.',
        cause: e,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Network request failed. Please try again.',
        cause: e,
      );
    }
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  dynamic _unwrapSuccessBody(dynamic decoded, int statusCode) {
    final envelope = ApiResponse.fromJson(decoded);
    if (!envelope.success) {
      final message = envelope.error ?? 'Request failed';
      if (statusCode == 402) {
        throw PaymentRequiredException(message, code: 'ai_quota_exceeded');
      }
      throw NetworkException(message, statusCode: statusCode, code: 'api_error');
    }
    return envelope.data ?? decoded;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final decoded = _decodeBody(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      if (decoded is Map && decoded.containsKey('success')) {
        return _unwrapSuccessBody(decoded, statusCode);
      }
      return decoded;
    }

    if (decoded is Map && decoded.containsKey('success') && decoded['success'] != true) {
      final message = decoded['error']?.toString() ?? 'Request failed';
      if (statusCode == 402) {
        final meta = decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : <String, dynamic>{};
        throw PaymentRequiredException(
          message,
          code: 'ai_quota_exceeded',
          limit: meta['limit'] is int ? meta['limit'] as int : int.tryParse('${meta['limit']}'),
          used: meta['used'] is int ? meta['used'] as int : int.tryParse('${meta['used']}'),
          resetsAt: meta['resetsAt']?.toString(),
        );
      }
      throw NetworkException(message, statusCode: statusCode, code: 'api_error');
    }

    final backendMessage = decoded is Map
        ? (decoded['safeMessage'] ??
              decoded['message'] ??
              decoded['detail'] ??
              decoded['error'])
        : null;

    final safeMessage = backendMessage?.toString().trim();
    final hasMessage = safeMessage != null && safeMessage.isNotEmpty;

    switch (statusCode) {
      case 400:
        throw NetworkException(
          hasMessage ? safeMessage : 'Bad request.',
          statusCode: statusCode,
          code: 'bad_request',
        );
      case 401:
        throw UnauthorizedException(
          hasMessage ? safeMessage : 'Please log in again.',
        );
      case 402:
        Map<String, dynamic> meta = {};
        if (decoded is Map && decoded['meta'] is Map) {
          meta = Map<String, dynamic>.from(decoded['meta'] as Map);
        }
        throw PaymentRequiredException(
          hasMessage
              ? safeMessage
              : 'Daily AI limit reached. Upgrade to Ofertix Premium for unlimited queries.',
          code: 'ai_quota_exceeded',
          limit: meta['limit'] is int ? meta['limit'] as int : int.tryParse('${meta['limit']}'),
          used: meta['used'] is int ? meta['used'] as int : int.tryParse('${meta['used']}'),
          resetsAt: meta['resetsAt']?.toString(),
        );
      case 403:
        throw ForbiddenException(
          hasMessage ? safeMessage : 'You do not have permission to do this.',
        );
      case 404:
        throw NotFoundException(
          hasMessage ? safeMessage : 'Resource not found.',
        );
      case >= 500:
        throw ServerException(
          hasMessage ? safeMessage : 'Server error. Please try again later.',
          statusCode: statusCode,
        );
      default:
        throw NetworkException(
          hasMessage ? safeMessage : 'Request failed.',
          statusCode: statusCode,
          code: 'http_$statusCode',
        );
    }
  }

  void dispose() => _client.close();
}
