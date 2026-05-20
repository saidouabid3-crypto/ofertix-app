import '../../services/scan_service.dart';

class ScanRepository {
  final ScanService _scanService = ScanService();

  Future<dynamic> findByCode(String code) {
    return _scanService.findByCode(code);
  }
}
