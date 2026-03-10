// File generated manually to bypass broken Firebase CLI
// Project: SojournBeta (sojournbeta)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_api_key_for_sojournbeta', // Will need to be replaced with actual key if Auth is used, but for Firestore it often works with the google-services.json
    appId: '1:652607774222:android:0000000000000000000000',
    messagingSenderId: '652607774222',
    projectId: 'sojournbeta',
    storageBucket: 'sojournbeta.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_api_key_for_sojournbeta',
    appId: '1:652607774222:ios:0000000000000000000000',
    messagingSenderId: '652607774222',
    projectId: 'sojournbeta',
    storageBucket: 'sojournbeta.appspot.com',
    iosBundleId: 'com.example.projetSejour',
  );
}
