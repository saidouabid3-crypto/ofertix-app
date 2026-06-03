import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // API
  static String get apiUrl => dotenv.env['API_URL'] ?? '';

  // AI — frontend must call backend only; keys are not required in Flutter
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static String get groqApiUrl => dotenv.env['GROQ_API_URL'] ?? '';

  // Firebase
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  // Notifications
  static String get oneSignalAppId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  // Affiliate
  static String get amazonTag => dotenv.env['AMAZON_AFFILIATE_TAG'] ?? '';

  static String get aliexpressKey => dotenv.env['ALIEXPRESS_API_KEY'] ?? '';
}
