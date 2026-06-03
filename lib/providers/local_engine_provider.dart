
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/local_offer_model.dart';
import '../models/local_store_model.dart';
import '../services/local_engine_service.dart';

class LocalEngineProvider extends ChangeNotifier {
  LocalEngineProvider({LocalEngineService? service})
      : _service = service ?? LocalEngineService.instance;

  final LocalEngineService _service;

  List<LocalStoreModel> stores = [];
  List<LocalOfferModel> offers = [];
  List<LocalOfferModel> pendingOffers = [];
  Position? userPosition;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadFeaturedStores({String countryCode = 'es'}) async {
    await _guard(() async {
      stores = await _service.getFeaturedStores(countryCode: countryCode);
    });
  }

  Future<void> loadNearby({double radiusKm = 10, String? category}) async {
    await _guard(() async {
      final position = await _resolvePosition();
      userPosition = position;
      stores = await _service.getNearbyStores(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
        category: category,
      );
      offers = await _service.getNearbyOffers(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
        category: category,
      );
    });
  }

  Future<void> loadMerchantDashboard() async {
    await _guard(() async {
      stores = await _service.getMerchantStores();
      offers = await _service.getMerchantOffers();
    });
  }

  Future<void> loadPendingOffers() async {
    await _guard(() async {
      pendingOffers = await _service.getPendingOffers();
    });
  }

  Future<LocalStoreModel> createStore(LocalStoreModel store) async {
    final created = await _service.createStore(store);
    stores = [created, ...stores.where((e) => e.id != created.id)];
    notifyListeners();
    return created;
  }

  Future<LocalOfferModel> createOffer(LocalOfferModel offer) async {
    final created = await _service.createOffer(offer);
    offers = [created, ...offers.where((e) => e.id != created.id)];
    notifyListeners();
    return created;
  }

  Future<void> approveOffer(String offerId) async {
    final updated = await _service.approveOffer(offerId);
    pendingOffers = pendingOffers.where((e) => e.id != offerId).toList();
    offers = [updated, ...offers.where((e) => e.id != offerId)];
    notifyListeners();
  }

  Future<void> rejectOffer(String offerId, {String reason = ''}) async {
    await _service.rejectOffer(offerId, reason: reason);
    pendingOffers = pendingOffers.where((e) => e.id != offerId).toList();
    notifyListeners();
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('local.locationDisabled');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('local.locationPermissionRequired');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _guard(Future<void> Function() work) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await work();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
