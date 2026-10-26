import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Public-client bridge used during the staged Firebase -> Supabase migration.
/// Never configure this class with a Supabase service-role or secret key.
class SupabaseBridge {
  SupabaseBridge._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gtlcfquglrtgdxfegrlh.supabase.co',
  );
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_bpEDGtDN8rJIHoJf3eJsEA_nbfMyUhI',
  );

  static bool get isConfigured =>
      _url.trim().isNotEmpty && _publishableKey.trim().isNotEmpty;

  static Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(false);
    if (user == null || token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không hợp lệ.');
    }
    return {
      'apikey': _publishableKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static dynamic _portableJson(dynamic value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) {
      return value
          .map((key, item) => MapEntry(key.toString(), _portableJson(item)));
    }
    if (value is Iterable) return value.map(_portableJson).toList();
    return value;
  }

  /// Mirrors an authoritative Firestore document into Supabase. Migration
  /// failures deliberately do not invalidate a successful Firebase write.
  static Future<bool> mirrorUserDocument({
    required String userId,
    required String collection,
    required String documentId,
    Map<String, dynamic>? data,
    bool deleted = false,
  }) async {
    if (!isConfigured) return false;
    try {
      final headers = await _authHeaders();
      if (FirebaseAuth.instance.currentUser?.uid != userId) return false;
      final baseUrl = _url.replaceFirst(RegExp(r'/+$'), '');
      final portable =
          _portableJson(data ?? <String, dynamic>{}) as Map<String, dynamic>;
      final updatedAt = portable['updatedAt'];
      final response = await http.post(
        Uri.parse(
          '$baseUrl/rest/v1/finora_documents?on_conflict=scope_kind,scope_id,collection_name,document_id',
        ),
        headers: {
          ...headers,
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: jsonEncode({
          'scope_kind': 'user',
          'scope_id': userId,
          'collection_name': collection,
          'document_id': documentId,
          'owner_uid': userId,
          'data': portable,
          'is_deleted': deleted,
          if (updatedAt is String) 'source_updated_at': updatedAt,
          'mirrored_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> loadUserCollection({
    required String userId,
    required String collection,
    bool includeDeleted = false,
  }) async {
    final headers = await _authHeaders();
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      throw StateError('Phiên đăng nhập không hợp lệ.');
    }
    final baseUrl = _url.replaceFirst(RegExp(r'/+$'), '');
    final deletedFilter = includeDeleted ? '' : '&is_deleted=eq.false';
    final uri = Uri.parse(
      '$baseUrl/rest/v1/finora_documents?select=document_id,data,is_deleted'
      '&scope_kind=eq.user&scope_id=eq.${Uri.encodeQueryComponent(userId)}'
      '&collection_name=eq.${Uri.encodeQueryComponent(collection)}$deletedFilter',
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Không tải được $collection từ Supabase (${response.statusCode}).');
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    return rows
        .map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);
          final data = row['data'] is Map
              ? Map<String, dynamic>.from(row['data'] as Map)
              : <String, dynamic>{};
          return <String, dynamic>{
            'id': row['document_id']?.toString() ?? '',
            ...data,
            if (includeDeleted) '_isDeleted': row['is_deleted'] == true,
          };
        })
        .where((row) => (row['id'] as String).isNotEmpty)
        .toList();
  }

  static Stream<List<Map<String, dynamic>>> watchUserCollection({
    required String userId,
    required String collection,
    Duration interval = const Duration(seconds: 3),
  }) {
    late StreamController<List<Map<String, dynamic>>> controller;
    Timer? timer;
    var running = false;
    var lastPayload = '';
    Future<void> refresh() async {
      if (running || controller.isClosed) return;
      running = true;
      try {
        final rows =
            await loadUserCollection(userId: userId, collection: collection);
        final signature = jsonEncode(rows);
        if (signature != lastPayload && !controller.isClosed) {
          lastPayload = signature;
          controller.add(rows);
        }
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      } finally {
        running = false;
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        unawaited(refresh());
        timer = Timer.periodic(interval, (_) => unawaited(refresh()));
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  static String newDocumentId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${FirebaseAuth.instance.currentUser?.uid.hashCode.abs() ?? 0}';

  static Future<void> saveUserDocument({
    required String userId,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool deleted = false,
    bool replace = false,
  }) async {
    Map<String, dynamic> payload = data;
    if (!replace) {
      final rows = await loadUserCollection(
        userId: userId,
        collection: collection,
        includeDeleted: true,
      );
      final existing = rows.where((row) => row['id'] == documentId).firstOrNull;
      if (existing != null) {
        payload = {...existing}
          ..remove('id')
          ..remove('_isDeleted');
        payload.addAll(data);
      }
    }
    final ok = await mirrorUserDocument(
      userId: userId,
      collection: collection,
      documentId: documentId,
      data: payload,
      deleted: deleted,
    );
    if (!ok) throw StateError('Không thể lưu dữ liệu lên Supabase.');
  }

  static Future<void> deleteUserDocument({
    required String userId,
    required String collection,
    required String documentId,
  }) =>
      saveUserDocument(
        userId: userId,
        collection: collection,
        documentId: documentId,
        deleted: true,
        data: {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
          'deletedBy': userId,
          'purgeAfter': DateTime.now()
              .add(const Duration(days: 30))
              .millisecondsSinceEpoch,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

  static Future<String?> uploadCategoryIcon({
    required String userId,
    required XFile image,
  }) async {
    if (!isConfigured) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('Phiên đăng nhập không hợp lệ.');
    }
    final token = await user.getIdToken(false);
    if (token == null || token.isEmpty) {
      throw StateError('Không lấy được mã xác thực Firebase.');
    }

    final rawExtension = image.name.split('.').last.toLowerCase();
    final extension =
        const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(rawExtension)
            ? rawExtension
            : 'jpg';
    final objectName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final objectPath = '$userId/$objectName';
    final encodedPath =
        objectPath.split('/').map(Uri.encodeComponent).join('/');
    final baseUrl = _url.replaceFirst(RegExp(r'/+$'), '');
    final response = await http.post(
      Uri.parse('$baseUrl/storage/v1/object/category-icons/$encodedPath'),
      headers: {
        'apikey': _publishableKey,
        'Authorization': 'Bearer $token',
        'Content-Type': image.mimeType ?? 'image/$extension',
        'x-upsert': 'false',
        'cache-control': 'max-age=31536000',
      },
      body: await image.readAsBytes(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Supabase Storage trả về ${response.statusCode}.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message =
            body['message']?.toString() ?? body['error']?.toString() ?? message;
      } catch (_) {}
      throw StateError(message);
    }
    return '$baseUrl/storage/v1/object/public/category-icons/$encodedPath';
  }
}
