import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'bank_notification_parser.dart';
import 'bank_notification_source.dart';

/// Native queue is the durable source of truth. Reading never acknowledges it.
/// Also supports pair-matching internal transfers on the same phone (1 expense + 1 income
/// of the exact same amount within 3 minutes across two banks/wallets) and Web/clipboard parsing.
class BankSyncService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.finora/bank_sync');
  static final BankSyncService _instance = BankSyncService._internal();
  factory BankSyncService() => _instance;
  BankSyncService._internal();

  final _inboxRequests = StreamController<void>.broadcast();
  Stream<void> get onInboxRequested => _inboxRequests.stream;

  final _events = StreamController<ParsedBankTransaction>.broadcast();
  Stream<ParsedBankTransaction> get onTransactionDetected => _events.stream;
  final Map<String, ParsedBankTransaction> _pending = {};
  final Map<String, ({String title, String text})> _unrecognized = {};
  Map<String, ({String title, String text})> get unrecognized =>
      Map.unmodifiable(_unrecognized);
  List<ParsedBankTransaction> get pending => List.unmodifiable(_pending.values);
  int get unrecognizedCount => _unrecognized.length;
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

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'openBankInbox') {
          await _consumeInboxRequest();
        }
        if (call.method == 'onBankNotification' && call.arguments is String) {
          _processRawJson(call.arguments as String);
        }
      });
    }
    await loadScanSettings();
    await checkPendingNotifications();
    await _consumeInboxRequest();
  }

  Future<void> _consumeInboxRequest() async {
    if (await _invokeBool('consumeBankInboxRequest')) _inboxRequests.add(null);
  }

  /// Pair-match an incoming transaction against existing pending transactions:
  /// If an expense from Bank A and an income from Bank B have the exact same amount
  /// within 3 minutes on the same device, merge/flag them as an internal transfer.
  ParsedBankTransaction _tryMatchInternalTransfer(
    ParsedBankTransaction incoming,
  ) {
    for (final existing in _pending.values.toList()) {
      if (existing.rawId == incoming.rawId) continue;
      // Equal amounts alone do not prove two independent transactions are
      // a transfer. Keep both unless a source explicitly describes one.
      if (existing.bankCode == incoming.bankCode ||
          (!existing.isInternalTransferCandidate &&
              !incoming.isInternalTransferCandidate)) continue;
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
      )) return;
      if (id.isEmpty || id.startsWith('sim_') || _pending.containsKey(id)) {
        return;
      }
      final parsed = BankNotificationParser.parse(
        rawId: id,
        packageName: map['package']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        timestampMs: (map['timestamp'] as num?)?.toInt(),
      );
      if (parsed == null) {
        _unrecognized[id] = (
          title: map['title']?.toString() ?? '',
          text: map['text']?.toString() ?? ''
        );
      } else {
        final resolved = _tryMatchInternalTransfer(parsed);
        _pending[resolved.rawId] = resolved;
        _events.add(resolved);
      }
      notifyListeners();
    } catch (_) {
      error =
          'Có thông báo chưa đọc được. Nội dung vẫn được giữ trên thiết bị.';
      notifyListeners();
    }
  }

  /// Allows Web or Mobile users to paste a bank SMS / notification string and parse it
  /// into the pending queue with full transaction code & transfer/card detection.
  ParsedBankTransaction injectManualNotification({
    required String title,
    required String text,
    String packageName = 'manual.bank',
  }) {
    final id = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    final parsed = BankNotificationParser.fromUnrecognized(
      rawId: id,
      title: title,
      text: text,
      packageName: packageName,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final resolved = _tryMatchInternalTransfer(parsed);
    _pending[resolved.rawId] = resolved;
    _events.add(resolved);
    notifyListeners();
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

  Future<void> updateScanSettings({
    bool? scanEcommerce,
    bool? scanEWallets,
    bool? scanAllApps,
  }) async {
    this.scanEcommerce = false;
    if (scanEWallets != null) this.scanEWallets = scanEWallets;
    this.scanAllApps = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('finora_scan_ecommerce', false);
      await prefs.setBool('finora_scan_all_apps', false);
      await prefs.setBool('finora_scan_ewallets', this.scanEWallets);
      if (!supported) {
        notifyListeners();
        return;
      }
      await _channel.invokeMethod('updateScanSettings', {
        'scanEcommerce': this.scanEcommerce,
        'scanEWallets': this.scanEWallets,
        'scanAllApps': this.scanAllApps,
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadScanSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      scanEcommerce = false;
      scanEWallets = prefs.getBool('finora_scan_ewallets') ?? true;
      scanAllApps = false;
      await prefs.setBool('finora_scan_ecommerce', false);
      await prefs.setBool('finora_scan_all_apps', false);
      _autoPrompted.addAll(prefs.getStringList(_promptHistoryKey) ?? []);
      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod('updateScanSettings', {
          'scanEcommerce': scanEcommerce,
          'scanEWallets': scanEWallets,
          'scanAllApps': scanAllApps,
        });
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> requestPostNotifications() =>
      _invokeBool('requestPostNotifications');
  Future<void> reconnect() async {
    await _invokeBool('reconnect');
    await checkPendingNotifications();
  }

  Future<void> acknowledge(String rawId) async {
    final item = _pending[rawId];
    final idsToAck = <String>[rawId];
    if (item?.matchedTransferRawId != null &&
        item!.matchedTransferRawId!.isNotEmpty) {
      idsToAck.add(item.matchedTransferRawId!);
    }
    if (rawId.startsWith('manual_')) {
      _pending.remove(rawId);
      _unrecognized.remove(rawId);
      notifyListeners();
      return;
    }
    final ok = await _channel.invokeMethod<bool>('acknowledgeNotifications', {
      'ids': idsToAck,
    });
    if (ok != true) throw StateError('Chưa cập nhật được hàng đợi ngân hàng.');
    for (final ackId in idsToAck) {
      _pending.remove(ackId);
      _unrecognized.remove(ackId);
    }
    notifyListeners();
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
    }
  }
}
