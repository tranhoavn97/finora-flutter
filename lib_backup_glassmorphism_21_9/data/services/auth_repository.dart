import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'supabase_bridge.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await _syncProfile(user);
    return user;
  }

  Future<User> signUpWithEmail(String email, String password, String fullName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    if (fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
    }
    await _syncProfile(user, fullName: fullName);
    return user;
  }

  Future<User> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final cred = await _auth.signInWithPopup(googleProvider);
      final user = cred.user!;
      await _syncProfile(user);
      return user;
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'cancelled', message: 'Đăng nhập đã bị hủy');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user!;
      await _syncProfile(user);
      return user;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> _syncProfile(User user, {String? fullName}) async {
    try {
      final name = (fullName != null && fullName.isNotEmpty)
          ? fullName
          : (user.displayName ?? (user.email?.split('@').first ?? ''));
      final data = {
        'email': user.email ?? '',
        'fullName': name,
        'profileImageUrl': user.photoURL ?? '',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await SupabaseBridge.saveUserDocument(
        userId: user.uid,
        collection: 'profiles',
        documentId: user.uid,
        data: {...data, 'createdAt': DateTime.now().millisecondsSinceEpoch},
      );
    } catch (_) {
      // Profile synchronization must not prevent Firebase Authentication login.
    }
  }
}
