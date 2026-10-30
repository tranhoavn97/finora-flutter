import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SupabaseBridge {
  static const String supabaseUrl = 'https://negbjqiyborkqqocdcgi.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_l1xHhumC2oy6vJvllJooyw_kO48FcLp';

  static bool get isConfigured => true;

  // StreamController bus to notify active streams of local writes/deletes immediately
  static final StreamController<String> _changeNotifier =
      StreamController<String>.broadcast();

  // Local cache per (userId:collection) to serve instant responses and fallbacks
  static final Map<String, List<Map<String, dynamic>>> _memoryCache = {};
  static final Map<String, _SharedCollectionWatch> _activeWatches = {};
  static bool _isForeground = true;
  static bool _observingLifecycle = false;
  static final WidgetsBindingObserver _lifecycleObserver =
      _CollectionLifecycleObserver();

  static void _observeLifecycle() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _observingLifecycle = true;
  }

  static void _setLifecycle(AppLifecycleState state) {
    final wasForeground = _isForeground;
    _isForeground = state != AppLifecycleState.hidden &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached;
    if (!wasForeground && _isForeground) {
      for (final watch in _activeWatches.values.toList()) {
        watch.refresh();
      }
    }
  }

  static String _cacheKey(String userId, String collection) =>
      '$userId:$collection';

  static String newDocumentId() {
    try {
      return const Uuid().v4();
    } catch (_) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }
  }

  static Future<String> _getAuthToken(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.');
    }
    final token = await user.getIdToken(false);
    if (token == null || token.isEmpty) {
      throw StateError(
          'Không lấy được phiên đăng nhập. Vui lòng đăng nhập lại.');
    }
    return token;
  }

  static Map<String, String> _buildHeaders(String token,
      {bool upsert = false}) {
    final headers = <String, String>{
      'apikey': supabaseAnonKey,
      'Content-Type': 'application/json',
    };
    headers['Authorization'] = 'Bearer $token';
    if (upsert) {
      headers['Prefer'] = 'resolution=merge-duplicates,return=minimal';
    }
    return headers;
  }

  static dynamic _toPortableJson(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is List) {
      return value.map(_toPortableJson).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toPortableJson(v)));
    }
    return value.toString();
  }

  /// Load documents for a given collection from Supabase `finora_active_documents`.
  static Future<List<Map<String, dynamic>>> loadUserCollection({
    required String userId,
    required String collection,
    bool includeDeleted = false,
  }) async {
    if (userId.trim().isEmpty) throw StateError('Thiếu tài khoản đăng nhập.');

    final token = await _getAuthToken(userId);
    final table =
        includeDeleted ? 'finora_documents' : 'finora_active_documents';
    const pageSize = 1000;
    final results = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += pageSize) {
      final uri =
          Uri.parse('$supabaseUrl/rest/v1/$table').replace(queryParameters: {
        'scope_kind': 'eq.user',
        'scope_id': 'eq.$userId',
        'collection_name': 'eq.$collection',
        if (includeDeleted) 'is_deleted': 'eq.true',
        'select': 'document_id,data',
        'order': 'document_id.asc',
        'limit': '$pageSize',
        'offset': '$offset',
      });
      final response = await http
          .get(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Không thể tải $collection (${response.statusCode}).');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List)
        throw StateError('Dữ liệu $collection không hợp lệ.');
      for (final row in decoded) {
        if (row is Map) {
          final docId = row['document_id']?.toString() ?? '';
          final docData = row['data'];
          final item = docData is Map
              ? Map<String, dynamic>.from(docData)
              : <String, dynamic>{};
          item['id'] = docId;
          if (includeDeleted) item['_isDeleted'] = true;
          results.add(item);
        }
      }
      if (decoded.length < pageSize) break;
    }
    if (!includeDeleted) {
      _memoryCache[_cacheKey(userId, collection)] = results;
    }
    return results;
  }

  /// Share one fetch per user/collection across all providers. Local writes and
  /// returning to the app refresh immediately; foreground polling is a fallback.
  static Stream<List<Map<String, dynamic>>> watchUserCollection({
    required String userId,
    required String collection,
    Duration interval = const Duration(minutes: 5),
  }) {
    return Stream.multi((listener) {
      _observeLifecycle();
      final key = _cacheKey(userId, collection);
      final watch = _activeWatches.putIfAbsent(
          key, () => _SharedCollectionWatch(userId, collection, interval));
      // Every new subscriber gets the latest value, even if it joins after
      // another screen has already completed the shared request.
      final cached = _memoryCache[key];
      if (cached != null) listener.add(cached);
      final sub =
          watch.events.stream.listen(listener.add, onError: listener.addError);
      watch.listeners++;
      if (watch.listeners == 1) watch.start();
      listener.onCancel = () {
        sub.cancel();
        watch.listeners--;
        if (watch.listeners == 0) {
          watch.stop();
          _activeWatches.remove(key);
        }
      };
    });
  }

  /// Save or update a document in Supabase `finora_documents`.
  static Future<void> saveUserDocument({
    required String userId,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool deleted = false,
    bool replace = false,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    if (userId == 'demo' || userId.trim().isEmpty) {
      throw StateError('Vui lòng đăng nhập để lưu dữ liệu.');
    }
    final token = await _getAuthToken(userId);
    Map<String, dynamic> existingData = {};
    if (!replace) {
      final readUri = Uri.parse('$supabaseUrl/rest/v1/finora_documents')
          .replace(queryParameters: {
        'scope_kind': 'eq.user',
        'scope_id': 'eq.$userId',
        'collection_name': 'eq.$collection',
        'document_id': 'eq.$documentId',
        'select': 'data',
        'limit': '1',
      });
      final readResponse = await http
          .get(readUri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 8));
      if (readResponse.statusCode < 200 || readResponse.statusCode >= 300) {
        throw StateError(
            'Không thể kiểm tra dữ liệu trước khi lưu (${readResponse.statusCode}).');
      }
      final rows = jsonDecode(utf8.decode(readResponse.bodyBytes));
      if (rows is! List) throw StateError('Dữ liệu hiện tại không hợp lệ.');
      if (rows.isNotEmpty && rows.first is Map && rows.first['data'] is Map) {
        existingData = Map<String, dynamic>.from(rows.first['data']);
      }
    }
    final mergedPayload = Map<String, dynamic>.from(existingData)
      ..addAll(data)
      ..['updatedAt'] = data['updatedAt'] ?? nowIso;
    mergedPayload['id'] = documentId;

    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/finora_documents?on_conflict=scope_kind,scope_id,collection_name,document_id',
    );

    final payload = {
      'scope_kind': 'user',
      'scope_id': userId,
      'owner_uid': userId,
      'collection_name': collection,
      'document_id': documentId,
      'data': _toPortableJson(mergedPayload),
      'is_deleted': deleted,
      'source_updated_at': nowIso,
      'mirrored_at': nowIso,
    };

    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token, upsert: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Không thể lưu $collection (${response.statusCode}).');
    }
    final key = _cacheKey(userId, collection);
    final cacheList = List<Map<String, dynamic>>.from(_memoryCache[key] ?? []);
    final existingIdx = cacheList.indexWhere((e) => e['id'] == documentId);
    if (existingIdx >= 0) cacheList.removeAt(existingIdx);
    if (!deleted) cacheList.insert(0, mergedPayload);
    _memoryCache[key] = cacheList;
    _changeNotifier.add(key);
  }

  /// Soft delete a document in Supabase `finora_documents`.
  static Future<void> deleteUserDocument({
    required String userId,
    required String collection,
    required String documentId,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final patch = {
      'deletedAt': nowIso,
      'deletedBy': userId,
      'purgeAfter': DateTime.now().millisecondsSinceEpoch + (30 * 86400000),
    };
    await saveUserDocument(
      userId: userId,
      collection: collection,
      documentId: documentId,
      data: patch,
      deleted: true,
    );
  }

  /// Permanently remove an already deleted document after an explicit purge.
  static Future<void> purgeUserDocument({
    required String userId,
    required String collection,
    required String documentId,
  }) async {
    final token = await _getAuthToken(userId);
    final uri = Uri.parse('$supabaseUrl/rest/v1/finora_documents').replace(
      queryParameters: {
        'scope_kind': 'eq.user',
        'scope_id': 'eq.$userId',
        'collection_name': 'eq.$collection',
        'document_id': 'eq.$documentId',
        'is_deleted': 'eq.true',
      },
    );
    final response = await http
        .delete(uri, headers: _buildHeaders(token))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Không thể xóa vĩnh viễn $collection (${response.statusCode}).');
    }
    _changeNotifier.add(_cacheKey(userId, collection));
  }

  /// Commit related document changes in one database transaction.
  static Future<void> mutateUserDocuments({
    required String userId,
    required List<Map<String, dynamic>> operations,
  }) async {
    if (operations.isEmpty) return;
    final token = await _getAuthToken(userId);
    for (final operation in operations) {
      if ((operation['collection_name']?.toString() ?? '').isEmpty ||
          (operation['document_id']?.toString() ?? '').isEmpty ||
          operation['data'] is! Map) {
        throw ArgumentError('Thao tác dữ liệu không hợp lệ.');
      }
    }
    final uri = Uri.parse('$supabaseUrl/rest/v1/rpc/mutate_finora_documents');
    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: jsonEncode({'p_operations': _toPortableJson(operations)}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Không thể hoàn tất thao tác tài chính (${response.statusCode}).');
    }
    for (final collection
        in operations.map((op) => op['collection_name'].toString()).toSet()) {
      final key = _cacheKey(userId, collection);
      _memoryCache.remove(key);
      _changeNotifier.add(key);
    }
  }

  /// Upload category icon to Supabase Storage bucket `category-icons`.
  static Future<List<String>> listCategoryIcons(
      {required String userId}) async {
    final token = await _getAuthToken(userId);
    final uri = Uri.parse('$supabaseUrl/storage/v1/object/list/category-icons');
    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: jsonEncode({
            'prefix': '$userId/',
            'limit': 100,
            'offset': 0,
            'sortBy': {'column': 'created_at', 'order': 'desc'},
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Không tải được ảnh đã lưu (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw StateError('Danh sách ảnh không hợp lệ.');
    return decoded
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty && !name.contains('/'))
        .map((name) =>
            '$supabaseUrl/storage/v1/object/public/category-icons/$userId/${Uri.encodeComponent(name)}')
        .toList();
  }

  static Future<String?> uploadCategoryIcon({
    required String userId,
    required XFile image,
  }) async {
    {
      final token = await _getAuthToken(userId);
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final safeExt =
          (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'webp';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4()}.$safeExt';
      final objectPath = '$userId/$fileName';

      final uri = Uri.parse(
          '$supabaseUrl/storage/v1/object/category-icons/$objectPath');
      final headers = <String, String>{
        'apikey': supabaseAnonKey,
        'Content-Type': 'image/$safeExt',
        'Cache-Control': 'max-age=31536000',
      };
      headers['Authorization'] = 'Bearer $token';

      final response = await http
          .post(uri, headers: headers, body: bytes)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return '$supabaseUrl/storage/v1/object/public/category-icons/$objectPath';
      }
      throw StateError(
          'Tải ảnh thất bại (${response.statusCode}): ${response.body}');
    }
  }
}

class _CollectionLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SupabaseBridge._setLifecycle(state);
  }
}

class _SharedCollectionWatch {
  final String userId;
  final String collection;
  final Duration interval;
  final events = StreamController<List<Map<String, dynamic>>>.broadcast();
  Timer? _timer;
  StreamSubscription<String>? _changes;
  bool _fetching = false;
  bool _refreshAfterFetch = false;
  bool _stopped = false;
  int listeners = 0;

  _SharedCollectionWatch(this.userId, this.collection, this.interval);

  void start() {
    refresh();
    _timer = Timer.periodic(interval, (_) {
      if (SupabaseBridge._isForeground) refresh();
    });
    final key = SupabaseBridge._cacheKey(userId, collection);
    _changes = SupabaseBridge._changeNotifier.stream.listen((changedKey) {
      if (changedKey != key) return;
      final cached = SupabaseBridge._memoryCache[key];
      if (cached != null && !events.isClosed) events.add(cached);
      refresh(afterCurrent: true);
    });
  }

  Future<void> refresh({bool afterCurrent = false}) async {
    if (_stopped) return;
    if (_fetching) {
      if (afterCurrent) _refreshAfterFetch = true;
      return;
    }
    _fetching = true;
    try {
      final rows = await SupabaseBridge.loadUserCollection(
          userId: userId, collection: collection);
      if (!_stopped && !events.isClosed) events.add(rows);
    } catch (error, stack) {
      if (!_stopped && !events.isClosed) events.addError(error, stack);
    } finally {
      _fetching = false;
      if (_refreshAfterFetch && !_stopped) {
        _refreshAfterFetch = false;
        refresh();
      }
    }
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _changes?.cancel();
    events.close();
  }
}
