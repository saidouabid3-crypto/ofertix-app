import '../services/analytics_service.dart';

class AnalyticsRepository {
  Future<void> track({required String event, Map<String, dynamic>? data}) {
    return AnalyticsService.track(event: event, data: data);
  }
}
