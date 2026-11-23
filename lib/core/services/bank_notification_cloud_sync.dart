import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/services/supabase_bridge.dart';
import 'bank_notification_parser.dart';

/// Canonical cross-platform record stored in Supabase `finora_documents`
/// under `collection_name = 'bankNotifications'`, scoped privately to `userId`.
class CloudBankNotification {
  final String id;
  final String userId;
  final String status; // 'pending' | 'imported' | 'dismissed'
  final String sourcePlatform; // 'android' | 'web' | 'ios'
  final String packageName;
  final String bankCode;
  final String bankName;
  final String? accountNumber;
  final String type; // 'expense' | 'income' | 'transfer'
  final double amount;
  final bool unrecognized;
  final double? balanceAfter;
  final String title;
  final String note;
  final String rawText;
  final String transactionCode;
  final String suggestedCategoryId;
  final String suggestedCategoryName;
  final String suggestedCategoryIcon;
  final String? suggestedMerchant;
  final bool isCreditCardPayment;
  final bool isInternalTransferCandidate;
  final String? matchedTransferBankCode;
  final String? matchedTransferBankName;
  final String? matchedTransferRawId;
  final int timestampMs;

  // Import audit fields (populated when status == 'imported')
  final int? importedAtMs;
  final String? importedFrom; // 'android' | 'web' | 'ios'
  final String? importedTransactionId;
  final String? importedWalletId;
  final String? importedWalletName;
  final String? importedToWalletId;
  final String? importedToWalletName;
  final int? importedAmount;
  final String? importedType;
  final String? importedCategoryName;
  final bool syncedBalance;
  final double? syncedBalanceValue;

  // Dismiss audit fields (populated when status == 'dismissed')
  final int? dismissedAtMs;
  final String? dismissedFrom;

  bool get isPending => status == 'pending';
  bool get isImported => status == 'imported';
  bool get isDismissed => status == 'dismissed';
  bool get isFromWeb => sourcePlatform == 'web' || id.startsWith('web_');

  const CloudBankNotification({
    required this.id,
    required this.userId,
    required this.status,
    required this.sourcePlatform,
    this.packageName = '',
    required this.bankCode,
    required this.bankName,
    this.accountNumber,
    required this.type,
    required this.amount,
    this.unrecognized = false,
    this.balanceAfter,
    this.title = '',
    required this.note,
    this.rawText = '',
    this.transactionCode = '',
    this.suggestedCategoryId = 'khac',
    this.suggestedCategoryName = 'Khác',
    this.suggestedCategoryIcon = 'more-horizontal',
    this.suggestedMerchant,
    this.isCreditCardPayment = false,
    this.isInternalTransferCandidate = false,
    this.matchedTransferBankCode,
    this.matchedTransferBankName,
    this.matchedTransferRawId,
    required this.timestampMs,
    this.importedAtMs,
    this.importedFrom,
    this.importedTransactionId,
    this.importedWalletId,
    this.importedWalletName,
    this.importedToWalletId,
    this.importedToWalletName,
    this.importedAmount,
    this.importedType,
    this.importedCategoryName,
    this.syncedBalance = false,
    this.syncedBalanceValue,
    this.dismissedAtMs,
    this.dismissedFrom,
  });

  static int _parseEpochMs(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) {
      final n = value.toInt();
      if (n <= 0) return fallback;
      return n < 100000000000 ? n * 1000 : n;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return fallback;
      final asNum = num.tryParse(trimmed);
      if (asNum != null) return _parseEpochMs(asNum, fallback: fallback);
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return fallback;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.isFinite ? value.toDouble() : null;
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  static String? _nonEmptyString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory CloudBankNotification.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final statusRaw = (map['status'] ?? 'pending').toString().trim().toLowerCase();
    final status = (statusRaw == 'imported' || statusRaw == 'dismissed')
        ? statusRaw
        : 'pending';
    final rawType = (map['type'] ?? 'expense').toString().trim().toLowerCase();
    final type = (rawType == 'income' || rawType == 'transfer')
        ? rawType
        : 'expense';

    final amount = _parseNullableDouble(map['amount']) ?? 0.0;
    final tsMs = _parseEpochMs(
      map['timestamp'] ?? map['createdAt'],
      fallback: nowMs,
    );
    final importedAtRaw = _parseEpochMs(map['importedAt'], fallback: 0);
    final dismissedAtRaw = _parseEpochMs(map['dismissedAt'], fallback: 0);

    return CloudBankNotification(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      status: status,
      sourcePlatform:
          _nonEmptyString(map['sourcePlatform'])?.toLowerCase() ?? 'android',
      packageName: (map['packageName'] ?? '').toString(),
      bankCode: _nonEmptyString(map['bankCode']) ?? 'bank',
      bankName: _nonEmptyString(map['bankName']) ?? 'Ngân hàng',
      accountNumber: _nonEmptyString(map['accountNumber']),
      type: type,
      amount: amount.abs(),
      unrecognized: map['unrecognized'] == true,
      balanceAfter: _parseNullableDouble(map['balanceAfter']),
      title: (map['title'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      rawText: (map['rawText'] ?? map['rawNotificationText'] ?? '').toString(),
      transactionCode: (map['transactionCode'] ?? map['refCode'] ?? '').toString(),
      suggestedCategoryId:
          _nonEmptyString(map['suggestedCategoryId']) ?? 'khac',
      suggestedCategoryName:
          _nonEmptyString(map['suggestedCategoryName']) ?? 'Khác',
      suggestedCategoryIcon:
          _nonEmptyString(map['suggestedCategoryIcon']) ?? 'more-horizontal',
      suggestedMerchant: _nonEmptyString(map['suggestedMerchant']),
      isCreditCardPayment: map['isCreditCardPayment'] == true,
      isInternalTransferCandidate: map['isInternalTransferCandidate'] == true,
      matchedTransferBankCode: _nonEmptyString(map['matchedTransferBankCode']),
      matchedTransferBankName: _nonEmptyString(map['matchedTransferBankName']),
      matchedTransferRawId: _nonEmptyString(map['matchedTransferRawId']),
      timestampMs: tsMs,
      importedAtMs: importedAtRaw > 0 ? importedAtRaw : null,
      importedFrom: _nonEmptyString(map['importedFrom'])?.toLowerCase(),
      importedTransactionId: _nonEmptyString(map['importedTransactionId']),
      importedWalletId: _nonEmptyString(map['importedWalletId']),
      importedWalletName: _nonEmptyString(map['importedWalletName']),
      importedToWalletId: _nonEmptyString(map['importedToWalletId']),
      importedToWalletName: _nonEmptyString(map['importedToWalletName']),
      importedAmount: (map['importedAmount'] as num?)?.round(),
      importedType: _nonEmptyString(map['importedType']),
      importedCategoryName: _nonEmptyString(map['importedCategoryName']),
      syncedBalance: map['syncedBalance'] == true,
      syncedBalanceValue: _parseNullableDouble(map['syncedBalanceValue']),
      dismissedAtMs: dismissedAtRaw > 0 ? dismissedAtRaw : null,
      dismissedFrom: _nonEmptyString(map['dismissedFrom'])?.toLowerCase(),
    );
  }

  factory CloudBankNotification.fromParsed(
    ParsedBankTransaction tx, {
    required String userId,
    String sourcePlatform = 'android',
    String status = 'pending',
    bool unrecognized = false,
    String? title,
  }) {
    return CloudBankNotification(
      id: tx.rawId,
      userId: userId,
      status: status,
      sourcePlatform: sourcePlatform,
      packageName: tx.packageName,
      bankCode: tx.bankCode,
      bankName: tx.bankName,
      accountNumber: tx.accountNumber,
      type: tx.type,
      amount: tx.amount,
      unrecognized: unrecognized,
      balanceAfter: tx.balanceAfter,
      title: title ?? tx.bankName,
      note: tx.note,
      rawText: tx.rawNotificationText.isNotEmpty
          ? tx.rawNotificationText
          : tx.note,
      transactionCode: tx.transactionCode,
      suggestedCategoryId: tx.suggestedCategoryId,
      suggestedCategoryName: tx.suggestedCategoryName,
      suggestedCategoryIcon: tx.suggestedCategoryIcon,
      suggestedMerchant: tx.suggestedMerchant,
      isCreditCardPayment: tx.isCreditCardPayment,
      isInternalTransferCandidate: tx.isInternalTransferCandidate,
      matchedTransferBankCode: tx.matchedTransferBankCode,
      matchedTransferBankName: tx.matchedTransferBankName,
      matchedTransferRawId: tx.matchedTransferRawId,
      timestampMs: tx.timestamp.millisecondsSinceEpoch,
    );
  }

  ParsedBankTransaction toParsedBankTransaction() {
    return ParsedBankTransaction(
      rawId: id,
      packageName: packageName.isNotEmpty
          ? packageName
          : (isFromWeb ? 'web.manual' : 'android.bank'),
      bankCode: bankCode,
      bankName: bankName,
      amount: amount,
      type: type,
      accountNumber: accountNumber,
      balanceAfter: balanceAfter,
      note: note.isNotEmpty ? note : rawText,
      transactionCode: transactionCode,
      rawNotificationText: rawText.isNotEmpty ? rawText : note,
      suggestedCategoryId: suggestedCategoryId,
      suggestedCategoryName: suggestedCategoryName,
      suggestedCategoryIcon: suggestedCategoryIcon,
      suggestedMerchant: suggestedMerchant,
      isCreditCardPayment: isCreditCardPayment,
      isInternalTransferCandidate: isInternalTransferCandidate,
      matchedTransferBankCode: matchedTransferBankCode,
      matchedTransferBankName: matchedTransferBankName,
      matchedTransferRawId: matchedTransferRawId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  CloudBankNotification copyWith({
    String? status,
    int? importedAtMs,
    String? importedFrom,
    String? importedTransactionId,
    String? importedWalletId,
    String? importedWalletName,
    String? importedToWalletId,
    String? importedToWalletName,
    int? importedAmount,
    String? importedType,
    String? importedCategoryName,
    bool? syncedBalance,
    double? syncedBalanceValue,
    int? dismissedAtMs,
    String? dismissedFrom,
    double? balanceAfter,
  }) {
    return CloudBankNotification(
      id: id,
      userId: userId,
      status: status ?? this.status,
      sourcePlatform: sourcePlatform,
      packageName: packageName,
      bankCode: bankCode,
      bankName: bankName,
      accountNumber: accountNumber,
      type: type,
      amount: amount,
      unrecognized: unrecognized,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      title: title,
      note: note,
      rawText: rawText,
      transactionCode: transactionCode,
      suggestedCategoryId: suggestedCategoryId,
      suggestedCategoryName: suggestedCategoryName,
      suggestedCategoryIcon: suggestedCategoryIcon,
      suggestedMerchant: suggestedMerchant,
      isCreditCardPayment: isCreditCardPayment,
      isInternalTransferCandidate: isInternalTransferCandidate,
      matchedTransferBankCode: matchedTransferBankCode,
      matchedTransferBankName: matchedTransferBankName,
      matchedTransferRawId: matchedTransferRawId,
      timestampMs: timestampMs,
      importedAtMs: importedAtMs ?? this.importedAtMs,
      importedFrom: importedFrom ?? this.importedFrom,
      importedTransactionId:
          importedTransactionId ?? this.importedTransactionId,
      importedWalletId: importedWalletId ?? this.importedWalletId,
      importedWalletName: importedWalletName ?? this.importedWalletName,
      importedToWalletId: importedToWalletId ?? this.importedToWalletId,
      importedToWalletName: importedToWalletName ?? this.importedToWalletName,
      importedAmount: importedAmount ?? this.importedAmount,
      importedType: importedType ?? this.importedType,
      importedCategoryName: importedCategoryName ?? this.importedCategoryName,
      syncedBalance: syncedBalance ?? this.syncedBalance,
      syncedBalanceValue: syncedBalanceValue ?? this.syncedBalanceValue,
      dismissedAtMs: dismissedAtMs ?? this.dismissedAtMs,
      dismissedFrom: dismissedFrom ?? this.dismissedFrom,
    );
  }

  Map<String, dynamic> toMap() {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'sourcePlatform': sourcePlatform,
      'sourceDeviceLabel':
          sourcePlatform == 'web' ? 'Trình duyệt Web' : 'Điện thoại Android',
      'packageName': packageName,
      'bankCode': bankCode,
      'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      'type': type,
      'amount': amount,
      'unrecognized': unrecognized,
      if (balanceAfter != null) 'balanceAfter': balanceAfter,
      'title': title,
      'note': note,
      'rawText': rawText,
      'transactionCode': transactionCode,
      'suggestedCategoryId': suggestedCategoryId,
      'suggestedCategoryName': suggestedCategoryName,
      'suggestedCategoryIcon': suggestedCategoryIcon,
      if (suggestedMerchant != null) 'suggestedMerchant': suggestedMerchant,
      'isCreditCardPayment': isCreditCardPayment,
      'isInternalTransferCandidate': isInternalTransferCandidate,
      if (matchedTransferBankCode != null)
        'matchedTransferBankCode': matchedTransferBankCode,
      if (matchedTransferBankName != null)
        'matchedTransferBankName': matchedTransferBankName,
      if (matchedTransferRawId != null)
        'matchedTransferRawId': matchedTransferRawId,
      'timestamp': timestampMs,
      'createdAt':
          DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true)
              .toIso8601String(),
      'updatedAt': nowIso,
      if (importedAtMs != null) 'importedAt': importedAtMs,
      if (importedFrom != null) 'importedFrom': importedFrom,
      if (importedTransactionId != null)
        'importedTransactionId': importedTransactionId,
      if (importedWalletId != null) 'importedWalletId': importedWalletId,
      if (importedWalletName != null) 'importedWalletName': importedWalletName,
      if (importedToWalletId != null) 'importedToWalletId': importedToWalletId,
      if (importedToWalletName != null)
        'importedToWalletName': importedToWalletName,
      if (importedAmount != null) 'importedAmount': importedAmount,
      if (importedType != null) 'importedType': importedType,
      if (importedCategoryName != null)
        'importedCategoryName': importedCategoryName,
      'syncedBalance': syncedBalance,
      if (syncedBalanceValue != null) 'syncedBalanceValue': syncedBalanceValue,
      if (dismissedAtMs != null) 'dismissedAt': dismissedAtMs,
      if (dismissedFrom != null) 'dismissedFrom': dismissedFrom,
    };
  }
}

/// Persistence adapter for syncing bank notifications to cloud (Supabase).
/// Abstracted so unit tests can inject a deterministic in-memory adapter.
abstract class BankNotificationCloudAdapter {
  const BankNotificationCloudAdapter();

  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);

  Future<List<Map<String, dynamic>>> loadNotifications(String userId);

  Future<void> saveNotification(
    String userId,
    String documentId,
    Map<String, dynamic> data, {
    bool replace = false,
  });

  Future<void> deleteNotification(String userId, String documentId);
}

class SupabaseBankNotificationAdapter extends BankNotificationCloudAdapter {
  static const String collectionName = 'bankNotifications';

  const SupabaseBankNotificationAdapter();

  bool _canUseCloudFor(String userId) {
    if (userId.isEmpty) return false;
    try {
      if (Firebase.apps.isEmpty) return false;
      final current = FirebaseAuth.instance.currentUser;
      return current != null && current.uid == userId;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    if (!_canUseCloudFor(userId)) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return SupabaseBridge.watchUserCollection(
      userId: userId,
      collection: collectionName,
      interval: const Duration(seconds: 8),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> loadNotifications(String userId) async {
    if (!_canUseCloudFor(userId)) return const [];
    return SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: collectionName,
    );
  }

  @override
  Future<void> saveNotification(
    String userId,
    String documentId,
    Map<String, dynamic> data, {
    bool replace = false,
  }) async {
    if (!_canUseCloudFor(userId)) return;
    return SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: collectionName,
      documentId: documentId,
      data: data,
      replace: replace,
    );
  }

  @override
  Future<void> deleteNotification(String userId, String documentId) async {
    if (!_canUseCloudFor(userId)) return;
    return SupabaseBridge.deleteUserDocument(
      userId: userId,
      collection: collectionName,
      documentId: documentId,
    );
  }
}
