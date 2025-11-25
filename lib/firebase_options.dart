import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqQ5VG7oM9JEd617WWtnDatQ13iJz91Qw',
    authDomain: 'p22rently.firebaseapp.com',
    projectId: 'p22rently',
    storageBucket: 'p22rently.firebasestorage.app',
    messagingSenderId: '1030223891349',
    appId: '1:1030223891349:web:b1ab7594364646f239c49c',
    measurementId: 'G-0HEM07W7YQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCY4TJk_b1EzgPfF1-DEjCtn7y3DUxiHpw',
    appId: '1:1030223891349:android:9d80ec1f41de8dea39c49c',
    messagingSenderId: '1030223891349',
    projectId: 'p22rently',
    storageBucket: 'p22rently.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHQlvWwv9d0wqxLwxqs_-6iydwg7OqR80',
    appId: '1:1030223891349:ios:65b08b966083f56739c49c',
    messagingSenderId: '1030223891349',
    projectId: 'p22rently',
    storageBucket: 'p22rently.firebasestorage.app',
    iosBundleId: 'com.example.p2',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAqQ5VG7oM9JEd617WWtnDatQ13iJz91Qw',
    appId: '1:1030223891349:web:b1ab7594364646f239c49c',
    messagingSenderId: '1030223891349',
    projectId: 'p22rently',
    storageBucket: 'p22rently.firebasestorage.app',
  );
}
