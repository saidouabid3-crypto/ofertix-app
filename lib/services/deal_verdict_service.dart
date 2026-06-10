import '../core/config/api_endpoints.dart';
import '../models/deal_verdict.dart';
import 'api_service.dart';
import 'settings_service.dart';

class DealVerdictService {
  DealVerdictService._();

  static final DealVerdictService instance = DealVerdictService._();

  Future<DealVerdict> getForProduct(String productId) async {
    final country = await SettingsService.instance.getCountry();
    final response = await ApiService.instance.get(
      ApiEndpoints.productDealVerdict(productId, country),
    );
    if (response is! Map) {
      throw const FormatException('Invalid deal verdict response');
    }
    return DealVerdict.fromMap(Map<String, dynamic>.from(response));
  }
}
