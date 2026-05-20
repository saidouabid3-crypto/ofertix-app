class NotificationPermission {
  static Future<bool> request() async {
    // Firebase Messaging يطلب الإذن حالياً داخل NotificationService
    return true;
  }
}
