import 'package:flutter/material.dart';

import '../../models/admin_duplicate_model.dart';
import '../../models/admin_import_batch_model.dart';
import '../../models/admin_log_entry_model.dart';
import '../../models/admin_source_trust_model.dart';
import '../../models/admin_moderation_item_model.dart';
import '../../models/admin_overview_model.dart';
import '../../models/admin_product_quality_model.dart';
import '../../models/admin_report_model.dart';
import '../../models/admin_system_health_model.dart';
import '../../models/admin_user_view_model.dart';
import '../../services/admin_service.dart';
import '../../services/profile_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService.instance;

  // ── access ────────────────────────────────────────────────────────────────
  bool isCheckingAccess = true;
  bool isAdmin = false;

  // ── overview ──────────────────────────────────────────────────────────────
  bool isLoadingOverview = false;
  AdminOverviewModel? overview;
  String? overviewError;

  // ── moderation reels ──────────────────────────────────────────────────────
  bool isLoadingReels = false;
  List<AdminModerationItemModel> reels = [];
  String reelsStatusFilter = 'approved';
  String? reelsError;

  // ── moderation marketplace ────────────────────────────────────────────────
  bool isLoadingMarketplace = false;
  List<AdminModerationItemModel> marketplaceItems = [];
  String marketplaceStatusFilter = 'active';
  String? marketplaceError;

  // ── reports ───────────────────────────────────────────────────────────────
  bool isLoadingReports = false;
  List<AdminReportModel> reports = [];
  String? reportsError;

  // ── users ─────────────────────────────────────────────────────────────────
  bool isLoadingUsers = false;
  List<AdminUserViewModel> users = [];
  String? usersError;

  // ── product quality ───────────────────────────────────────────────────────
  bool isLoadingProductQuality = false;
  List<AdminProductQualityItemModel> productQualityItems = [];
  String? productQualityError;
  bool isScanLoading = false;
  ProductTrustScanSummaryModel? lastScanSummary;
  String? scanError;

  // ── duplicate review ──────────────────────────────────────────────────────
  bool isDuplicatesLoading = false;
  List<AdminDuplicateGroupModel> duplicateGroups = [];
  String? duplicatesError;
  bool isDuplicateScanLoading = false;
  AdminDuplicateScanSummaryModel? lastDuplicateScanSummary;
  String? duplicateScanError;
  String selectedDuplicateStatusFilter = 'candidate';

  // ── system health ─────────────────────────────────────────────────────────
  bool isLoadingHealth = false;
  AdminSystemHealthModel? systemHealth;
  String? healthError;

  // ── audit logs ────────────────────────────────────────────────────────────
  bool isLoadingLogs = false;
  List<AdminLogEntryModel> adminLogs = [];
  String? logsError;

  // ── import intelligence ───────────────────────────────────────────────────
  bool isLoadingImportBatches = false;
  List<AdminImportBatchModel> importBatches = [];
  String? importBatchesError;

  bool isLoadingSourceTrust = false;
  List<AdminSourceTrustModel> sourceTrustList = [];
  String? sourceTrustError;

  bool isImportActing = false;
  String? importActionError;
  Map<String, dynamic>? lastImportActionResult;

  // ── action state ──────────────────────────────────────────────────────────
  bool isActing = false;
  String? actionError;

  Future<void> checkAdminAccess() async {
    isCheckingAccess = true;
    notifyListeners();
    try {
      isAdmin = await ProfileService.instance.isCurrentUserAdmin();
    } catch (_) {
      isAdmin = false;
    }
    isCheckingAccess = false;
    notifyListeners();
  }

  Future<void> loadOverview() async {
    isLoadingOverview = true;
    overviewError = null;
    notifyListeners();
    try {
      overview = await _service.getOverview();
    } catch (e) {
      overviewError = e.toString();
    }
    isLoadingOverview = false;
    notifyListeners();
  }

  Future<void> loadReels({String? status}) async {
    final s = status ?? reelsStatusFilter;
    reelsStatusFilter = s;
    isLoadingReels = true;
    reelsError = null;
    notifyListeners();
    try {
      final result = await _service.getModerationReels(status: s);
      reels = result.items;
    } catch (e) {
      reelsError = e.toString();
    }
    isLoadingReels = false;
    notifyListeners();
  }

  Future<void> loadMarketplace({String? status}) async {
    final s = status ?? marketplaceStatusFilter;
    marketplaceStatusFilter = s;
    isLoadingMarketplace = true;
    marketplaceError = null;
    notifyListeners();
    try {
      final result = await _service.getModerationMarketplace(status: s);
      marketplaceItems = result.items;
    } catch (e) {
      marketplaceError = e.toString();
    }
    isLoadingMarketplace = false;
    notifyListeners();
  }

  Future<void> loadReports() async {
    isLoadingReports = true;
    reportsError = null;
    notifyListeners();
    try {
      final result = await _service.getReports();
      reports = result.reports;
    } catch (e) {
      reportsError = e.toString();
    }
    isLoadingReports = false;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    isLoadingUsers = true;
    usersError = null;
    notifyListeners();
    try {
      final result = await _service.getUsers();
      users = result.users;
    } catch (e) {
      usersError = e.toString();
    }
    isLoadingUsers = false;
    notifyListeners();
  }

  Future<void> loadProductQuality() async {
    isLoadingProductQuality = true;
    productQualityError = null;
    notifyListeners();
    try {
      final result = await _service.getProductQuality();
      productQualityItems = result.items;
    } catch (e) {
      productQualityError = e.toString();
    }
    isLoadingProductQuality = false;
    notifyListeners();
  }

  Future<void> loadSystemHealth() async {
    isLoadingHealth = true;
    healthError = null;
    notifyListeners();
    try {
      systemHealth = await _service.getSystemHealth();
    } catch (e) {
      healthError = e.toString();
    }
    isLoadingHealth = false;
    notifyListeners();
  }

  Future<void> loadAdminLogs() async {
    isLoadingLogs = true;
    logsError = null;
    notifyListeners();
    try {
      final result = await _service.getAdminLogs();
      adminLogs = result.logs;
    } catch (e) {
      logsError = e.toString();
    }
    isLoadingLogs = false;
    notifyListeners();
  }

  // ── reel actions ──────────────────────────────────────────────────────────

  Future<bool> moderateReel(String reelId, String action, {String? reason}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      switch (action) {
        case 'approve':
          await _service.approveReel(reelId, reason: reason);
        case 'reject':
          await _service.rejectReel(reelId, reason: reason);
        case 'hide':
          await _service.hideReel(reelId, reason: reason);
        case 'restore':
          await _service.restoreReel(reelId);
      }
      isActing = false;
      notifyListeners();
      await loadReels();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  // ── marketplace actions ───────────────────────────────────────────────────

  Future<bool> moderateMarketplaceItem(String itemId, String action, {String? reason}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      switch (action) {
        case 'approve':
          await _service.approveMarketplaceItem(itemId, reason: reason);
        case 'reject':
          await _service.rejectMarketplaceItem(itemId, reason: reason);
        case 'hide':
          await _service.hideMarketplaceItem(itemId, reason: reason);
        case 'restore':
          await _service.restoreMarketplaceItem(itemId);
      }
      isActing = false;
      notifyListeners();
      await loadMarketplace();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  // ── report actions ────────────────────────────────────────────────────────

  Future<bool> actOnReport(String reportId, String action, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      switch (action) {
        case 'resolve':
          await _service.resolveReport(reportId, note: note);
        case 'dismiss':
          await _service.dismissReport(reportId, note: note);
        case 'note':
          if (note != null) await _service.addReportNote(reportId, note);
      }
      isActing = false;
      notifyListeners();
      await loadReports();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  // ── user actions ──────────────────────────────────────────────────────────

  Future<bool> actOnUser(String uid, String action, {String? reason, String? role}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      switch (action) {
        case 'verify':
          await _service.verifyUser(uid);
        case 'unverify':
          await _service.unverifyUser(uid);
        case 'verify_seller':
          await _service.verifySeller(uid);
        case 'remove_seller':
          await _service.removeSellerVerification(uid);
        case 'ban':
          await _service.banUser(uid, reason: reason);
        case 'unban':
          await _service.unbanUser(uid);
        case 'role':
          if (role != null) await _service.changeUserRole(uid, role);
      }
      isActing = false;
      notifyListeners();
      await loadUsers();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  // ── product actions ───────────────────────────────────────────────────────

  Future<bool> actOnProduct(String productId, String action, {String? reason}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      switch (action) {
        case 'hide':
          await _service.hideProduct(productId, reason: reason);
        case 'restore':
          await _service.restoreProduct(productId);
        case 'mark_review':
          await _service.markProductReview(productId, reason: reason);
        case 'mark_safe':
          await _service.markProductSafe(productId);
        case 'refresh':
          await _service.refreshProductQuality(productId);
      }
      isActing = false;
      notifyListeners();
      await loadProductQuality();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<ProductTrustScanSummaryModel?> runDryRunScan({int limit = 100}) async {
    isScanLoading = true;
    scanError = null;
    lastScanSummary = null;
    notifyListeners();
    try {
      final result = await _service.scanProductQuality(dryRun: true, limit: limit, write: false);
      lastScanSummary = result;
      isScanLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      scanError = e.toString();
      isScanLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<ProductTrustScanSummaryModel?> applyProductQualityScan({int limit = 100}) async {
    isScanLoading = true;
    scanError = null;
    lastScanSummary = null;
    notifyListeners();
    try {
      final result = await _service.scanProductQuality(dryRun: false, limit: limit, write: true);
      lastScanSummary = result;
      isScanLoading = false;
      notifyListeners();
      await loadProductQuality();
      return result;
    } catch (e) {
      scanError = e.toString();
      isScanLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── duplicate actions ─────────────────────────────────────────────────────

  Future<void> loadDuplicateGroups({String? status}) async {
    isDuplicatesLoading = true;
    duplicatesError = null;
    notifyListeners();
    try {
      final s = status ?? selectedDuplicateStatusFilter;
      final result = await _service.getProductDuplicateGroups(status: s, limit: 50);
      duplicateGroups = result.groups;
    } catch (e) {
      duplicatesError = e.toString();
    }
    isDuplicatesLoading = false;
    notifyListeners();
  }

  Future<AdminDuplicateScanSummaryModel?> runDuplicateDryRunScan({int limit = 300}) async {
    isDuplicateScanLoading = true;
    duplicateScanError = null;
    lastDuplicateScanSummary = null;
    notifyListeners();
    try {
      final result = await _service.scanProductDuplicates(dryRun: true, limit: limit, write: false);
      lastDuplicateScanSummary = result;
      isDuplicateScanLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      duplicateScanError = e.toString();
      isDuplicateScanLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<AdminDuplicateScanSummaryModel?> applyDuplicateScan({int limit = 300}) async {
    isDuplicateScanLoading = true;
    duplicateScanError = null;
    lastDuplicateScanSummary = null;
    notifyListeners();
    try {
      final result = await _service.scanProductDuplicates(dryRun: false, limit: limit, write: true);
      lastDuplicateScanSummary = result;
      isDuplicateScanLoading = false;
      notifyListeners();
      await loadDuplicateGroups();
      return result;
    } catch (e) {
      duplicateScanError = e.toString();
      isDuplicateScanLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> markDuplicateMaster(String groupId, String productId, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _service.markDuplicateMaster(groupId, productId, note: note);
      isActing = false;
      notifyListeners();
      await loadDuplicateGroups();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> hideDuplicate(String productId, String masterProductId, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _service.hideDuplicateProduct(productId, masterProductId, note: note);
      isActing = false;
      notifyListeners();
      await loadDuplicateGroups();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> dismissDuplicate(String productId, {String? note}) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _service.dismissDuplicateProduct(productId, note: note);
      isActing = false;
      notifyListeners();
      await loadDuplicateGroups();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreDuplicate(String productId) async {
    isActing = true;
    actionError = null;
    notifyListeners();
    try {
      await _service.restoreDuplicateProduct(productId);
      isActing = false;
      notifyListeners();
      await loadDuplicateGroups();
      return true;
    } catch (e) {
      actionError = e.toString();
      isActing = false;
      notifyListeners();
      return false;
    }
  }

  // ── import intelligence ───────────────────────────────────────────────────

  Future<void> loadImportBatches() async {
    isLoadingImportBatches = true;
    importBatchesError = null;
    notifyListeners();
    try {
      final result = await _service.getImportBatches();
      importBatches = result.batches;
    } catch (e) {
      importBatchesError = e.toString();
    }
    isLoadingImportBatches = false;
    notifyListeners();
  }

  Future<void> loadSourceTrust() async {
    isLoadingSourceTrust = true;
    sourceTrustError = null;
    notifyListeners();
    try {
      final result = await _service.getSourceTrust();
      sourceTrustList = result.items;
    } catch (e) {
      sourceTrustError = e.toString();
    }
    isLoadingSourceTrust = false;
    notifyListeners();
  }

  Future<bool> hideImportBatchProducts(String batchId, {String? note}) async {
    isImportActing = true;
    importActionError = null;
    lastImportActionResult = null;
    notifyListeners();
    try {
      final result = await _service.hideImportBatchProducts(batchId, note: note);
      lastImportActionResult = result;
      isImportActing = false;
      notifyListeners();
      await loadImportBatches();
      return true;
    } catch (e) {
      importActionError = e.toString();
      isImportActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markImportBatchReview(String batchId, {String? note}) async {
    isImportActing = true;
    importActionError = null;
    lastImportActionResult = null;
    notifyListeners();
    try {
      final result = await _service.markImportBatchReview(batchId, note: note);
      lastImportActionResult = result;
      isImportActing = false;
      notifyListeners();
      await loadImportBatches();
      return true;
    } catch (e) {
      importActionError = e.toString();
      isImportActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreImportBatchProducts(String batchId, {String? note}) async {
    isImportActing = true;
    importActionError = null;
    lastImportActionResult = null;
    notifyListeners();
    try {
      final result = await _service.restoreImportBatchProducts(batchId, note: note);
      lastImportActionResult = result;
      isImportActing = false;
      notifyListeners();
      await loadImportBatches();
      return true;
    } catch (e) {
      importActionError = e.toString();
      isImportActing = false;
      notifyListeners();
      return false;
    }
  }
}
