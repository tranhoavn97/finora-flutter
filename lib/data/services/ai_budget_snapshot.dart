import '../models/transaction.dart';

class AiBudgetSnapshot {
  static List<Map<String, dynamic>> build(List<Map<String, dynamic>> budgets,
      List<TransactionModel> transactions, DateTime now) {
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final selected = <String, Map<String, dynamic>>{};
    DateTime? date(dynamic raw) {
      if (raw is Map && raw['seconds'] is num)
        return DateTime.fromMillisecondsSinceEpoch(
            (raw['seconds'] as num).toInt() * 1000);
      if (raw is num && raw > 0)
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      return DateTime.tryParse(raw?.toString() ?? '');
    }

    for (final b in budgets) {
      if (b['isArchived'] == true) continue;
      final created = date(b['createdAt']);
      final period = b['monthKey']?.toString() ??
          (created == null
              ? ''
              : '${created.year}-${created.month.toString().padLeft(2, '0')}');
      if (period.isNotEmpty && period != month) continue;
      final key = (b['categoryId'] ?? b['categoryName'] ?? b['id']).toString();
      selected.putIfAbsent(key, () => b);
    }
    return selected.values.map((b) {
      final limit =
          num.tryParse('${b['limitAmount'] ?? b['amount'] ?? 0}')?.toDouble() ??
              0;
      final spent = transactions.where((t) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        return t.date > 0 &&
            t.type == 'expense' &&
            d.year == now.year &&
            d.month == now.month &&
            ((b['categoryId'] != null && b['categoryId'] == t.categoryId) ||
                (b['categoryName'] != null &&
                    b['categoryName'].toString().trim().toLowerCase() ==
                        t.categoryName?.trim().toLowerCase()));
      }).fold<int>(0, (s, t) => s + t.amount);
      return {
        ...b,
        'monthKey': month,
        'limitAmount': limit,
        'spent': spent,
        'remainingAmount': (limit - spent).clamp(0, double.infinity),
        'usagePercent': limit > 0 ? spent / limit * 100 : 0
      };
    }).toList();
  }

  static String report(List<Map<String, dynamic>> rows) {
    String money(dynamic value) => '${(value as num).round()}'
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    if (rows.isEmpty) return 'Bạn chưa thiết lập ngân sách nào cho tháng này.';
    return '🎯 **Tình hình ngân sách tháng này:**\n\n' +
        rows
            .map((b) =>
                '• **${b['categoryName'] ?? 'Danh mục'}:** Đã tiêu ${money(b['spent'])}đ / ${money(b['limitAmount'])}đ (${(b['usagePercent'] as num).round()}%)')
            .join('\n');
  }
}
