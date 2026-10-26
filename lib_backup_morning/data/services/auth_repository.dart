import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339',
  );

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

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> _syncProfile(User user, {String? fullName}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (user.displayName ?? (user.email?.split('@').first ?? ''));
    final data = {
      'email': user.email ?? '',
      'fullName': name,
      'profileImageUrl': user.photoURL ?? '',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (!snap.exists) {
      await ref.set({...data, 'createdAt': DateTime.now().millisecondsSinceEpoch});
    } else {
      await ref.update(data);
    }
  }
}
