import 'app_exception.dart';

class ErrorHandler {
  static String message(dynamic error) {
    if (error is AppException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
