import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // API
  static String apiUrl = dotenv.env['API_URL'] ?? '';

  // AI
  static String groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  static String groqApiUrl = dotenv.env['GROQ_API_URL'] ?? '';

  // Firebase
  static String firebaseProjectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  // Notifications
  static String oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  // Affiliate
  static String amazonTag = dotenv.env['AMAZON_AFFILIATE_TAG'] ?? '';

  static String aliexpressKey = dotenv.env['ALIEXPRESS_API_KEY'] ?? '';
}
