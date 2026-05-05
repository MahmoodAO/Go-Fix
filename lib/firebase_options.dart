import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSQrkYtlxxbnpeudTVMpXIsAZ-qb-InI4',
    appId: '1:78476996161:web:6cf29f6b03846c19f1e0c0',
    messagingSenderId: '78476996161',
    projectId: 'homemate-app-9aa9a',
    authDomain: 'homemate-app-9aa9a.firebaseapp.com',
    storageBucket: 'homemate-app-9aa9a.firebasestorage.app',
    measurementId: 'G-VYHHR060PB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpDrM0P8WWRaArJQGbsf0M21ny2ia1QjM',
    appId: '1:78476996161:android:c7245d481d9058c9f1e0c0',
    messagingSenderId: '78476996161',
    projectId: 'homemate-app-9aa9a',
    storageBucket: 'homemate-app-9aa9a.firebasestorage.app',
  );
}
