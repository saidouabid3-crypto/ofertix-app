import '../../core/storage/local_storage.dart';

class OnboardingRepository {
  Future<void> complete() async {
    await LocalStorage.setBool('onboarding_completed', true);
  }

  Future<bool> isCompleted() async {
    return await LocalStorage.getBool('onboarding_completed') ?? false;
  }
}
