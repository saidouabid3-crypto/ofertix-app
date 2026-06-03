import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ofertix_ad_model.dart';
import 'profile_service.dart';

class AdminAdsService {
  AdminAdsService._();

  static final AdminAdsService instance = AdminAdsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProfileService _profileService = ProfileService.instance;

  CollectionReference<Map<String, dynamic>> get _ads =>
      _firestore.collection('ads');

  Stream<List<OfertixAdModel>> watchAds({OfertixAdPlacement? placement}) {
    Query<Map<String, dynamic>> query = _ads;

    if (placement != null) {
      query = query.where(
        'placement',
        isEqualTo: OfertixAdModel.placementKey(placement),
      );
    }

    // No orderBy here on purpose: it avoids Firebase composite-index errors.
    return query.snapshots().map((snapshot) {
      final ads = snapshot.docs.map(OfertixAdModel.fromDoc).toList();
      ads.sort(_sortAds);
      return ads;
    });
  }

  Stream<List<OfertixAdModel>> watchLiveAds({
    required OfertixAdPlacement placement,
    String countryCode = 'es',
  }) {
    final placementKey = OfertixAdModel.placementKey(placement);
    final normalizedCountry = countryCode.trim().toLowerCase();

    return _ads
        .where('placement', isEqualTo: placementKey)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs.map(OfertixAdModel.fromDoc).where((ad) {
            final adCountry = ad.countryCode.trim().toLowerCase();
            final countryMatches =
                adCountry == 'global' ||
                normalizedCountry.isEmpty ||
                adCountry == normalizedCountry;
            return ad.isLiveNow && countryMatches;
          }).toList();
          ads.sort(_sortAds);
          return ads.take(20).toList();
        });
  }

  Future<void> createAd(OfertixAdModel ad) async {
    await _assertAdmin();
    _validate(ad);
    await _ads.add(ad.toFirestore(creating: true));
  }

  Future<void> updateAd(OfertixAdModel ad) async {
    await _assertAdmin();
    if (ad.id.trim().isEmpty) throw Exception('Ad id is required.');
    _validate(ad);

    final data = ad.toFirestore(creating: false);
    data.addAll(ad.clearDateFieldsPatch());

    await _ads.doc(ad.id).set(data, SetOptions(merge: true));
  }

  Future<void> setActive(String adId, bool active) async {
    await _assertAdmin();
    await _ads.doc(adId).set({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAd(String adId) async {
    await _assertAdmin();

    final cleanId = adId.trim();
    if (cleanId.isEmpty) {
      throw Exception('Ad id is required.');
    }

    await _ads.doc(cleanId).delete();
  }

  Future<void> deleteAds(List<String> adIds) async {
    await _assertAdmin();

    final cleanIds = adIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) return;

    final batch = _firestore.batch();

    for (final id in cleanIds) {
      batch.delete(_ads.doc(id));
    }

    await batch.commit();
  }

  Future<void> registerImpression(String adId) async {
    if (adId.trim().isEmpty) return;
    try {
      await _ads.doc(adId).set({
        'impressions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Never break the user app because analytics counters failed.
    }
  }

  Future<void> registerClick(String adId) async {
    if (adId.trim().isEmpty) return;
    try {
      await _ads.doc(adId).set({
        'clicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Never break the user app because analytics counters failed.
    }
  }

  Future<void> _assertAdmin() async {
    final isAdmin = await _profileService.isCurrentUserAdmin();
    if (!isAdmin) throw Exception('Admin access required.');
  }

  void _validate(OfertixAdModel ad) {
    if (ad.title.trim().isEmpty) throw Exception('Title is required.');
    if (ad.trackingUrl.trim().isEmpty) {
      throw Exception('Tracking URL is required.');
    }
    final uri = Uri.tryParse(ad.trackingUrl.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw Exception('Tracking URL is not valid.');
    }
    if (ad.type == OfertixAdType.video && ad.mediaUrl.trim().isEmpty) {
      throw Exception('Video ads require a video URL or uploaded video.');
    }
    if (ad.priority < 0 || ad.priority > 9999) {
      throw Exception('Priority must be between 0 and 9999.');
    }
    if (ad.endAt != null &&
        ad.startAt != null &&
        ad.endAt!.isBefore(ad.startAt!)) {
      throw Exception('End date must be after start date.');
    }
  }
}

int _sortAds(OfertixAdModel a, OfertixAdModel b) {
  final byPriority = b.priority.compareTo(a.priority);
  if (byPriority != 0) return byPriority;
  return b.updatedAt.compareTo(a.updatedAt);
}
