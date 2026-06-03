import '../core/config/api_endpoints.dart';
import '../models/setup_status_model.dart';
import 'api_service.dart';

class SetupStatusService {
  SetupStatusService._();
  static final SetupStatusService instance = SetupStatusService._();

  Future<SetupStatusModel> publicStatus() async {
    final response = await ApiService.instance.get(ApiEndpoints.setupPublic);
    return SetupStatusModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<SetupStatusModel> adminStatus() async {
    final response = await ApiService.instance.get(
      ApiEndpoints.setupAdmin,
      authorized: true,
    );
    return SetupStatusModel.fromMap(Map<String, dynamic>.from(response as Map));
  }
}
