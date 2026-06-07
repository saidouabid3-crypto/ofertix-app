import 'package:flutter/material.dart';

import '../../models/product.dart';

enum ProductTrustState {
  priceNeedsReview,
  offerUnderReview,
  verified,
  sourceReliable,
  limitedInfo,
  none,
}

class ProductTrustUi {
  ProductTrustUi._();

  static const _criticalFlags = {
    'missing_price',
    'missing_image',
    'missing_link',
    'invalid_link',
    'missing_currency',
    'suspicious_price',
    'duplicate_candidate',
  };
  static const _limitedFlags = {
    'single_image_only',
    'no_gallery',
    'weak_description',
  };
  static const _blockedStatuses = {
    'needs_review',
    'quarantined',
    'duplicate',
    'hidden',
  };

  static ProductTrustState resolve(Product p) {
    final flags = p.qualityFlags.map((f) => f.toLowerCase()).toSet();
    final trust = (p.trustStatus ?? '').toLowerCase();
    final priceConf = (p.priceConfidence ?? '').toLowerCase();
    final admission = (p.admissionStatus ?? '').toLowerCase();
    final risk = (p.riskLevel ?? '').toLowerCase();

    // 1 – price / currency problem
    final priceIssue = priceConf == 'missing' ||
        priceConf == 'needs_review' ||
        flags.intersection({'missing_price', 'suspicious_price', 'missing_currency'}).isNotEmpty ||
        p.newPrice <= 0;
    if (priceIssue) return ProductTrustState.priceNeedsReview;

    // 2 – offer under review
    final underReview = admission == 'needs_review' ||
        trust == 'needs_review' ||
        risk == 'medium' ||
        risk == 'high';
    if (underReview) return ProductTrustState.offerUnderReview;

    // no positive signal if critical flags or blocked status
    if (flags.intersection(_criticalFlags).isNotEmpty) return ProductTrustState.none;
    if (_blockedStatuses.contains(trust)) return ProductTrustState.none;

    // 3 – verified
    final isTrusted = trust == 'trusted' || trust == 'ok';
    final admissionOk = admission.isEmpty || admission == 'approved' || admission == 'ok';
    if (isTrusted && admissionOk && priceConf != 'missing') {
      return ProductTrustState.verified;
    }

    // 4 – source reliable
    final srcTrust = p.sourceTrustScoreAtImport ?? 0.0;
    if (srcTrust >= 85 && isTrusted) return ProductTrustState.sourceReliable;

    // 5 – limited info
    if (flags.intersection(_limitedFlags).isNotEmpty) {
      return ProductTrustState.limitedInfo;
    }

    return ProductTrustState.none;
  }

  static String shortKey(ProductTrustState state) {
    switch (state) {
      case ProductTrustState.priceNeedsReview:
        return 'productTrust.priceNeedsReviewShort';
      case ProductTrustState.offerUnderReview:
        return 'productTrust.offerUnderReviewShort';
      case ProductTrustState.verified:
        return 'productTrust.verifiedShort';
      case ProductTrustState.sourceReliable:
        return 'productTrust.sourceReliableShort';
      case ProductTrustState.limitedInfo:
        return 'productTrust.limitedInfoShort';
      case ProductTrustState.none:
        return '';
    }
  }

  static String messageKey(ProductTrustState state) {
    switch (state) {
      case ProductTrustState.priceNeedsReview:
        return 'productTrust.priceReviewMessage';
      case ProductTrustState.offerUnderReview:
        return 'productTrust.reviewMessage';
      case ProductTrustState.verified:
        return 'productTrust.verifiedMessage';
      case ProductTrustState.sourceReliable:
        return 'productTrust.sourceReliableMessage';
      case ProductTrustState.limitedInfo:
        return 'productTrust.limitedInfoMessage';
      case ProductTrustState.none:
        return '';
    }
  }

  static IconData icon(ProductTrustState state) {
    switch (state) {
      case ProductTrustState.priceNeedsReview:
        return Icons.warning_amber_rounded;
      case ProductTrustState.offerUnderReview:
        return Icons.pending_rounded;
      case ProductTrustState.verified:
        return Icons.verified_rounded;
      case ProductTrustState.sourceReliable:
        return Icons.shield_rounded;
      case ProductTrustState.limitedInfo:
        return Icons.info_outline_rounded;
      case ProductTrustState.none:
        return Icons.info_outline_rounded;
    }
  }

  static Color color(ProductTrustState state) {
    switch (state) {
      case ProductTrustState.priceNeedsReview:
        return const Color(0xFFFF9800);
      case ProductTrustState.offerUnderReview:
        return const Color(0xFF78909C);
      case ProductTrustState.verified:
        return const Color(0xFF4CAF50);
      case ProductTrustState.sourceReliable:
        return const Color(0xFF4CAF50);
      case ProductTrustState.limitedInfo:
        return const Color(0xFF78909C);
      case ProductTrustState.none:
        return const Color(0xFF78909C);
    }
  }
}
