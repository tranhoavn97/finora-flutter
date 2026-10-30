import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vietqr_data.dart';

/// Device-local pending records. Never changes a wallet balance or claims payment.
class QrPaymentDraft {
  final String id;
  final VietQrData data;
  final int amount;
  final String memo;
  final String? walletId;
  final String? categoryId;
  const QrPaymentDraft(
      {required this.id,
      required this.data,
      required this.amount,
      required this.memo,
      this.walletId,
      this.categoryId});
  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'memo': memo,
        'walletId': walletId,
        'categoryId': categoryId,
        'bankBin': data.bankBin,
        'bankName': data.bankName,
        'bankShortName': data.bankShortName,
        'accountNumber': data.accountNumber,
        'accountName': data.accountName,
        'rawPayload': data.rawPayload,
      };
  factory QrPaymentDraft.fromMap(Map<String, dynamic> m) => QrPaymentDraft(
      id: m['id'] as String,
      amount: (m['amount'] as num).toInt(),
      memo: m['memo'] as String,
      walletId: m['walletId'] as String?,
      categoryId: m['categoryId'] as String?,
      data: VietQrData(
          bankBin: m['bankBin'] as String?,
          bankName: m['bankName'] as String,
          bankShortName: m['bankShortName'] as String,
          accountNumber: m['accountNumber'] as String,
          accountName: m['accountName'] as String?,
          amount: (m['amount'] as num).toDouble(),
          memo: m['memo'] as String,
          rawPayload: m['rawPayload'] as String));
}

class QrPaymentDraftStore {
  static Future<void> _queue = Future.value();
  static String _key(String uid) => 'finora_pending_qr_v1_$uid';
  static Future<List<QrPaymentDraft>> list(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return [];
    final items = jsonDecode(raw) as List;
    return items
        .map((m) => QrPaymentDraft.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static Future<void> _mutate(
      String uid, void Function(List<QrPaymentDraft>) update) {
    final next = _queue.then((_) async {
      final items = await list(uid);
      update(items);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
          _key(uid), jsonEncode(items.map((d) => d.toMap()).toList()))) {
        throw StateError('Không lưu được bản nháp trên máy');
      }
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  static Future<void> save(String uid, QrPaymentDraft draft) =>
      _mutate(uid, (items) {
        items.removeWhere((d) => d.id == draft.id);
        items.insert(0, draft);
      });
  static Future<void> remove(String uid, String id) =>
      _mutate(uid, (items) => items.removeWhere((d) => d.id == id));
}
