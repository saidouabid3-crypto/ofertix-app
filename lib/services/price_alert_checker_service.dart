import 'package:cloud_firestore/cloud_firestore.dart';

import 'alert_service.dart';
import 'firebase_service.dart';

/// Flutter-side price alert checker.
///
/// Runs for the **current authenticated user** when they pull-to-refresh the
/// Alerts screen. It fetches each active alert's latest price from the
/// `products` Firestore collection and triggers local notifications for
/// any price drops.
///
/// The backend job at `POST /api/jobs/check-price-alerts` does the same for
/// ALL users on a schedule (every 6 h). Both paths write to the same
/// `price_alerts` documents, so they are fully compatible.
///
/// Fields updated per alert:
/// - `lastCheckedAt`   — server timestamp of this check
/// - `lastCheckedPrice` — freshest price found (or stored price as fallback)
/// - `triggered`        — true if price <= targetPrice (set by AlertService)
/// - `active`           — false once triggered
/// - `triggeredAt`      — server timestamp when triggered (set by AlertService)
class PriceAlertCheckerService {
  PriceAlertCheckerService._();

  static final PriceAlertCheckerService instance = PriceAlertCheckerService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  /// Checks all active, non-triggered alerts for [userId].
  /// Returns `(checked: N, triggered: M)`.
  Future<({int checked, int triggered})> checkActiveAlerts({
    required String userId,
  }) async {
    int checked = 0;
    int triggered = 0;

    try {
      final snapshot = await _firestore
          .collection('price_alerts')
          .where('userId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .where('triggered', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final alertId = doc.id;

        final productId = data['productId']?.toString() ?? '';
        final productName =
            (data['productName'] ?? data['name'] ?? data['productId'] ?? '')
                .toString();
        final targetPrice = (data['targetPrice'] as num?)?.toDouble() ?? 0;
        final storedPrice =
            (data['currentPrice'] ?? data['newPrice'] as num?)?.toDouble() ?? 0;

        if (targetPrice <= 0) continue;

        // Try to get the latest price from the products collection.
        // Falls back to the price stored in the alert document.
        double latestPrice = storedPrice;
        try {
          final fresh = await _fetchCurrentPrice(productId);
          if (fresh != null && fresh > 0) latestPrice = fresh;
        } catch (_) {}

        // Always record when and at what price we checked.
        try {
          await _firestore.collection('price_alerts').doc(alertId).update({
            'lastCheckedAt': FieldValue.serverTimestamp(),
            'lastCheckedPrice': latestPrice,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        checked++;

        // Trigger alert if price reached target.
        if (latestPrice > 0 && latestPrice <= targetPrice) {
          try {
            await AlertService.instance.checkLocalPriceDrop(
              alertId: alertId,
              productName: productName,
              oldPrice: storedPrice,
              newPrice: latestPrice,
              targetPrice: targetPrice,
            );
            triggered++;
          } catch (_) {}
        }
      }
    } catch (_) {}

    return (checked: checked, triggered: triggered);
  }

  /// Looks up the latest `newPrice` for [productId] from the `products`
  /// collection. Returns null if the product is not found or the price is
  /// unavailable.
  Future<double?> _fetchCurrentPrice(String productId) async {
    final clean = productId.trim();
    if (clean.isEmpty) return null;

    // 1. Direct document lookup (fastest — works when productId == doc.id).
    try {
      final doc = await _firestore.collection('products').doc(clean).get();
      if (doc.exists) {
        final price = (doc.data()?['newPrice'] as num?)?.toDouble();
        if (price != null && price > 0) return price;
      }
    } catch (_) {}

    // 2. Field query fallback (when productId is stored inside the document).
    try {
      final snap = await _firestore
          .collection('products')
          .where('id', isEqualTo: clean)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final price =
            (snap.docs.first.data()['newPrice'] as num?)?.toDouble();
        if (price != null && price > 0) return price;
      }
    } catch (_) {}

    return null;
  }
}
