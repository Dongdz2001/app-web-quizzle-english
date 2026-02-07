import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_config.dart';

/// Initialize Firebase for the app
/// 
/// This function should be called before running the app
/// to initialize Firebase services.
Future<void> initializeFirebase() async {
  try {
    // Initialize Firebase with web options
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        appId: FirebaseConfig.appId,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        projectId: FirebaseConfig.projectId,
        authDomain: FirebaseConfig.authDomain,
        storageBucket: FirebaseConfig.storageBucket,
        measurementId: FirebaseConfig.measurementId,
      ),
    );
    
    // Initialize Analytics
    FirebaseAnalytics.instance;
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow;
  }
}

/// Get Firebase Analytics instance
FirebaseAnalytics getAnalytics() {
  return FirebaseAnalytics.instance;
}
