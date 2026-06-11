import 'package:firebase_core/firebase_core.dart';

/// Default Firebase configuration.
///
/// Replace these values with your Firebase project's configuration.
/// To get these values:
///   1. Go to https://console.firebase.google.com
///   2. Create a project (or use existing)
///   3. Add Android app (package: com.safeapartment.app)
///   4. Download google-services.json
///   5. iOS: Add app (bundle: com.safeapartment.app)
///   6. Download GoogleService-Info.plist
///   7. Or run: flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (isAndroid) return android;
    if (isIOS) return ios;
    return android;
  }

  static const bool isAndroid = true; // Set based on platform
  static const bool isIOS = false;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'safeapartment-12345',
    storageBucket: 'safeapartment-12345.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'safeapartment-12345',
    storageBucket: 'safeapartment-12345.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.safeapartment.app',
  );
}
