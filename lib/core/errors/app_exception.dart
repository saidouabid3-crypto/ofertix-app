class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() {
    return code == null ? message : '[$code] $message';
  }
}

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
  });
}

class TimeoutAppException extends NetworkException {
  const TimeoutAppException(super.message, {super.cause})
      : super(code: 'timeout');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(
    super.message, {
    super.code = 'unauthorized',
    super.cause,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException(
    super.message, {
    super.code = 'forbidden',
    super.cause,
  });
}

/// Thrown when the backend returns 403 USER_BANNED — account is restricted.
class BannedAccountException extends ForbiddenException {
  const BannedAccountException([super.message = 'Your account is restricted.'])
      : super(code: 'user_banned');
}

class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code = 'not_found',
    super.cause,
  });
}

class ServerException extends NetworkException {
  const ServerException(
    super.message, {
    super.statusCode,
    super.code = 'server_error',
    super.cause,
  });
}

/// HTTP 402 — daily AI quota exceeded; show premium upgrade UI.
class PaymentRequiredException extends AppException {
  final int? limit;
  final int? used;
  final String? resetsAt;

  const PaymentRequiredException(
    super.message, {
    super.code = 'ai_quota_exceeded',
    super.cause,
    this.limit,
    this.used,
    this.resetsAt,
  });
}
