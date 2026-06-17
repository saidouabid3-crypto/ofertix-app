import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import 'profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  User? user;

  String country = 'ES';

  String currency = 'EUR';

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  UserProfileModel? profile;

  final ProfileService _profileService = ProfileService.instance;

  Future<void> initialize() async {
    user = _repository.currentUser;

    country = await _repository.getCountry();

    currency = await _repository.getCurrency();

    profile = await _profileService.getCurrentProfile();

    isLoading = false;

    notifyListeners();
  }

  Future<bool> saveProfile({
    required String displayName,
    required String username,
    required String bio,
    required String country,
    required String city,
    required String currency,
    required bool isCreator,
    String? photoUrl,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseProfile =
          profile ?? await _profileService.createProfileIfMissing();
      if (baseProfile == null) {
        throw Exception('No authenticated user found.');
      }

      profile = await _profileService.updateProfile(
        profile: baseProfile,
        displayName: displayName,
        username: username,
        bio: bio,
        country: country,
        city: city,
        currency: currency,
        isCreator: isCreator,
        photoUrl: photoUrl,
      );

      this.country = profile?.country ?? country;
      this.currency = profile?.currency ?? currency;
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      final text = e.toString();
      if (text.contains('object-not-found') ||
          text.contains('firebase_storage')) {
        errorMessage = 'profile.imageUnavailable';
      } else {
        errorMessage = text.trim().isEmpty ? 'profile.saveFailed' : text;
      }
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}
