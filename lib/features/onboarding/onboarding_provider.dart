import 'package:flutter/material.dart';

import 'onboarding_repository.dart';

class OnboardingProvider extends ChangeNotifier {
  final OnboardingRepository _repository = OnboardingRepository();

  int currentPage = 0;

  final PageController controller = PageController();

  void nextPage() {
    currentPage++;

    controller.nextPage(
      duration: const Duration(milliseconds: 300),

      curve: Curves.easeInOut,
    );

    notifyListeners();
  }

  void updatePage(int index) {
    currentPage = index;

    notifyListeners();
  }

  Future<void> finish() async {
    await _repository.complete();
  }
}
