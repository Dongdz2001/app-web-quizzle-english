/// Firebase configuration for Quizzle English App
/// 
/// This file contains Firebase configuration constants.
/// For Flutter web, Firebase is initialized using these values.

class FirebaseConfig {
  // Firebase configuration values
  static const String apiKey = "AIzaSyCmtt2y93m4_cfOHRHKuOnlzuCY_hMJHoQ";
  static const String authDomain = "quizzle-app-english.firebaseapp.com";
  static const String projectId = "quizzle-app-english";
  static const String storageBucket = "quizzle-app-english.firebasestorage.app";
  static const String messagingSenderId = "883676761076";
  static const String appId = "1:883676761076:web:25dbf9a0ab3bf5d05687a1";
  static const String measurementId = "G-RS2F8HC6YY";

  /// Get Firebase options for web platform
  /// 
  /// Returns a map containing Firebase configuration options
  /// compatible with Flutter Firebase SDK
  static Map<String, String> get webOptions => {
        'apiKey': apiKey,
        'authDomain': authDomain,
        'projectId': projectId,
        'storageBucket': storageBucket,
        'messagingSenderId': messagingSenderId,
        'appId': appId,
        'measurementId': measurementId,
      };
}
