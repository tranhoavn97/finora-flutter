import '../models/wallet.dart';
import '../models/transaction.dart';
import 'wallet_repository.dart';
import 'finora_nlp_engine.dart';
import 'supabase_bridge.dart';

/// A proposal is data only. Applying it always requires a separate UI confirmation.
class CopilotAction {
  final String collection, id, field, label;
  final Object before, value;
  const CopilotAction(
      {required this.collection,
      required this.id,
      required this.field,
      required this.label,
      required this.before,
      required this.value});
}

class CopilotActionService {
  static bool isEditRequest(String message) {
    final text = FinoraNlpEngine.normalize(message);
    return RegExp(r'\b(sua|doi|cap nhat|dieu chinh|dat lai)\b')
            .hasMatch(text) ||
        (RegExp(r'\b(tang|giam)\b').hasMatch(text) &&
            RegExp('ngan sach|muc tieu|giao dich').hasMatch(text));
  }

  static const fields = {
    'transactions': ['amount', 'note'],
    'budgets': ['limitAmount'],
    'goals': ['targetAmount', 'name']
  };

  static CopilotAction validate(String collection, String id, String field,
      Object value, Map<String, List<Map<String, dynamic>>> data) {
    if (!(fields[collection]?.contains(field) ?? false))
      throw StateError('Thao tác chưa được hỗ trợ.');
    final row = data[collection]
        ?.where((r) =>
            r['id'] == id && r['deletedAt'] == null && r['isArchived'] != true)
        .firstOrNull;
    if (row == null) throw StateError('Không tìm thấy bản ghi còn hoạt động.');
    if (collection == 'transactions' &&
        (!['income', 'expense'].contains(row['type']) ||
            row['assetId'] != null ||
            row['goalId'] != null ||
            row['loanId'] != null)) {
      throw StateError('Hãy sửa giao dịch liên kết tại màn hình chi tiết.');
    }
    final money = ['amount', 'limitAmount', 'targetAmount'].contains(field);
    if (money
        ? !(value is int && value > 0 && value <= 1000000000000000)
        : !(value is String &&
            value.trim().isNotEmpty &&
            value.length <= 300)) {
      throw StateError('Giá trị mới không hợp lệ.');
    }
    if (collection == 'goals' &&
        field == 'targetAmount' &&
        (value as int) < ((row['savedAmount'] as num?)?.toInt() ?? 0)) {
      throw StateError('Mục tiêu không được thấp hơn số tiền đã tích lũy.');
    }
    return CopilotAction(
        collection: collection,
        id: id,
        field: field,
        value: value,
        before: row[field] ?? '',
        label: (row['note'] ?? row['name'] ?? row['categoryName'] ?? id)
            .toString());
  }

  static CopilotAction plan(
      String message, Map<String, List<Map<String, dynamic>>> data) {
    final text = FinoraNlpEngine.normalize(message);
    final collection = text.contains('ngan sach')
        ? 'budgets'
        : text.contains('muc tieu')
            ? 'goals'
            : 'transactions';
    var rows = (data[collection] ?? [])
        .where((r) => r['deletedAt'] == null && r['isArchived'] != true)
        .toList();
    if (collection == 'budgets') {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      rows = rows
          .where((r) => r['monthKey'] == null || r['monthKey'] == month)
          .toList();
    }
    var matches = rows
        .where((r) => [r['id'], r['note'], r['name'], r['categoryName']].any(
            (v) =>
                v != null &&
                v.toString().isNotEmpty &&
                text.contains(FinoraNlpEngine.normalize(v.toString()))))
        .toList();
    if (collection == 'transactions' &&
        RegExp('gan nhat|moi nhat').hasMatch(text) &&
        matches.isEmpty) {
      rows.sort((a, b) => _date(b['date']).compareTo(_date(a['date'])));
      matches = rows.take(1).toList();
    }
    if (matches.length != 1)
      throw StateError(matches.isEmpty
          ? 'Hãy nêu rõ tên hoặc ID bản ghi cần sửa.'
          : 'Có nhiều bản ghi cùng tên. Hãy nêu ID bản ghi cần sửa.');
    final row = matches.single;
    final quoted = RegExp(r'[“"]([^”"]+)[”"]\s*$').firstMatch(message);
    late String field;
    late Object value;
    if (quoted != null &&
        (text.contains('ghi chu') || text.contains('doi ten'))) {
      field = collection == 'goals' ? 'name' : 'note';
      value = quoted.group(1)!;
    } else {
      final numbers = RegExp(
              r'(\d+(?:[.,]\d+)*)\s*(trieu|tr|nghin|ngan|k|ty|vnd|d)?(?=\s|$|[,;!?])')
          .allMatches(text)
          .toList();
      if (numbers.isEmpty)
        throw StateError(
            'Hãy nêu số tiền mới, ví dụ: sửa ngân sách Ăn uống thành 3 triệu.');
      final m = numbers.last;
      final unit = m.group(2) ?? '';
      final number = double.tryParse(unit.isNotEmpty
              ? m.group(1)!.replaceAll(',', '.')
              : m.group(1)!.replaceAll(RegExp(r'[.,]'), '')) ??
          0;
      var amount = (number *
              (['tr', 'trieu'].contains(unit)
                  ? 1000000
                  : ['k', 'nghin', 'ngan'].contains(unit)
                      ? 1000
                      : unit == 'ty'
                          ? 1000000000
                          : 1))
          .round();
      field = collection == 'budgets'
          ? 'limitAmount'
          : collection == 'goals'
              ? 'targetAmount'
              : 'amount';
      if (RegExp(r'\b(tang|giam)\b').hasMatch(text) &&
          !RegExp('thanh|len|xuong|con').hasMatch(text)) {
        amount = ((row[field] as num?)?.toInt() ?? 0) +
            (text.contains('giam') ? -amount : amount);
      }
      value = amount;
    }
    return validate(collection, row['id'].toString(), field, value, data);
  }

  static int _date(dynamic value) => value is num
      ? value.toInt()
      : DateTime.tryParse(value?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;

  static Future<void> apply(String userId, CopilotAction action) async {
    final rows = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: action.collection);
    final current = validate(action.collection, action.id, action.field,
        action.value, {action.collection: rows});
    if (current.before != action.before)
      throw StateError('Bản ghi đã thay đổi. Hãy tạo lại bản nháp.');
    if (action.collection == 'transactions' && action.field == 'amount') {
      final row = rows.firstWhere((r) => r['id'] == action.id);
      if (row['type'] == 'expense') {
        final walletRows = await SupabaseBridge.loadUserCollection(
            userId: userId, collection: 'wallets');
        final wallets = WalletRepository.computeWalletsWithBalances(
            walletRows
                .map((w) => Wallet.fromMap(w['id'].toString(), w))
                .toList(),
            rows
                .map((t) => TransactionModel.fromMap(t['id'].toString(), t))
                .toList());
        final wallet = wallets
            .where((w) => w.id == (row['walletId'] ?? row['fromWalletId']))
            .firstOrNull;
        if (wallet == null) throw StateError('Không tìm thấy ví giao dịch.');
        final delta =
            (action.value as int) - ((row['amount'] as num?)?.toInt() ?? 0);
        if (!wallet.isCreditCard && delta > wallet.balance)
          throw StateError('Ví không đủ số dư cho thay đổi này.');
      }
    }
    // Merge only the approved field; preserve all other metadata and ledger links.
    await SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: action.collection,
        documentId: action.id,
        data: {
          action.field: action.value,
          'updatedAt': DateTime.now().toUtc().toIso8601String()
        });
  }
}
