import '../core/config/api_endpoints.dart';
import '../models/admin_catalog_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_duplicate_model.dart';
import '../models/admin_import_batch_model.dart';
import '../models/admin_log_entry_model.dart';
import '../models/admin_moderation_item_model.dart';
import '../models/admin_overview_model.dart';
import '../models/admin_product_quality_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_source_trust_model.dart';
import '../models/admin_system_health_model.dart';
import '../models/admin_user_view_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;

  Future<void> _setToken() async {
    final token = await _auth.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Admin session required.');
    }
    _api.setToken(token);
  }

  dynamic _unwrap(dynamic response) {
    if (response is Map && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  Map<String, dynamic> _toMap(dynamic response) {
    final data = _unwrap(response);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected admin response shape.');
  }

  // ── original dashboard ────────────────────────────────────────────────────

  Future<AdminDashboardModel> getDashboard() async {
    await _setToken();
    final response = await _api.get(
      ApiEndpoints.adminDashboard,
      authorized: true,
    );
    return AdminDashboardModel.fromJson(_toMap(response));
  }

  // ── overview ──────────────────────────────────────────────────────────────

  Future<AdminOverviewModel> getOverview() async {
    await _setToken();
    final response = await _api.get('/admin/overview', authorized: true);
    return AdminOverviewModel.fromJson(_toMap(response));
  }

  // ── moderation: reels ─────────────────────────────────────────────────────

  Future<AdminModerationListModel> getModerationReels({
    String status = 'pending',
    int limit = 50,
  }) async {
    await _setToken();
    final response = await _api.get(
      '/admin/moderation/reels',
      authorized: true,
      queryParameters: {'status': status, 'limit': limit},
    );
    return AdminModerationListModel.fromJson(_toMap(response));
  }

  Future<void> approveReel(String reelId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/reels/$reelId/approve',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> rejectReel(String reelId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/reels/$reelId/reject',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> hideReel(String reelId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/reels/$reelId/hide',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> restoreReel(String reelId) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/reels/$reelId/restore',
      authorized: true,
    );
  }

  // ── moderation: marketplace ───────────────────────────────────────────────

  Future<AdminModerationListModel> getModerationMarketplace({
    String status = 'pending',
    int limit = 50,
  }) async {
    await _setToken();
    final response = await _api.get(
      '/admin/moderation/marketplace',
      authorized: true,
      queryParameters: {'status': status, 'limit': limit},
    );
    return AdminModerationListModel.fromJson(_toMap(response));
  }

  Future<void> approveMarketplaceItem(String itemId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/marketplace/$itemId/approve',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> rejectMarketplaceItem(String itemId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/marketplace/$itemId/reject',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> hideMarketplaceItem(String itemId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/marketplace/$itemId/hide',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> restoreMarketplaceItem(String itemId) async {
    await _setToken();
    await _api.post(
      '/admin/moderation/marketplace/$itemId/restore',
      authorized: true,
    );
  }

  // ── reports ───────────────────────────────────────────────────────────────

  Future<AdminReportListModel> getReports({int limit = 50}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/reports',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminReportListModel.fromJson(_toMap(response));
  }

  Future<void> resolveReport(String reportId, {String? note}) async {
    await _setToken();
    await _api.post(
      '/admin/reports/$reportId/resolve',
      authorized: true,
      body: {'note': note},
    );
  }

  Future<void> dismissReport(String reportId, {String? note}) async {
    await _setToken();
    await _api.post(
      '/admin/reports/$reportId/dismiss',
      authorized: true,
      body: {'note': note},
    );
  }

  Future<void> addReportNote(String reportId, String note) async {
    await _setToken();
    await _api.post(
      '/admin/reports/$reportId/note',
      authorized: true,
      body: {'note': note},
    );
  }

  // ── users ─────────────────────────────────────────────────────────────────

  Future<AdminUserListModel> getUsers({int limit = 50}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/users',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminUserListModel.fromJson(_toMap(response));
  }

  Future<AdminUserViewModel?> getUser(String uid) async {
    await _setToken();
    final response = await _api.get('/admin/users/$uid', authorized: true);
    return AdminUserViewModel.fromJson(_toMap(response));
  }

  Future<void> verifyUser(String uid) async {
    await _setToken();
    await _api.post('/admin/users/$uid/verify', authorized: true);
  }

  Future<void> unverifyUser(String uid) async {
    await _setToken();
    await _api.post('/admin/users/$uid/unverify', authorized: true);
  }

  Future<void> verifySeller(String uid) async {
    await _setToken();
    await _api.post('/admin/users/$uid/verify-seller', authorized: true);
  }

  Future<void> removeSellerVerification(String uid) async {
    await _setToken();
    await _api.post(
      '/admin/users/$uid/remove-seller-verification',
      authorized: true,
    );
  }

  Future<void> banUser(String uid, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/users/$uid/ban',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> unbanUser(String uid) async {
    await _setToken();
    await _api.post('/admin/users/$uid/unban', authorized: true);
  }

  Future<void> changeUserRole(String uid, String role) async {
    await _setToken();
    await _api.post(
      '/admin/users/$uid/role',
      authorized: true,
      body: {'role': role},
    );
  }

  // ── product quality ───────────────────────────────────────────────────────

  Future<AdminProductQualityListModel> getProductQuality({
    int limit = 50,
  }) async {
    await _setToken();
    final response = await _api.get(
      '/admin/products/quality',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminProductQualityListModel.fromJson(_toMap(response));
  }

  Future<void> hideProduct(String productId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/hide',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> restoreProduct(String productId) async {
    await _setToken();
    await _api.post('/admin/products/$productId/restore', authorized: true);
  }

  Future<void> markProductReview(String productId, {String? reason}) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/mark-review',
      authorized: true,
      body: {'reason': reason},
    );
  }

  Future<void> markProductSafe(String productId) async {
    await _setToken();
    await _api.post('/admin/products/$productId/mark-safe', authorized: true);
  }

  Future<void> refreshProductQuality(String productId) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/quality/refresh',
      authorized: true,
    );
  }

  Future<ProductTrustScanSummaryModel> scanProductQuality({
    bool dryRun = true,
    int limit = 100,
    bool write = false,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/products/quality/scan',
      authorized: true,
      body: {'dryRun': dryRun, 'limit': limit, 'write': write},
    );
    return ProductTrustScanSummaryModel.fromJson(_toMap(response));
  }

  // ── product duplicates ────────────────────────────────────────────────────

  Future<AdminDuplicateScanSummaryModel> scanProductDuplicates({
    bool dryRun = true,
    int limit = 300,
    bool write = false,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/products/duplicates/scan',
      authorized: true,
      body: {'dryRun': dryRun, 'limit': limit, 'write': write},
    );
    return AdminDuplicateScanSummaryModel.fromJson(_toMap(response));
  }

  Future<AdminDuplicateGroupListModel> getProductDuplicateGroups({
    String status = 'candidate',
    int limit = 50,
  }) async {
    await _setToken();
    final response = await _api.get(
      '/admin/products/duplicates',
      authorized: true,
      queryParameters: {'status': status, 'limit': limit},
    );
    return AdminDuplicateGroupListModel.fromJson(_toMap(response));
  }

  Future<void> markDuplicateMaster(
    String groupId,
    String productId, {
    String? note,
  }) async {
    await _setToken();
    await _api.post(
      '/admin/products/duplicates/$groupId/mark-master',
      authorized: true,
      body: {'productId': productId, 'note': note},
    );
  }

  Future<void> hideDuplicateProduct(
    String productId,
    String masterProductId, {
    String? note,
  }) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/duplicates/hide',
      authorized: true,
      body: {'masterProductId': masterProductId, 'note': note},
    );
  }

  Future<void> dismissDuplicateProduct(String productId, {String? note}) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/duplicates/dismiss',
      authorized: true,
      body: {'note': note},
    );
  }

  Future<void> restoreDuplicateProduct(String productId) async {
    await _setToken();
    await _api.post(
      '/admin/products/$productId/duplicates/restore',
      authorized: true,
    );
  }

  // ── import batches ────────────────────────────────────────────────────────

  Future<AdminImportBatchListModel> getImportBatches({int limit = 50}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/imports/batches',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminImportBatchListModel.fromJson(_toMap(response));
  }

  Future<AdminImportBatchModel> getImportBatchDetails(String batchId) async {
    await _setToken();
    final response = await _api.get(
      '/admin/imports/batches/$batchId',
      authorized: true,
    );
    return AdminImportBatchModel.fromJson(_toMap(response));
  }

  Future<Map<String, dynamic>> hideImportBatchProducts(
    String batchId, {
    String? note,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/imports/batches/$batchId/hide-products',
      authorized: true,
      body: {'note': note},
    );
    return _toMap(response);
  }

  Future<Map<String, dynamic>> markImportBatchReview(
    String batchId, {
    String? note,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/imports/batches/$batchId/mark-review',
      authorized: true,
      body: {'note': note},
    );
    return _toMap(response);
  }

  Future<Map<String, dynamic>> restoreImportBatchProducts(
    String batchId, {
    String? note,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/imports/batches/$batchId/restore-products',
      authorized: true,
      body: {'note': note},
    );
    return _toMap(response);
  }

  Future<AdminSourceTrustListModel> getSourceTrust({int limit = 50}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/imports/source-trust',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminSourceTrustListModel.fromJson(_toMap(response));
  }

  // ── system health ─────────────────────────────────────────────────────────

  Future<AdminSystemHealthModel> getSystemHealth() async {
    await _setToken();
    final response = await _api.get('/admin/system-health', authorized: true);
    return AdminSystemHealthModel.fromJson(_toMap(response));
  }

  // ── audit logs ────────────────────────────────────────────────────────────

  Future<AdminLogListModel> getAdminLogs({int limit = 50}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/logs',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return AdminLogListModel.fromJson(_toMap(response));
  }

  // ── public catalog governance ─────────────────────────────────────────────

  Future<CatalogPreviewModel> getCatalogPreview({int limit = 500}) async {
    await _setToken();
    final response = await _api.get(
      '/admin/catalog/public-preview',
      authorized: true,
      queryParameters: {'limit': limit},
    );
    return CatalogPreviewModel.fromJson(_toMap(response));
  }

  Future<Map<String, dynamic>> updateCatalogConfig(
    Map<String, dynamic> updates,
  ) async {
    await _setToken();
    final response = await _api.patch(
      '/admin/catalog/public-config',
      authorized: true,
      body: updates,
    );
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'ok': true};
  }

  Future<CatalogHealthModel> getCatalogHealth() async {
    await _setToken();
    final response = await _api.get('/admin/catalog/health', authorized: true);
    return CatalogHealthModel.fromJson(_toMap(response));
  }

  Future<Map<String, dynamic>> recalibrateSourceTrust({
    String? sourceKey,
    bool dryRun = true,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/catalog/recalibrate-source-trust',
      authorized: true,
      body: {
        if (sourceKey != null && sourceKey.trim().isNotEmpty)
          'sourceKey': sourceKey.trim(),
        'dryRun': dryRun,
      },
    );
    return _toMap(response);
  }

  // ── catalog cache shield ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCacheStatus() async {
    await _setToken();
    final response = await _api.get(
      '/admin/catalog/cache/status',
      authorized: true,
    );
    return _toMap(response);
  }

  Future<Map<String, dynamic>> warmCache({
    List<String>? countries,
    int pages = 2,
    int limit = 20,
    bool includeTrending = true,
  }) async {
    await _setToken();
    final response = await _api.post(
      '/admin/catalog/cache/warm',
      authorized: true,
      body: {
        'countries': countries ?? ['es', 'fr', 'us'],
        'pages': pages,
        'limit': limit,
        'includeTrending': includeTrending,
      },
    );
    return _toMap(response);
  }

  Future<Map<String, dynamic>> clearCache() async {
    await _setToken();
    final response = await _api.post(
      '/admin/catalog/cache/clear',
      authorized: true,
    );
    return _toMap(response);
  }
}
