import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bank_notification_cloud_sync.dart';
import 'bank_notification_parser.dart';
import 'bank_notification_source.dart';

/// Native queue is the durable source of truth on Android, mirrored bidirectionally
/// to Supabase `finora_documents` (`collection_name = 'bankNotifications'`) so
/// Web and Mobile stay in sync (pending queue, ending balance, and imported status).
/// Also supports pair-matching internal transfers on the same phone (1 expense + 1 income
/// of the exact same amount within 3 minutes across two banks/wallets) and manual/Web parsing.
class BankSyncService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.finora/bank_sync');
  static final BankSyncService _instance = BankSyncService._internal();
  factory BankSyncService() => _instance;
  BankSyncService._internal();

  final _inboxRequests = StreamController<void>.broadcast();
  Stream<void> get onInboxRequested => _inboxRequests.stream;

  final _launchActions = StreamController<String>.broadcast();
  Stream<String> get onLaunchAction => _launchActions.stream;

  final _events = StreamController<ParsedBankTransaction>.broadcast();
  Stream<ParsedBankTransaction> get onTransactionDetected => _events.stream;

  final Map<String, ParsedBankTransaction> _pending = {};
  final Map<String, ({String title, String text})> _unrecognized = {};
  final Map<String, CloudBankNotification> _cloudDocs = {};
  final Set<String> _nativeSeenIds = {};
  final Set<String> _remoteOnlyIds = {};
  final Set<String> _inFlightCloudPushes = {};

  BankNotificationCloudAdapter _cloudAdapter =
      const SupabaseBankNotificationAdapter();
  String? _boundUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _cloudSub;
  bool _cloudSyncing = false;

  Map<String, ({String title, String text})> get unrecognized =>
      Map.unmodifiable(_unrecognized);
  List<ParsedBankTransaction> get pending {
    final list = _pending.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  /// Recent imported notifications synced from Phone or Web (newest first).
  List<CloudBankNotification> get importedHistory {
    final list = _cloudDocs.values.where((d) => d.isImported).toList()
      ..sort((a, b) =>
          (b.importedAtMs ?? b.timestampMs)
              .compareTo(a.importedAtMs ?? a.timestampMs));
    return List.unmodifiable(list.take(50));
  }

  String? get boundUserId => _boundUserId;
  bool get isCloudBound => _boundUserId != null && _boundUserId!.isNotEmpty;

  CloudBankNotification? cloudRecordFor(String rawId) => _cloudDocs[rawId];
  bool isAlreadyImported(String rawId) => _cloudDocs[rawId]?.isImported == true;
  bool isFromWeb(String rawId) =>
      rawId.startsWith('web_') || _cloudDocs[rawId]?.isFromWeb == true;

  bool _isNonNativeId(String id) =>
      id.startsWith('manual_') ||
      id.startsWith('web_') ||
      (_remoteOnlyIds.contains(id) && !_nativeSeenIds.contains(id));

  int get manualPendingCount =>
      _pending.keys.where(_isNonNativeId).length +
      _unrecognized.keys.where(_isNonNativeId).length;
  int get unrecognizedCount => _unrecognized.length;
  int _unreadActivityCount = 0;
  int get unreadActivityCount => _unreadActivityCount;
  int get totalBadgeCount =>
      _pending.length + _unrecognized.length + _unreadActivityCount;
  bool connected = false;
  DateTime? lastReceivedAt;
  String? error;
  bool _initialized = false;
  bool _polling = false;
  final Set<String> _autoPrompted = {};
  static const _promptHistoryKey = 'finora_bank_auto_prompted_v1';
  bool wasAutoPrompted(String id) => _autoPrompted.contains(id);
  Future<void> markAutoPrompted(String id) async {
    _autoPrompted.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_promptHistoryKey, _autoPrompted.toList());
    } catch (_) {/* Keep the in-memory guard even if device storage fails. */}
  }

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  void setCloudAdapterForTest(BankNotificationCloudAdapter? adapter) {
    _cloudAdapter = adapter ?? const SupabaseBankNotificationAdapter();
  }

  @visibleForTesting
  Future<void> resetCloudStateForTest() async {
    await _cloudSub?.cancel();
    _cloudSub = null;
    _boundUserId = null;
    _cloudDocs.clear();
    _nativeSeenIds.clear();
    _remoteOnlyIds.clear();
    _inFlightCloudPushes.clear();
    _pending.clear();
    _unrecognized.clear();
    _cloudAdapter = const SupabaseBankNotificationAdapter();
    notifyListeners();
  }

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'openBankInbox') {
          await _consumeInboxRequest();
        }
        if (call.method == 'onLaunchAction' && call.arguments is String) {
          final action = (call.arguments as String).trim();
          if (action.isNotEmpty) {
            _launchActions.add(action);
          }
        }
        if (call.method == 'onBankNotification' && call.arguments is String) {
          _processRawJson(call.arguments as String);
        }
        if (call.method == 'onSyncStatusChanged' && call.arguments is Map) {
          final map = call.arguments as Map;
          connected = map['connected'] == true;
          notifyListeners();
        }
      });
    }
    await loadScanSettings();
    await checkPendingNotifications();
    await _consumeInboxRequest();
    await consumeLaunchAction();
  }

  /// Bind cloud sync to the signed-in user so Android & Web mirror
  /// pending notifications, ending balances, and imported/dismissed status.
  Future<void> bindUser(String? userId) async {
    final normalized = (userId ?? '').trim();
    final effective = (normalized.isEmpty ||
            normalized == 'guest' ||
            normalized == 'demo-user-finora')
        ? null
        : normalized;

    if (effective == _boundUserId) {
      if (effective != null && _cloudSub != null) {
        unawaited(syncCloudNow());
      }
      return;
    }

    await _cloudSub?.cancel();
    _cloudSub = null;
    _boundUserId = effective;
    _cloudDocs.clear();
    // Clear remote-only items from previous user session while preserving local native items.
    for (final remoteId in _remoteOnlyIds.toList()) {
      if (!_nativeSeenIds.contains(remoteId)) {
        _pending.remove(remoteId);
        _unrecognized.remove(remoteId);
      }
    }
    _remoteOnlyIds.clear();
    notifyListeners();

    if (effective == null) {
      unawaited(updateAppBadge());
      return;
    }

    try {
      _cloudSub = _cloudAdapter.watchNotifications(effective).listen(
        (rows) {
          _applyCloudSnapshot(rows);
        },
        onError: (_) {
          // Keep offline/local queue intact if cloud watch temporarily fails.
        },
      );
      await syncCloudNow();
    } catch (_) {
      // Never block local bank capture if Firebase/Supabase isn't ready yet.
    }
  }

  /// Force a bidirectional cloud reconciliation pass (pull remote status + push unsynced local items).
  Future<void> syncCloudNow() async {
    final uid = _boundUserId;
    if (uid == null || uid.isEmpty || _cloudSyncing) return;
    _cloudSyncing = true;
    try {
      final rows = await _cloudAdapter.loadNotifications(uid);
      _applyCloudSnapshot(rows);
    } catch (_) {
      // Graceful degradation when offline.
    } finally {
      _cloudSyncing = false;
    }
  }

  void _applyCloudSnapshot(List<Map<String, dynamic>> rows) {
    final uid = _boundUserId;
    if (uid == null || uid.isEmpty) return;

    final nextCloud = <String, CloudBankNotification>{};
    for (final raw in rows) {
      if (raw['deletedAt'] != null) continue;
      final id = (raw['id'] ?? raw['document_id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      nextCloud[id] = CloudBankNotification.fromMap(id, raw);
    }

    _cloudDocs
      ..clear()
      ..addAll(nextCloud);

    final nativeIdsToAck = <String>[];
    var changed = false;

    // 1. Auto-acknowledge any local pending/unrecognized item already imported or dismissed on Web/another device.
    for (final doc in nextCloud.values) {
      if (doc.isImported || doc.isDismissed) {
        final removedPending = _pending.remove(doc.id) != null;
        final removedUnrec = _unrecognized.remove(doc.id) != null;
        if (removedPending || removedUnrec) {
          changed = true;
          if (!_isNonNativeId(doc.id)) {
            nativeIdsToAck.add(doc.id);
          }
        }
        _remoteOnlyIds.remove(doc.id);
      }
    }

    // 2. Remove stale remote-only pending items that were deleted on Web.
    for (final remoteId in _remoteOnlyIds.toList()) {
      final remoteDoc = nextCloud[remoteId];
      if (remoteDoc == null || !remoteDoc.isPending) {
        if (!_nativeSeenIds.contains(remoteId)) {
          if (_pending.remove(remoteId) != null) changed = true;
          if (_unrecognized.remove(remoteId) != null) changed = true;
        }
        _remoteOnlyIds.remove(remoteId);
      }
    }

    // 3. Merge cloud pending items (e.g., pasted or entered from Web) into the phone inbox.
    for (final doc in nextCloud.values) {
      if (!doc.isPending) continue;
      if (!_pending.containsKey(doc.id) && !_unrecognized.containsKey(doc.id)) {
        if (!_nativeSeenIds.contains(doc.id)) {
          _remoteOnlyIds.add(doc.id);
        }
        if (doc.unrecognized) {
          _unrecognized[doc.id] = (
            title: doc.title.isNotEmpty ? doc.title : doc.bankName,
            text: doc.rawText.isNotEmpty ? doc.rawText : doc.note,
          );
          changed = true;
        } else {
          final parsed = doc.toParsedBankTransaction();
          _pending[doc.id] = parsed;
          changed = true;
        }
      }
    }

    if (nativeIdsToAck.isNotEmpty) {
      unawaited(_acknowledgeNativeQuietly(nativeIdsToAck));
    }

    // 4. Push any local pending items that do not exist in cloud yet.
    unawaited(_flushLocalPendingToCloud());

    if (changed || nextCloud.isNotEmpty) {
      notifyListeners();
      unawaited(updateAppBadge());
    }
  }

  Future<void> _flushLocalPendingToCloud() async {
    final uid = _boundUserId;
    if (uid == null || uid.isEmpty) return;

    for (final tx in _pending.values.toList()) {
      final existing = _cloudDocs[tx.rawId];
      if (existing != null) continue;
      await _pushPendingTxToCloud(
        tx,
        sourcePlatform: tx.rawId.startsWith('web_') ? 'web' : 'android',
      );
    }
    for (final entry in _unrecognized.entries.toList()) {
      final existing = _cloudDocs[entry.key];
      if (existing != null) continue;
      await _pushUnrecognizedToCloud(
        id: entry.key,
        title: entry.value.title,
        text: entry.value.text,
      );
    }
  }

  Future<void> _pushPendingTxToCloud(
    ParsedBankTransaction tx, {
    String sourcePlatform = 'android',
  }) async {
    final uid = _boundUserId;
    if (uid == null || uid.isEmpty) return;
    // Never overwrite an already imported or dismissed cloud record back to pending!
    final existing = _cloudDocs[tx.rawId];
    if (existing != null && (existing.isImported || existing.isDismissed)) {
      return;
    }
    if (_inFlightCloudPushes.contains(tx.rawId)) return;
    _inFlightCloudPushes.add(tx.rawId);
    try {
      final doc = CloudBankNotification.fromParsed(
        tx,
        userId: uid,
        sourcePlatform: sourcePlatform,
        status: 'pending',
      );
      await _cloudAdapter.saveNotification(uid, tx.rawId, doc.toMap());
      _cloudDocs[tx.rawId] = doc;
    } catch (_) {
      // Will retry on next syncCloudNow / resume.
    } finally {
      _inFlightCloudPushes.remove(tx.rawId);
    }
  }

  Future<void> _pushUnrecognizedToCloud({
    required String id,
    required String title,
    required String text,
    String packageName = '',
    int? timestampMs,
  }) async {
    final uid = _boundUserId;
    if (uid == null || uid.isEmpty) return;
    final existing = _cloudDocs[id];
    if (existing != null && (existing.isImported || existing.isDismissed)) {
      return;
    }
    if (_inFlightCloudPushes.contains(id)) return;
    _inFlightCloudPushes.add(id);
    try {
      final combinedText = '$title\n$text';
      final bank = BankNotificationParser.resolveBank(packageName, title, text);
      final balanceAfter = BankNotificationParser.extractBalanceAfter(
        combinedText,
      );
      final accountNumber = BankNotificationParser.extractAccountNumber(
        combinedText,
      );
      final doc = CloudBankNotification(
        id: id,
        userId: uid,
        status: 'pending',
        sourcePlatform: kIsWeb ? 'web' : 'android',
        packageName: packageName,
        bankCode: bank.code,
        bankName: bank.name,
        accountNumber: accountNumber,
        type: 'expense',
        amount: 0,
        unrecognized: true,
        balanceAfter: balanceAfter,
        title: title,
        note: text,
        rawText: combinedText.trim(),
        timestampMs: timestampMs ?? DateTime.now().millisecondsSinceEpoch,
      );
      await _cloudAdapter.saveNotification(uid, id, doc.toMap());
      _cloudDocs[id] = doc;
    } catch (_) {
      // Will retry on next syncCloudNow / resume.
    } finally {
      _inFlightCloudPushes.remove(id);
    }
  }

  Future<void> _acknowledgeNativeQuietly(List<String> ids) async {
    final nativeIds = ids.where((id) => !_isNonNativeId(id)).toList();
    if (nativeIds.isEmpty || kIsWeb || !supported) return;
    try {
      await _channel.invokeMethod<bool>('acknowledgeNotifications', {
        'ids': nativeIds,
      });
    } catch (_) {}
  }

  Future<void> _consumeInboxRequest() async {
    if (await _invokeBool('consumeBankInboxRequest')) _inboxRequests.add(null);
  }

  Future<String?> consumeLaunchAction() async {
    if (!supported) return null;
    try {
      final action = await _channel.invokeMethod<String>('consumeLaunchAction');
      final trimmed = action?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        if (trimmed == 'open_bank_inbox') {
          _inboxRequests.add(null);
        } else {
          _launchActions.add(trimmed);
        }
        return trimmed;
      }
    } catch (_) {}
    return null;
  }

  /// Pair-match an incoming transaction against existing pending transactions:
  /// If an expense from Bank A and an income from Bank B have the exact same amount
  /// within 3 minutes on the same device, merge/flag them as an internal transfer.
  ParsedBankTransaction _tryMatchInternalTransfer(
    ParsedBankTransaction incoming,
  ) {
    if (!pairTransfers) return incoming;
    for (final existing in _pending.values.toList()) {
      if (existing.rawId == incoming.rawId) continue;
      // Equal amounts alone do not prove two independent transactions are
      // a transfer. Keep both unless a source explicitly describes one.
      if (existing.bankCode == incoming.bankCode ||
          (!existing.isInternalTransferCandidate &&
              !incoming.isInternalTransferCandidate)) {
        continue;
      }
      final sameAmount = (existing.amount - incoming.amount).abs() < 1.0;
      if (!sameAmount) continue;
      final timeDiff = incoming.timestamp.difference(existing.timestamp).abs();
      if (timeDiff > const Duration(minutes: 3)) continue;

      final oppositeDirection =
          (existing.type == 'expense' && incoming.type == 'income') ||
              (existing.type == 'income' && incoming.type == 'expense');
      if (!oppositeDirection) continue;

      final sourceTx = existing.type == 'expense' ? existing : incoming;
      final destTx = existing.type == 'income' ? existing : incoming;

      final mergedTransfer = sourceTx.copyWith(
        type: 'transfer',
        isInternalTransferCandidate: true,
        matchedTransferBankCode: destTx.bankCode,
        matchedTransferBankName: destTx.bankName,
        matchedTransferRawId: destTx.rawId,
        suggestedCategoryId: 'chuyen_khoan',
        suggestedCategoryName:
            'Chuyển khoản (${sourceTx.bankName} → ${destTx.bankName})',
        suggestedCategoryIcon: 'arrow-right-left',
      );

      // Replace the earlier legs with the single paired transfer entry
      _pending.remove(existing.rawId);
      return mergedTransfer;
    }
    return incoming;
  }

  void _processRawJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      if (!BankNotificationSource.accepts(
        map['package']?.toString() ?? '',
        map['title']?.toString() ?? '',
        wallets: scanEWallets,
      )) {
        return;
      }
      if (id.isEmpty || id.startsWith('sim_') || _pending.containsKey(id)) {
        return;
      }
      _nativeSeenIds.add(id);

      // If Web/another device already imported or dismissed this notification,
      // clean up native queue instead of re-queueing it on the phone.
      final cloudExisting = _cloudDocs[id];
      if (cloudExisting != null &&
          (cloudExisting.isImported || cloudExisting.isDismissed)) {
        unawaited(_acknowledgeNativeQuietly([id]));
        return;
      }

      final pkg = map['package']?.toString() ?? '';
      final title = map['title']?.toString() ?? '';
      final text = map['text']?.toString() ?? '';
      final timestampMs = (map['timestamp'] as num?)?.toInt();

      final parsed = BankNotificationParser.parse(
        rawId: id,
        packageName: pkg,
        title: title,
        text: text,
        timestampMs: timestampMs,
      );
      if (parsed == null || parsed.amount <= 0) {
        _unrecognized[id] = (title: title, text: text);
        unawaited(
          _pushUnrecognizedToCloud(
            id: id,
            title: title,
            text: text,
            packageName: pkg,
            timestampMs: timestampMs,
          ),
        );
      } else {
        final resolved = _tryMatchInternalTransfer(parsed);
        _pending[resolved.rawId] = resolved;
        unawaited(_pushPendingTxToCloud(resolved, sourcePlatform: 'android'));
        if (resolved.amount > 0) {
          _events.add(resolved);
        }
      }
      notifyListeners();
      unawaited(updateAppBadge());
    } catch (_) {
      error =
          'Có thông báo chưa đọc được. Nội dung vẫn được giữ trên thiết bị.';
      notifyListeners();
    }
  }

  /// Allows Web or Mobile users to paste a bank SMS / notification string OR
  /// enter a manual balance fluctuation directly into the synced pending queue.
  ParsedBankTransaction injectManualNotification({
    required String title,
    required String text,
    String packageName = 'manual.bank',
    double? manualAmount,
    String? manualType,
    double? manualBalanceAfter,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? manualNote,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final id = 'manual_$nowMs';
    var parsed = BankNotificationParser.fromUnrecognized(
      rawId: id,
      title: title,
      text: text,
      packageName: packageName,
      timestampMs: nowMs,
    );
    if (manualAmount != null ||
        manualType != null ||
        manualBalanceAfter != null ||
        bankCode != null ||
        bankName != null ||
        accountNumber != null ||
        manualNote != null) {
      parsed = parsed.copyWith(
        amount: manualAmount ?? parsed.amount,
        type: manualType ?? parsed.type,
        balanceAfter: manualBalanceAfter ?? parsed.balanceAfter,
        bankCode: (bankCode != null && bankCode.trim().isNotEmpty)
            ? bankCode.trim()
            : parsed.bankCode,
        bankName: (bankName != null && bankName.trim().isNotEmpty)
            ? bankName.trim()
            : parsed.bankName,
        accountNumber:
            (accountNumber != null && accountNumber.trim().isNotEmpty)
                ? accountNumber.trim()
                : parsed.accountNumber,
        note: (manualNote != null && manualNote.trim().isNotEmpty)
            ? manualNote.trim()
            : parsed.note,
      );
    }
    final resolved = _tryMatchInternalTransfer(parsed);
    _pending[resolved.rawId] = resolved;
    unawaited(
      _pushPendingTxToCloud(
        resolved,
        sourcePlatform: kIsWeb ? 'web' : 'android',
      ),
    );
    _events.add(resolved);
    notifyListeners();
    unawaited(updateAppBadge());
    return resolved;
  }

  Future<bool> _invokeBool(String method) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPermissionGranted() => _invokeBool('isPermissionGranted');
  Future<bool> requestPermission() => _invokeBool('requestPermission');
  Future<bool> openAppInfo() => _invokeBool('openAppInfo');

  bool scanEcommerce = false;
  bool scanEWallets = true;
  bool scanAllApps = false;
  bool pairTransfers = true;
  bool detectCreditCardRepay = true;

  Future<void> updateScanSettings({
    bool? scanEcommerce,
    bool? scanEWallets,
    bool? scanAllApps,
    bool? pairTransfers,
    bool? detectCreditCardRepay,
  }) async {
    this.scanEcommerce = false;
    if (scanEWallets != null) this.scanEWallets = scanEWallets;
    if (pairTransfers != null) this.pairTransfers = pairTransfers;
    if (detectCreditCardRepay != null) {
      this.detectCreditCardRepay = detectCreditCardRepay;
    }
    this.scanAllApps = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('finora_scan_ecommerce', false);
      await prefs.setBool('finora_scan_all_apps', false);
      await prefs.setBool('finora_scan_ewallets', this.scanEWallets);
      await prefs.setBool('finora_pair_transfers', this.pairTransfers);
      await prefs.setBool(
          'finora_detect_credit_card_repay', this.detectCreditCardRepay);
      if (!supported) {
        notifyListeners();
        return;
      }
      await _channel.invokeMethod('updateScanSettings', {
        'scanEcommerce': this.scanEcommerce,
        'scanEWallets': this.scanEWallets,
        'scanAllApps': this.scanAllApps,
        'pairTransfers': this.pairTransfers,
        'detectCreditCardRepay': this.detectCreditCardRepay,
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadScanSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      scanEcommerce = false;
      scanEWallets = prefs.getBool('finora_scan_ewallets') ?? true;
      pairTransfers = prefs.getBool('finora_pair_transfers') ?? true;
      detectCreditCardRepay =
          prefs.getBool('finora_detect_credit_card_repay') ?? true;
      scanAllApps = false;
      await prefs.setBool('finora_scan_ecommerce', false);
      await prefs.setBool('finora_scan_all_apps', false);
      _autoPrompted.addAll(prefs.getStringList(_promptHistoryKey) ?? []);
      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod('updateScanSettings', {
          'scanEcommerce': scanEcommerce,
          'scanEWallets': scanEWallets,
          'scanAllApps': scanAllApps,
          'pairTransfers': pairTransfers,
          'detectCreditCardRepay': detectCreditCardRepay,
        });
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> isPostNotificationsGranted() =>
      _invokeBool('isPostNotificationsGranted');

  Future<bool> requestPostNotifications() =>
      _invokeBool('requestPostNotifications');

  Future<bool> openNotificationSettings() =>
      _invokeBool('openNotificationSettings');

  Future<bool> showSystemNotification({
    required String title,
    required String body,
    String channel = 'activity',
    int? id,
    bool fromBankSync = false,
    String? action,
  }) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('showSystemNotification', {
            'title': title,
            'body': body,
            'channel': channel,
            if (id != null) 'id': id,
            'fromBankSync': fromBankSync,
            if (action != null) 'action': action,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Đồng bộ số lượng thông báo hoạt động chưa đọc từ MoreProvider để badge luôn chính xác.
  Future<void> setUnreadActivityCount(int count) async {
    final normalized = count < 0 ? 0 : count;
    final changed = _unreadActivityCount != normalized;
    _unreadActivityCount = normalized;
    if (changed) notifyListeners();
    await updateAppBadge();
  }

  /// Cập nhật số lượng thông báo / giao dịch chờ lên biểu tượng ứng dụng ngoài màn hình chính
  Future<void> updateAppBadge([int? count]) async {
    if (!supported || kIsWeb) return;
    try {
      final total = count ?? totalBadgeCount;
      // Native pending_notifications already includes unrecognized bank notifications,
      // so extraCount must only carry non-native items (unread activity + manual/web drafts).
      final extra = _unreadActivityCount + manualPendingCount;
      await _channel.invokeMethod('updateAppBadge', {
        'count': total,
        'extraCount': extra,
      });
    } catch (_) {}
  }

  Future<bool> reconnect() async {
    await _invokeBool('reconnect');
    await checkPendingNotifications();
    await syncCloudNow();
    return connected;
  }

  /// Mark a bank notification as IMPORTED on this device and sync to Supabase
  /// so Web immediately shows "Đã nhập trên điện thoại" and blocks duplicate entry.
  Future<void> markImported(
    String rawId, {
    required String transactionId,
    required String walletId,
    required String walletName,
    String? toWalletId,
    String? toWalletName,
    required int amount,
    required String type,
    String? categoryName,
    bool syncedBalance = false,
    double? syncedBalanceValue,
    ParsedBankTransaction? fallbackTx,
  }) async {
    final item = _pending[rawId] ?? fallbackTx;
    final idsToAck = <String>[rawId];
    if (item?.matchedTransferRawId != null &&
        item!.matchedTransferRawId!.isNotEmpty) {
      idsToAck.add(item.matchedTransferRawId!);
    }

    final uid = _boundUserId;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const importedFrom = kIsWeb ? 'web' : 'android';

    if (uid != null && uid.isNotEmpty) {
      for (final targetId in idsToAck) {
        final baseDoc = _cloudDocs[targetId] ??
            (item != null
                ? CloudBankNotification.fromParsed(
                    item.rawId == targetId
                        ? item
                        : item.copyWith(rawId: targetId),
                    userId: uid,
                    sourcePlatform:
                        targetId.startsWith('web_') ? 'web' : 'android',
                  )
                : CloudBankNotification(
                    id: targetId,
                    userId: uid,
                    status: 'imported',
                    sourcePlatform:
                        targetId.startsWith('web_') ? 'web' : 'android',
                    bankCode: 'bank',
                    bankName: 'Ngân hàng',
                    type: type,
                    amount: amount.toDouble(),
                    note: categoryName ?? 'Giao dịch ngân hàng',
                    timestampMs: nowMs,
                  ));

        final importedDoc = baseDoc.copyWith(
          status: 'imported',
          importedAtMs: nowMs,
          importedFrom: importedFrom,
          importedTransactionId: transactionId,
          importedWalletId: walletId,
          importedWalletName: walletName,
          importedToWalletId: toWalletId,
          importedToWalletName: toWalletName,
          importedAmount: amount,
          importedType: type,
          importedCategoryName: categoryName,
          syncedBalance: syncedBalance,
          syncedBalanceValue: syncedBalanceValue,
          balanceAfter: syncedBalanceValue ?? baseDoc.balanceAfter,
        );
        _cloudDocs[targetId] = importedDoc;
        try {
          await _cloudAdapter.saveNotification(
            uid,
            targetId,
            importedDoc.toMap(),
          );
        } catch (_) {
          // Keep local ack reliable even if offline; transaction itself is already saved.
        }
      }
    }

    await _acknowledgeLocalAndNative(idsToAck);
  }

  Future<void> _acknowledgeLocalAndNative(List<String> idsToAck) async {
    final nativeIds = idsToAck.where((id) => !_isNonNativeId(id)).toList();
    if (!kIsWeb && nativeIds.isNotEmpty) {
      bool? ok;
      try {
        ok = await _channel.invokeMethod<bool>('acknowledgeNotifications', {
          'ids': nativeIds,
        });
      } on MissingPluginException {
        if (supported) rethrow;
      }
      if (ok == false || (supported && ok != true)) {
        throw StateError('acknowledge_failed');
      }
    }
    for (final ackId in idsToAck) {
      _pending.remove(ackId);
      _unrecognized.remove(ackId);
      _remoteOnlyIds.remove(ackId);
    }
    notifyListeners();
    unawaited(updateAppBadge());
  }

  Future<void> acknowledge(String rawId) async {
    final item = _pending[rawId];
    final idsToAck = <String>[rawId];
    if (item?.matchedTransferRawId != null &&
        item!.matchedTransferRawId!.isNotEmpty) {
      idsToAck.add(item.matchedTransferRawId!);
    }

    final uid = _boundUserId;
    if (uid != null && uid.isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      const dismissedFrom = kIsWeb ? 'web' : 'android';
      for (final targetId in idsToAck) {
        final existing = _cloudDocs[targetId];
        if (existing?.isImported == true) continue;
        final baseDoc = existing ??
            (item != null
                ? CloudBankNotification.fromParsed(
                    item.rawId == targetId
                        ? item
                        : item.copyWith(rawId: targetId),
                    userId: uid,
                    sourcePlatform:
                        targetId.startsWith('web_') ? 'web' : 'android',
                  )
                : null);
        if (baseDoc != null) {
          final dismissedDoc = baseDoc.copyWith(
            status: 'dismissed',
            dismissedAtMs: nowMs,
            dismissedFrom: dismissedFrom,
          );
          _cloudDocs[targetId] = dismissedDoc;
          try {
            await _cloudAdapter.saveNotification(
              uid,
              targetId,
              dismissedDoc.toMap(),
            );
          } catch (_) {}
        }
      }
    }

    await _acknowledgeLocalAndNative(idsToAck);
  }

  /// Remove an old imported/dismissed notification from cloud history.
  Future<void> deleteCloudHistoryItem(String id) async {
    final uid = _boundUserId;
    _cloudDocs.remove(id);
    notifyListeners();
    if (uid != null && uid.isNotEmpty) {
      try {
        await _cloudAdapter.deleteNotification(uid, id);
      } catch (_) {}
    }
  }

  /// Dọn dẹp sạch toàn bộ hàng đợi giao dịch chờ và thông báo chưa đọc số tiền
  Future<void> acknowledgeAll() async {
    final allIds = <String>{
      ..._pending.keys,
      ..._unrecognized.keys,
    }.toList();

    if (allIds.isEmpty) {
      _pending.clear();
      _unrecognized.clear();
      notifyListeners();
      unawaited(updateAppBadge());
      return;
    }

    final uid = _boundUserId;
    if (uid != null && uid.isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      const dismissedFrom = kIsWeb ? 'web' : 'android';
      for (final id in allIds) {
        final existing = _cloudDocs[id];
        if (existing?.isImported == true) continue;
        final pendingTx = _pending[id];
        final baseDoc = existing ??
            (pendingTx != null
                ? CloudBankNotification.fromParsed(
                    pendingTx,
                    userId: uid,
                    sourcePlatform: id.startsWith('web_') ? 'web' : 'android',
                  )
                : null);
        if (baseDoc != null) {
          final dismissedDoc = baseDoc.copyWith(
            status: 'dismissed',
            dismissedAtMs: nowMs,
            dismissedFrom: dismissedFrom,
          );
          _cloudDocs[id] = dismissedDoc;
          try {
            await _cloudAdapter.saveNotification(uid, id, dismissedDoc.toMap());
          } catch (_) {}
        }
      }
    }

    try {
      if (supported && !kIsWeb) {
        final nativeIds =
            allIds.where((id) => !_isNonNativeId(id)).toList();
        if (nativeIds.isNotEmpty) {
          await _channel.invokeMethod<bool>('acknowledgeNotifications', {
            'ids': nativeIds,
          });
        }
      }
    } catch (_) {}

    _pending.clear();
    _unrecognized.clear();
    _remoteOnlyIds.clear();
    notifyListeners();
    unawaited(updateAppBadge());
  }

  Future<void> checkPendingNotifications() async {
    if (!supported || _polling) return;
    _polling = true;
    try {
      final list =
          await _channel.invokeListMethod<String>('getPendingNotifications') ??
              [];
      for (final raw in list) {
        _processRawJson(raw);
      }
      final status =
          await _channel.invokeMapMethod<String, dynamic>('getSyncStatus');
      connected = status?['connected'] == true;
      final ms = (status?['lastReceivedAt'] as num?)?.toInt() ?? 0;
      lastReceivedAt = ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
      error = null;
    } catch (_) {
      error = 'Chưa kết nối được dịch vụ đọc thông báo trên thiết bị.';
    } finally {
      _polling = false;
      notifyListeners();
      unawaited(updateAppBadge());
    }
  }
}
