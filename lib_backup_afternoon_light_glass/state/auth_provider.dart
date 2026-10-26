import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool isLoading = false;
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  Stream<User?> get authStateChanges => _repo.authStateChanges;
  User? get currentUser => _repo.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.signInWithEmail(email.trim(), password);
    } on FirebaseAuthException catch (e) {
      _events.add(e.message ?? 'Đăng nhập thất bại');
    } catch (_) {
      _events.add('Đăng nhập thất bại');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    _setLoading(true);
    try {
      await _repo.signUpWithEmail(email.trim(), password, fullName.trim());
    } on FirebaseAuthException catch (e) {
      _events.add(e.message ?? 'Đăng ký thất bại');
    } catch (_) {
      _events.add('Đăng ký thất bại');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _repo.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _events.add(e.message ?? 'Google Sign-In thất bại');
    } catch (_) {
      _events.add('Google Sign-In thất bại');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() => _repo.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _events.add('Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư.');
    } on FirebaseAuthException catch (e) {
      _events.add(e.message ?? 'Gửi email khôi phục thất bại');
    } catch (_) {
      _events.add('Gửi email khôi phục thất bại');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
