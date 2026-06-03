import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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
    required String currency,
    required bool isCreator,
    XFile? image,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseProfile = profile ?? await _profileService.createProfileIfMissing();
      if (baseProfile == null) {
        throw Exception('No authenticated user found.');
      }

      String? photoUrl;
      if (image != null) {
        photoUrl = await _profileService.uploadProfileImage(
          uid: baseProfile.uid,
          image: image,
        );
      }

      profile = await _profileService.updateProfile(
        profile: baseProfile,
        displayName: displayName,
        username: username,
        bio: bio,
        country: country,
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
      errorMessage = e.toString();
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}
