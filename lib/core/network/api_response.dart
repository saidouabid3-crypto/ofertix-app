class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  const ApiResponse.success(this.data) : success = true, error = null;

  const ApiResponse.error(this.error) : success = false, data = null;

  factory ApiResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return ApiResponse<T>.success(json as T?);
    }

    final data = json['data'];
    final error = json['error'] ?? json['message'] ?? json['safeMessage'];
    final success = json['success'] == true;

    if (success) {
      return ApiResponse<T>.success(data as T?);
    }

    return ApiResponse<T>.error(error?.toString() ?? 'Request failed');
  }
}
