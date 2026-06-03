import '../core/config/api_endpoints.dart';
import '../models/admin_dashboard_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;

  Future<AdminDashboardModel> getDashboard() async {
    final token = await _auth.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Admin session required.');
    }

    _api.setToken(token);
    final response = await _api.get(ApiEndpoints.adminDashboard, authorized: true);

    if (response is Map<String, dynamic>) {
      return AdminDashboardModel.fromJson(response);
    }

    if (response is Map) {
      return AdminDashboardModel.fromJson(Map<String, dynamic>.from(response));
    }

    throw Exception('Invalid admin dashboard response.');
  }
}
