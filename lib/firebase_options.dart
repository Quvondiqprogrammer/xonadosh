import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase options generated from google-services.json (project: inbaraka-f013d).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJK-VT45B6gnqt9m0BIRIeCQSW9NnrB2U',
    appId: '1:1062554549724:web:xonadosh-web',
    messagingSenderId: '1062554549724',
    projectId: 'inbaraka-f013d',
    storageBucket: 'inbaraka-f013d.firebasestorage.app',
    authDomain: 'inbaraka-f013d.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJK-VT45B6gnqt9m0BIRIeCQSW9NnrB2U',
    appId: '1:1062554549724:android:0e6b428c1d1d348696e319',
    messagingSenderId: '1062554549724',
    projectId: 'inbaraka-f013d',
    storageBucket: 'inbaraka-f013d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJK-VT45B6gnqt9m0BIRIeCQSW9NnrB2U',
    appId: '1:1062554549724:ios:0e6b428c1d1d348696e319',
    messagingSenderId: '1062554549724',
    projectId: 'inbaraka-f013d',
    storageBucket: 'inbaraka-f013d.firebasestorage.app',
    iosBundleId: 'uz.zargo.xonadosh',
  );
}
