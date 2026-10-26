import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options for platforms that cannot read native config files.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (!kIsWeb) return null;
    return web;
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyA8LIrAoisLdtNepRXYuQ327nhpxmfguvo',
    appId: '1:264825318501:web:b30281befc1e09da026a8c',
    messagingSenderId: '264825318501',
    projectId: 'gen-lang-client-0843862000',
    authDomain: 'gen-lang-client-0843862000.firebaseapp.com',
    storageBucket: 'gen-lang-client-0843862000.firebasestorage.app',
  );
}
