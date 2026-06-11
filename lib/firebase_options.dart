import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (isAndroid) return android;
    if (isIOS) return ios;
    return android;
  }

  static const bool isAndroid = true;
  static const bool isIOS = false;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFgGc1dnP7NYDG1ui_31XeVJCi61SqeCE',
    appId: '1:2767604632:android:7d2661dea2e3d65a0d79ed',
    messagingSenderId: '2767604632',
    projectId: 'applica-8990f',
    storageBucket: 'applica-8990f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFgGc1dnP7NYDG1ui_31XeVJCi61SqeCE',
    appId: '1:2767604632:android:7d2661dea2e3d65a0d79ed',
    messagingSenderId: '2767604632',
    projectId: 'applica-8990f',
    storageBucket: 'applica-8990f.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.safeapartment.app',
  );
}
