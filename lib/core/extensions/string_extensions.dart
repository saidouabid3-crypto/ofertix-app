extension StringExtensions on String {
  bool get isEmail {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trim());
  }

  bool get isStrongPassword {
    return trim().length >= 6;
  }

  String get clean {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
