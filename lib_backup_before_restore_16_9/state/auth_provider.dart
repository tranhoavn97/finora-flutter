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
      _events.add(_mapAuthError(e));
    } catch (e) {
      _events.add('Đăng nhập thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    _setLoading(true);
    try {
      await _repo.signUpWithEmail(email.trim(), password, fullName.trim());
    } on FirebaseAuthException catch (e) {
      _events.add(_mapAuthError(e));
    } catch (e) {
      _events.add('Đăng ký thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _repo.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _events.add(_mapAuthError(e));
    } catch (e) {
      _events.add('Google Sign-In thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously() async {
    _setLoading(true);
    try {
      await _repo.signInAnonymously();
    } catch (e) {
      _events.add('Đăng nhập dùng thử thất bại: ${e.toString()}');
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
      _events.add(_mapAuthError(e));
    } catch (e) {
      _events.add('Gửi email khôi phục thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email hoặc mật khẩu không chính xác. Nếu bạn đã dùng Google để đăng nhập trước đó, vui lòng bấm "Đăng nhập với Google".';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký tài khoản. Vui lòng chuyển sang tab Đăng nhập.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá ngắn hoặc quá yếu (tối thiểu 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị tạm khóa.';
      case 'popup-closed-by-user':
        return 'Cửa sổ đăng nhập Google đã đóng trước khi hoàn tất.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ bật lên. Vui lòng cấp quyền popup cho trang.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền.';
      case 'cancelled':
        return 'Đăng nhập Google đã bị hủy.';
      default:
        return e.message ?? 'Đăng nhập thất bại (${e.code})';
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
