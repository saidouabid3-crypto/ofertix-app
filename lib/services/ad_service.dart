import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ad_banner_model.dart';

/// Reads active affiliate banners from Firestore.
/// WHY: Ads should be remotely controlled without shipping a new app version.
class AdService {
  AdService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AdBannerModel>> watchActiveAds({
    String placement = 'home_top',
    int limit = 5,
  }) {
    return _firestore
        .collection('ads')
        .where('isActive', isEqualTo: true)
        .where('placement', isEqualTo: placement)
        .orderBy('priority', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AdBannerModel.fromFirestore)
              .where((ad) => ad.hasValidLink)
              .toList(growable: false),
        );
  }
}
