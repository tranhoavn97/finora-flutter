import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'supabase_bridge.dart';

/// Reference sharing only. No financial writes, imports or local membership.
class FamilySharingService {
  final http.Client _client;
  final Future<String> Function() _token;
  FamilySharingService({http.Client? client, Future<String> Function()? token})
      : _client = client ?? http.Client(),
        _token = token ?? _firebaseToken;

  static Future<String> _firebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('FAMILY_EMAIL_VERIFICATION_REQUIRED');
    final token = await user.getIdToken();
    if (token == null) throw StateError('FAMILY_EMAIL_VERIFICATION_REQUIRED');
    return token;
  }

  Future<Map<String, dynamic>> request(String action,
      [Map<String, dynamic> args = const {}]) async {
    final token = await _token();
    final response = await _client
        .post(
            Uri.parse(
                '${SupabaseBridge.supabaseUrl}/rest/v1/rpc/finora_family'),
            headers: {
              'apikey': SupabaseBridge.supabaseAnonKey,
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'p_action': action, 'p_args': args}))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(utf8.decode(response.bodyBytes));
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid family response');
    }
    final valid = action == 'ledger'
        ? data['transactions'] is List && data.containsKey('nextAfter')
        : data.containsKey('family') &&
            ['members', 'invitations', 'myWallets', 'sharedWallets']
                .every((key) => data[key] is List);
    if (!valid) {
      throw StateError('Invalid family response');
    }
    return data;
  }

  void close() => _client.close();

  static String errorText(Object error) {
    final text = error.toString();
    const messages = {
      'FAMILY_EMAIL_VERIFICATION_REQUIRED':
          'Hãy đăng nhập bằng email đã xác minh, sau đó đăng nhập lại để cập nhật phiên.',
      'FAMILY_OWNER_REQUIRED':
          'Chỉ chủ gia đình được quản lý lời mời và thành viên.',
      'FAMILY_INVALID_EMAIL':
          'Nhập email hợp lệ của người được mời, khác email của bạn.',
      'FAMILY_ALREADY_MEMBER': 'Email này đã là thành viên gia đình.',
      'FAMILY_FULL': 'Gia đình đã đủ 10 thành viên.',
      'FAMILY_TOO_MANY_INVITES': 'Hãy thu hồi lời mời cũ trước khi mời thêm.',
      'FAMILY_INVITE_INVALID':
          'Không tìm thấy lời mời dành cho email đang đăng nhập.',
      'FAMILY_INVITE_EXPIRED': 'Lời mời đã hết hạn hoặc đã được thu hồi.',
      'FAMILY_LEAVE_FIRST': 'Hãy rời nhóm hiện tại trước khi nhận lời mời này.',
      'FAMILY_NOT_JOINED':
          'Bạn chưa tham gia gia đình hoặc quyền đã bị thu hồi.',
      'FAMILY_OWNER_CANNOT_LEAVE':
          'Chủ gia đình chưa thể rời nhóm. Sổ riêng vẫn giữ nguyên.',
      'FAMILY_WALLET_NOT_FOUND':
          'Ví không tồn tại hoặc không thuộc tài khoản của bạn.',
    };
    for (final entry in messages.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    if (text.contains('PGRST202') ||
        text.contains('Could not find the function')) {
      return 'Máy chủ chưa được cập nhật tính năng gia đình. Dữ liệu cá nhân vẫn giữ nguyên.';
    }
    return 'Không kết nối được gia đình. Kiểm tra mạng và thử lại; chưa xác nhận thay đổi.';
  }
}
