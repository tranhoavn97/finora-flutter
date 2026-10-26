import 'dart:math' as math;
import '../../core/utils/formatters.dart';
import '../../domain/finance/finance_summary.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'ai_budget_snapshot.dart';
import 'finora_nlp_engine.dart';

class AiFinanceReply {
  final String text;
  final List<String> chips;
  const AiFinanceReply(this.text, [this.chips = const []]);

  /// Exact ledger reports do not depend on a remote language model.
  static AiFinanceReply? build(
      {required String prompt,
      required List<TransactionModel> transactions,
      required List<Wallet> wallets,
      required List<Map<String, dynamic>> budgets,
      required DateTime now,
      String previousPrompt = ''}) {
    final q = FinoraNlpEngine.normalize(prompt);
    final month = transactions.where(FinanceScope.month(now).contains).toList();
    final summary = FinanceSummary.from(month);
    final cash = wallets.where((w) => !w.isCreditCard).toList();
    final cards = wallets.where((w) => w.isCreditCard).toList();
    final balance = cash.fold<int>(0, (s, w) => s + w.balance);
    final debt = cards.fold<int>(0, (s, w) => s + w.currentDebt);
    String money(int value) => formatVND(value);
    String line(String label, int value) => '• $label: **${money(value)}**';
    const overviewChips = ['Kiểm tra số dư từng ví', 'Rà soát nợ thẻ tín dụng'];
    Map<String, int> totals(Iterable<TransactionModel> txs) {
      final result = <String, int>{};
      for (final t in txs.where(FinanceSummary.isExpense)) {
        final name = t.categoryName ?? 'Khác';
        result[name] = (result[name] ?? 0) + t.amount;
      }
      return result;
    }

    final categories = totals(month);
    String? category(String query) {
      for (final name in categories.keys) {
        if (query.contains(FinoraNlpEngine.normalize(name))) return name;
      }
      return null;
    }

    final selected = category(q);
    // Mutations need a specific draft and explicit confirmation, never a report.
    if (RegExp(r'\b(dat|tao)\b').hasMatch(q) && q.contains('ngan sach')) {
      final lastCategory =
          selected ?? category(FinoraNlpEngine.normalize(previousPrompt));
      return AiFinanceReply(lastCategory == null
          ? 'Bạn muốn đặt ngân sách cho **danh mục nào**, với **hạn mức bao nhiêu**?\n\nVí dụ: “Đặt ngân sách ăn uống 3 triệu tháng này”. Chưa có dữ liệu nào được thay đổi.'
          : 'Bạn muốn đặt hạn mức cho **$lastCategory** là bao nhiêu?\n\nChưa có ngân sách nào được tạo. Bạn có thể thiết lập trong trang **Ngân sách**.');
    }
    if (q.contains('the tin dung') ||
        q.contains('no the') ||
        q.contains('sao ke') ||
        q.contains('cham tran')) {
      if (cards.isEmpty)
        return const AiFinanceReply(
            'Bạn chưa có thẻ tín dụng trong danh sách ví.');
      final limit = cards.fold<int>(0, (s, w) => s + w.creditLimit);
      final rows = cards.map((w) {
        final used = w.creditLimit > 0
            ? '${(w.currentDebt / w.creditLimit * 100).round()}%'
            : 'chưa có hạn mức';
        return '### ${w.name}\n${line('Dư nợ', w.currentDebt)}\n${line('Còn khả dụng trên thẻ', math.max(0, w.creditLimit - w.currentDebt))}\n'
            'Hạn mức ${money(w.creditLimit)} · Đã dùng $used\nNgày sao kê: ${w.statementDay} · Ngày hạn thanh toán cài đặt: ${w.paymentDueDay}';
      }).join('\n\n');
      return AiFinanceReply(
          '## Nợ thẻ tín dụng\n${line('Tổng dư nợ', debt)}\n${line('Tổng hạn mức', limit)}\n\n$rows\n\n'
          'Hạn mức còn lại là khả năng vay trên thẻ, không phải tiền sẵn có. Ngày thanh toán trên đây là cấu hình thẻ; hãy đối chiếu sao kê ngân hàng.',
          ['Phân bổ dòng tiền an toàn', 'Kiểm tra số dư từng ví']);
    }
    if (q.contains('phan bo') ||
        q.contains('50/30/20') ||
        q.contains('dong tien an toan')) {
      final reserve = math.max(0, balance - math.max(0, debt)).toInt();
      final body = summary.income > 0
          ? 'Gợi ý theo **thu nhập đã ghi nhận tháng này** (${money(summary.income)}):\n'
              '${line('Thiết yếu · 50%', (summary.income * .5).round())}\n'
              '${line('Linh hoạt · 30%', (summary.income * .3).round())}\n'
              '${line('Tích lũy · 20%', (summary.income * .2).round())}\n\n'
              '${summary.net < 0 ? 'Tháng này đang thâm hụt ${money(-summary.net)}. Ưu tiên kiểm tra khoản chi lớn trước khi đặt mục tiêu tích lũy.' : 'Đây là khung tham khảo, cần điều chỉnh theo chi phí bắt buộc thực tế.'}'
          : 'Chưa có thu nhập được ghi nhận tháng này để chia theo tỷ lệ 50/30/20. Số dư ví không được coi là thu nhập.';
      return AiFinanceReply(
          '## Phân bổ dòng tiền\n${line('Tiền trong ví', balance)}\n${line('Dư nợ thẻ', debt)}\n'
          '${line('Còn lại nếu dành tiền trả toàn bộ nợ thẻ', reserve)}\n\n$body',
          ['Cơ cấu thu chi tháng này', 'Rà soát nợ thẻ tín dụng']);
    }
    if (q.contains('so du') && !q.contains('30 ngay') ||
        q.contains('tong tai san') ||
        q.contains('tong tien')) {
      if (wallets.isEmpty)
        return const AiFinanceReply('Chưa có ví để tổng hợp số dư.');
      return AiFinanceReply(
          '## Số dư ví hiện tại\n${line('Tiền khả dụng', balance)}\n'
          '${line('Dư nợ thẻ', debt)}\n${line('Tài sản ròng', balance - debt)}\n\n'
          '### Tiền mặt & tài khoản\n${cash.map((w) => line(w.name, w.balance)).join('\n')}\n\n'
          'Thẻ tín dụng được tách ở mục dư nợ, không cộng vào tiền khả dụng.',
          ['Rà soát nợ thẻ tín dụng', 'Phân bổ dòng tiền an toàn']);
    }
    if (q.contains('so sanh') || q.contains('thang truoc')) {
      final prior = transactions
          .where(FinanceScope.month(DateTime(now.year, now.month - 1)).contains)
          .toList();
      final chosen =
          selected ?? category(FinoraNlpEngine.normalize(previousPrompt));
      final current =
          chosen == null ? summary.expense : categories[chosen] ?? 0;
      final old = chosen == null
          ? FinanceSummary.from(prior).expense
          : totals(prior)[chosen] ?? 0;
      final delta = current - old;
      return AiFinanceReply(
          '## So sánh ${chosen ?? 'chi tiêu'}\n'
          '${line('Tháng ${now.month}/${now.year}', current)}\n'
          '${line('Tháng ${DateTime(now.year, now.month - 1).month}/${DateTime(now.year, now.month - 1).year}', old)}\n\n'
          '${delta == 0 ? 'Không thay đổi.' : '${delta > 0 ? 'Tăng' : 'Giảm'} **${money(delta.abs())}**${old > 0 ? ' (${(delta.abs() / old * 100).round()}%)' : '; chưa có mức chi tháng trước để tính tỷ lệ'}.'}\n'
          'Tháng hiện tại chưa kết thúc; đây là so sánh số liệu đã ghi nhận.',
          overviewChips);
    }
    if (q.contains('ngan sach') &&
        !RegExp('goi y|tu van|lich su').hasMatch(q)) {
      return AiFinanceReply(
          '## Ngân sách tháng ${now.month}/${now.year}\n\n${AiBudgetSnapshot.report(budgets)}',
          ['Cơ cấu thu chi tháng này', 'Phân bổ dòng tiền an toàn']);
    }
    if (q.contains('hom nay') && RegExp('chi|tieu').hasMatch(q)) {
      final start = DateTime(now.year, now.month, now.day);
      final txs = transactions
          .where((t) =>
              t.date >= start.millisecondsSinceEpoch &&
              t.date <
                  start.add(const Duration(days: 1)).millisecondsSinceEpoch)
          .toList();
      final spent = FinanceSummary.from(txs).expense;
      final items = totals(txs);
      return AiFinanceReply(
          '## Chi tiêu hôm nay\n${line('Tổng đã chi', spent)}\n\n${items.entries.map((e) => line(e.key, e.value)).join('\n')}',
          ['Cơ cấu thu chi tháng này', 'Kiểm tra số dư từng ví']);
    }
    if (q.contains('30 ngay') &&
        (q.contains('mo phong') || q.contains('so du'))) {
      final dailyNet = summary.net / now.day;
      return AiFinanceReply(
          '## Mô phỏng 30 ngày\n${line('Số dư hiện tại', balance)}\n'
          '${line('Số dư mô phỏng', balance + (dailyNet * 30).round())}\n\n'
          'Giả định thu chi mỗi ngày giữ bằng trung bình ${now.day} ngày đầu tháng. Đây là mô phỏng, chưa tính lịch lương, trả nợ, chuyển tiền hoặc khoản phát sinh tương lai.',
          overviewChips);
    }
    if (selected != null && RegExp('chi|tieu|thang nay').hasMatch(q)) {
      final spent = categories[selected]!;
      final percent =
          summary.expense > 0 ? (spent / summary.expense * 100).round() : 0;
      return AiFinanceReply(
          '## $selected · tháng ${now.month}/${now.year}\n'
          '${line('Đã chi', spent)}\nChiếm **$percent%** tổng chi tiêu tháng.\n\n'
          'Số liệu tính từ giao dịch đã ghi nhận trong tháng.',
          ['So sánh với tháng trước', 'Tình hình ngân sách tháng này']);
    }
    if (RegExp('thu chi|chi tieu|tiet kiem|de danh|cat giam').hasMatch(q)) {
      final sorted = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final result = summary.net >= 0 ? 'Thặng dư' : 'Thâm hụt';
      return AiFinanceReply(
          '## Thu chi tháng ${now.month}/${now.year}\n'
          '${line('Thu nhập', summary.income)}\n${line('Chi tiêu', summary.expense)}\n${line(result, summary.net.abs())}\n\n'
          '${sorted.isEmpty ? 'Chưa có khoản chi được ghi nhận.' : '### Các khoản chi lớn\n${sorted.take(3).map((e) => line(e.key, e.value)).join('\n')}'}\n\n'
          '${summary.net < 0 ? 'Chi đang vượt thu đã ghi nhận. Kiểm tra thu nhập đã nhập đủ chưa và rà soát khoản chi lớn nhất trước.' : summary.income == 0 ? 'Chưa có thu nhập để tính tỷ lệ tiết kiệm.' : 'Tỷ lệ còn lại trên thu nhập đã ghi nhận: ${(summary.net / summary.income * 100).round()}%.'}',
          ['So sánh với tháng trước', 'Tình hình ngân sách tháng này']);
    }
    return null;
  }
}
