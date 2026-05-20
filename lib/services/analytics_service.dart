import 'firebase_service.dart';

class AnalyticsService {
  static Future<void> track({
    required String event,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseService.analytics().add({
      'event': event,
      'data': data ?? {},
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
