import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool isLoading = false;
  String? lastError;
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  Stream<User?> get authStateChanges => _repo.authStateChanges;
  User? get currentUser => _repo.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    clearError();
    _setLoading(true);
    try {
      await _repo.signInWithEmail(email.trim(), password);
    } on FirebaseAuthException catch (e) {
      _reportError(e);
    } catch (e) {
      _setError('Đăng nhập thất bại. Vui lòng thử lại hoặc dùng Google.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    clearError();
    _setLoading(true);
    try {
      await _repo.signUpWithEmail(email.trim(), password, fullName.trim());
    } on FirebaseAuthException catch (e) {
      _reportError(e);
    } catch (e) {
      _setError('Đăng ký thất bại. Vui lòng thử lại.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    clearError();
    _setLoading(true);
    try {
      await _repo.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _reportError(e);
    } catch (e) {
      _setError('Đăng nhập Google thất bại. Vui lòng thử lại trên trình duyệt hỗ trợ cửa sổ bật lên.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously() async {
    clearError();
    _setLoading(true);
    try {
      await _repo.signInAnonymously();
    } catch (e) {
      _setError('Không thể kích hoạt chế độ khách. Vui lòng thử lại.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() => _repo.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    clearError();
    _setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _events.add('Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư.');
    } on FirebaseAuthException catch (e) {
      _reportError(e);
    } catch (e) {
      _setError('Không gửi được email khôi phục. Vui lòng thử lại.');
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
        return 'Cửa sổ Google đã đóng trước khi hoàn tất. Nếu cửa sổ trắng rồi tự đóng, hãy mở localhost trong Chrome hoặc Edge để đăng nhập.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ Google. Hãy cho phép popup hoặc mở localhost trong Chrome hoặc Edge.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trong Firebase.';
      case 'unauthorized-domain':
        return 'localhost chưa được cấp quyền đăng nhập trong Firebase Authentication.';
      case 'too-many-requests':
        return 'Có quá nhiều lần thử đăng nhập. Vui lòng đợi rồi thử lại.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Cấu hình Firebase của bản web không hợp lệ.';
      case 'cancelled':
        return 'Đăng nhập Google đã bị hủy.';
      default:
        return '${e.message ?? 'Đăng nhập thất bại'} (${e.code})';
    }
  }

  void clearError() {
    if (lastError == null) return;
    lastError = null;
    notifyListeners();
  }

  void _reportError(FirebaseAuthException error) => _setError(_mapAuthError(error));

  void _setError(String message) {
    lastError = message;
    _events.add(message);
    notifyListeners();
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
