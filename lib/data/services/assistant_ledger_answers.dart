import '../../core/utils/formatters.dart';
import '../../domain/finance/finance_summary.dart';
import '../models/category.dart';
import '../models/finance_models.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'finora_nlp_engine.dart';

class LedgerAnswer {
  final String text;
  final String contextPrompt;
  const LedgerAnswer(this.text, this.contextPrompt);
}

/// Answers a question from the ledger, preserving explicit time/category filters.
/// The explanation describes measured differences, never guesses their cause.
class AssistantLedgerAnswers {
  static String norm(String text) => FinoraNlpEngine.normalize(text);
  static bool has(String text, String pattern) =>
      RegExp('\\b(?:$pattern)\\b').hasMatch(text);

  static LedgerAnswer answer(
      {required String prompt,
      required String previous,
      required List<TransactionModel> transactions,
      required List<Wallet> wallets,
      required List<Category> categories,
      required List<Budget> budgets,
      required bool budgetsReady,
      required DateTime now}) {
    final q = norm(prompt);
    final follow = has(q,
            'con|the|vay|chi tiet|liet ke|vi sao|tai sao|khoan nao|so sanh|goi y') &&
        previous.isNotEmpty;
    final old = follow ? norm(previous) : '';
    var period = has(q, 'so sanh') && has(q, 'voi thang truoc')
        ? _Period.parse(old, now) ?? _Period.month(now)
        : _Period.parse(q, now);
    period ??= _Period.parse(old, now);
    period ??= _Period.month(now);
    if (period.invalid)
      return LedgerAnswer(
          'Ngày hoặc khoảng thời gian chưa hợp lệ. Bạn ghi rõ **ngày/tháng/năm**, **tháng 9/2026**, hoặc **7 ngày gần đây** để mình tính lại.',
          prompt);

    final names = {
      ...categories.map((c) => c.name),
      ...Category.defaults.map((c) => c.name),
      ...transactions.map((t) => t.categoryName).whereType<String>()
    };
    List<String> findCategories(String text) {
      final found = names
          .where(
              (n) => n.trim().isNotEmpty && has(text, RegExp.escape(norm(n))))
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      return found
          .where((n) => !found
              .any((other) => other != n && norm(other).contains(norm(n))))
          .toList();
    }

    var chosen = findCategories(q);
    if (chosen.isEmpty && !has(q, 'tat ca|toan bo|tong chi|tong thu'))
      chosen = findCategories(old);
    var chosenWallets = wallets
        .where((w) =>
            w.name.trim().isNotEmpty && has(q, RegExp.escape(norm(w.name))))
        .toList();
    if (chosenWallets.isEmpty && !has(q, 'tat ca|toan bo'))
      chosenWallets = wallets
          .where((w) =>
              w.name.trim().isNotEmpty && has(old, RegExp.escape(norm(w.name))))
          .toList();
    if (chosen.length > 1 || chosenWallets.length > 1)
      return LedgerAnswer(
          'Bạn đang nhắc nhiều danh mục hoặc ví. Hãy hỏi riêng từng mục, hoặc ghi **“tất cả”** để mình tổng hợp toàn bộ.',
          prompt);
    final category = chosen.firstOrNull;
    final wallet = chosenWallets.firstOrNull;
    final merchantNames = transactions
        .map((t) => t.merchantName)
        .whereType<String>()
        .where((n) => n.trim().length >= 2)
        .toSet();
    var merchants =
        merchantNames.where((n) => has(q, RegExp.escape(norm(n)))).toList();
    if (merchants.isEmpty && follow && category == null)
      merchants =
          merchantNames.where((n) => has(old, RegExp.escape(norm(n)))).toList();
    if (merchants.length > 1)
      return LedgerAnswer(
          'Bạn muốn xem riêng nơi mua nào? Mình có thể tổng hợp theo từng nơi mua trong sổ.',
          prompt);
    final merchant = merchants.firstOrNull;
    final coffee = has(q, 'cafe|ca phe') ||
        (follow && category == null && has(old, 'cafe|ca phe'));
    final typeText = follow && !has(q, 'thu|chi|tieu|thu nhap|luong') ? old : q;
    final typeIncome = has(typeText, 'thu nhap|tien thu|nhan luong|luong') &&
        !has(typeText, 'thu chi|chi tieu');
    final typeExpense = !typeIncome && !has(typeText, 'thu chi|co cau');
    final ownerText = has(q, 'cua chong|cua anh|cua vo|cua em') ? q : old;
    final owner = has(ownerText, 'cua chong|cua anh')
        ? 'husband'
        : has(ownerText, 'cua vo|cua em')
            ? 'wife'
            : null;
    final filter = [
      if (category != null) category,
      if (coffee) 'Cà phê',
      if (merchant != null) merchant,
      if (wallet != null) wallet.name,
      if (owner != null) owner == 'wife' ? 'Vợ' : 'Chồng'
    ].join(' · ');
    if (has(q, 'tai') &&
        !has(q, 'o dau') &&
        merchant == null &&
        category == null &&
        wallet == null &&
        !coffee) {
      return LedgerAnswer(
          'Mình chưa tìm thấy tên nơi mua này trong sổ. Bạn dùng đúng **tên nơi mua đã lưu**, hoặc hỏi theo danh mục/ví để mình lọc chính xác.',
          prompt);
    }
    final titleScope = '${period.label}${filter.isEmpty ? '' : ' · $filter'}';
    final context =
        '${typeIncome ? 'Thu nhập' : typeExpense ? 'Chi tiêu' : 'Thu chi'} ${period.canonical} $filter ${owner == null ? '' : owner == 'wife' ? 'của vợ' : 'của chồng'}';
    List<TransactionModel> rows(_Period scope) => transactions
        .where((t) =>
            FinanceScope(
                    start: scope.start,
                    end: scope.end,
                    walletId: wallet?.id,
                    owner: owner)
                .contains(t) &&
            (category == null ||
                norm(t.categoryName ?? '') == norm(category)) &&
            (merchant == null ||
                norm(t.merchantName ?? '') == norm(merchant)) &&
            (!coffee ||
                has(
                    norm(
                        '${t.note ?? ''} ${t.categoryName ?? ''} ${t.merchantName ?? ''}'),
                    'cafe|ca phe')))
        .toList();
    final selected = rows(period);
    final summary = FinanceSummary.from(selected);
    final expenses = selected.where(FinanceSummary.isExpense).toList();
    final incomes = selected.where(FinanceSummary.isIncome).toList();
    String metric(String name, int value) => '• **$name:** ${formatVND(value)}';
    String money(int value) => formatVND(value);
    Map<String, int> totals(List<TransactionModel> list) {
      final result = <String, int>{};
      for (final t in list.where(FinanceSummary.isExpense)) {
        final name = t.categoryName ?? 'Chưa có danh mục';
        result[name] = (result[name] ?? 0) + t.amount;
      }
      return result;
    }

    final groups = totals(selected);
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final source =
        '> Số liệu sổ FINORA · ${period.label} (chuyển khoản nội bộ không tính thu/chi).';

    if (has(q, 'ngan sach|vuot han muc')) {
      if (!budgetsReady)
        return LedgerAnswer(
            'Ngân sách chưa tải xong hoặc đang lỗi. Mình chưa thể kết luận còn bao nhiêu hay vượt hạn mức; bạn thử tải lại mục **Ngân sách**.',
            context);
      final monthKey =
          '${period.start.year}-${period.start.month.toString().padLeft(2, '0')}';
      final monthRows = rows(_Period.month(period.start));
      final matching = budgets
          .where((b) =>
              !b.isArchived &&
              b.monthKey == monthKey &&
              (category == null || norm(b.categoryName) == norm(category)))
          .toList();
      if (matching.isEmpty)
        return LedgerAnswer(
            '## Ngân sách · tháng ${period.start.month}/${period.start.year}\nChưa thiết lập ngân sách${category == null ? '' : ' cho **$category**'} trong tháng này (đặt tại **Kế hoạch → Ngân sách**).',
            context);
      final lines = matching.map((b) {
        final spent = monthRows
            .where((t) =>
                FinanceSummary.isExpense(t) &&
                ((b.categoryId.isNotEmpty && t.categoryId == b.categoryId) ||
                    norm(t.categoryName ?? '') == norm(b.categoryName)))
            .fold<int>(0, (s, t) => s + t.amount);
        final percent =
            b.limitAmount > 0 ? (spent / b.limitAmount * 100).round() : 0;
        return '• **${b.categoryName}:** Đã chi ${money(spent)} / ${money(b.limitAmount)} ($percent%) · '
            '${spent > b.limitAmount ? 'Vượt **${money(spent - b.limitAmount)}**.' : 'Còn **${money(b.limitAmount - spent)}**.'}';
      }).join('\n');
      return LedgerAnswer(
          '## Ngân sách · tháng ${period.start.month}/${period.start.year}\n$lines\n\n> Tính theo ngân sách đã lưu${wallet == null ? '' : ' (lọc ví ${wallet.name})'}.',
          context);
    }

    if (has(q, 'so sanh|tang|vi sao|tai sao') ||
        (has(q, 'giam') && !has(q, 'cat giam|tiet kiem|goi y|toi uu'))) {
      final priorPeriod = period.previous();
      final priorRows = rows(priorPeriod);
      final priorSummary = FinanceSummary.from(priorRows);
      final currentAmount = typeIncome ? summary.income : summary.expense;
      final priorAmount =
          typeIncome ? priorSummary.income : priorSummary.expense;
      final delta = currentAmount - priorAmount;
      final beforeGroups = totals(priorRows);
      final changes = {...groups.keys, ...beforeGroups.keys}
          .map((n) => MapEntry(n, (groups[n] ?? 0) - (beforeGroups[n] ?? 0)))
          .toList()
        ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
      final contributions = typeIncome
          ? ''
          : changes
              .where((e) => e.value != 0)
              .take(4)
              .map((e) =>
                  '• **${e.key}:** ${e.value > 0 ? 'tăng' : 'giảm'} ${money(e.value.abs())} (${money(beforeGroups[e.key] ?? 0)} → ${money(groups[e.key] ?? 0)})')
              .join('\n');
      return LedgerAnswer(
          '## ${typeIncome ? 'Thu nhập' : 'Chi tiêu'} thay đổi thế nào?${filter.isEmpty ? '' : ' · $filter'}\n'
          '${metric(period.label, currentAmount)}\n${metric(priorPeriod.label, priorAmount)}\n'
          '${metric(delta >= 0 ? 'Tăng' : 'Giảm', delta.abs())}\n\n'
          '${delta == 0 ? 'Tổng tiền không đổi giữa hai kỳ.' : priorAmount > 0 ? '${delta > 0 ? 'Tăng' : 'Giảm'} **${(delta.abs() / priorAmount * 100).toStringAsFixed(1)}%** so với kỳ trước.' : 'Kỳ trước chưa có khoản tương ứng để tính %.'}\n\n'
          '${contributions.isEmpty ? '' : '### Danh mục chênh lệch chính\n$contributions\n\n'}'
          '> Số liệu thực tế, chưa thể kết luận nguyên nhân mua sắm.',
          context);
    }

    final listing = has(q,
        'nhung gi|nhung khoan|cac khoan|liet ke|chi tiet|giao dich|gan nhat|lon nhat|nhieu nhat|khoan nao');
    if (listing && !has(q, 'danh muc|o dau|nhom nao')) {
      final list = typeIncome
          ? incomes
          : typeExpense
              ? expenses
              : selected
                  .where((t) =>
                      FinanceSummary.isIncome(t) || FinanceSummary.isExpense(t))
                  .toList();
      if (has(q, 'lon nhat|nhieu nhat'))
        list.sort((a, b) => b.amount.compareTo(a.amount));
      else
        list.sort((a, b) => b.date.compareTo(a.date));
      if (list.isEmpty)
        return LedgerAnswer(
            '## ${typeIncome ? 'Khoản thu' : 'Khoản chi'} · $titleScope\nChưa có giao dịch đã ghi trong phạm vi này. $source',
            context);
      final lines = list.take(8).map((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.date);
        return '• **${t.note?.trim().isNotEmpty == true ? t.note : t.categoryName ?? 'Giao dịch'}** — ${money(t.amount)}\n${date.day}/${date.month} · ${t.walletName ?? wallets.where((w) => w.id == t.walletId).firstOrNull?.name ?? 'Chưa gắn ví'}';
      }).join('\n\n');
      return LedgerAnswer(
          '## ${typeIncome ? 'Khoản thu' : 'Khoản chi'} · $titleScope\n'
          '${metric(typeIncome ? 'Tổng thu' : typeExpense ? 'Tổng chi' : 'Tổng thu', typeIncome || !typeExpense ? summary.income : summary.expense)}\n'
          '${!typeExpense && !typeIncome ? '${metric('Tổng chi', summary.expense)}\n' : ''}'
          '**${list.length} giao dịch**${list.length > 8 ? ' · hiển thị 8 khoản ${has(q, 'lon nhat|nhieu nhat') ? 'lớn nhất' : 'gần nhất'}' : ''}\n\n$lines\n\n$source',
          context);
    }

    if (has(q, 'tiet kiem|cat giam|goi y|toi uu')) {
      if (expenses.isEmpty)
        return LedgerAnswer(
            '## Rà soát tiết kiệm · $titleScope\nChưa có khoản chi để xác định nơi có thể giảm. Hãy ghi đủ chi tiêu trước khi đặt mục tiêu.',
            context);
      final largest = [...expenses]
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final top = sorted.first;
      final percent =
          summary.expense > 0 ? top.value / summary.expense * 100 : 0;
      return LedgerAnswer(
          '## Nên rà soát khoản nào? · $titleScope\n${metric('Tổng chi', summary.expense)}\n'
          '**${top.key}** đang chi nhiều nhất: **${money(top.value)}**, chiếm **${percent.toStringAsFixed(1)}%**, gồm **${expenses.where((t) => (t.categoryName ?? 'Chưa có danh mục') == top.key).length} khoản**.\n\n'
          '### Bắt đầu từ khoản lớn\n${largest.take(3).map((t) => '• **${t.note ?? t.categoryName ?? 'Khoản chi'}:** ${money(t.amount)}').join('\n')}\n\n'
          '### Nếu giảm 10% nhóm ${top.key}\nCó thể giảm **${money((top.value * .1).round())}** trong một kỳ tương tự. Đây là kịch bản để bạn cân nhắc; chỉ áp dụng cho phần chi linh hoạt, chưa biết khoản nào là bắt buộc.\n\n$source',
          context);
    }

    final ranking = sorted
        .take(5)
        .map((e) =>
            '• **${e.key}:** ${money(e.value)} · ${summary.expense > 0 ? (e.value / summary.expense * 100).toStringAsFixed(1) : '0'}% · ${expenses.where((t) => (t.categoryName ?? 'Chưa có danh mục') == e.key).length} khoản')
        .join('\n');
    final title = typeIncome
        ? 'Thu nhập'
        : typeExpense
            ? 'Chi tiêu'
            : 'Thu chi';
    return LedgerAnswer(
        '## $title · $titleScope\n'
        '${typeIncome || !typeExpense ? '${metric('Tổng thu', summary.income)}\n' : ''}'
        '${!typeIncome ? '${metric('Tổng chi', summary.expense)}\n' : ''}'
        '${!typeIncome && !typeExpense ? '${metric('Chênh lệch', summary.net)}\n' : ''}\n'
        '${(typeIncome ? incomes : expenses).isEmpty ? (summary.income > 0 && !typeIncome ? 'Chưa có khoản chi đã ghi trong phạm vi này.' : 'Chưa có giao dịch đã ghi trong phạm vi này.') : '**${typeIncome ? incomes.length : expenses.length} khoản ${typeIncome ? 'thu' : 'chi'}** · Trung bình **${money(((typeIncome ? summary.income : summary.expense) / (typeIncome ? incomes.length : expenses.length)).round())}/khoản**.\n\n${typeIncome ? '' : '### Chi theo danh mục\n$ranking'}'}\n\n$source',
        context);
  }
}

class _Period {
  final DateTime start, end;
  final String label, canonical;
  final bool invalid;
  const _Period(this.start, this.end, this.label, this.canonical,
      {this.invalid = false});
  factory _Period.month(DateTime d) => _Period(
      DateTime(d.year, d.month),
      DateTime(d.year, d.month + 1),
      'Tháng ${d.month}/${d.year}',
      'tháng ${d.month}/${d.year}');
  bool isCurrentMonth(DateTime now) =>
      start == DateTime(now.year, now.month) &&
      end == DateTime(now.year, now.month + 1);
  _Period previous() {
    if (start.day == 1 &&
        end.day == 1 &&
        DateTime(start.year, start.month + 1) == end)
      return _Period.month(DateTime(start.year, start.month - 1));
    final length = end.difference(start).inDays;
    final from = DateTime(start.year, start.month, start.day - length);
    return _Period(
        from,
        start,
        '${from.day}/${from.month}/${from.year}–${start.subtract(const Duration(days: 1)).day}/${start.subtract(const Duration(days: 1)).month}/${start.subtract(const Duration(days: 1)).year}',
        '');
  }

  static _Period? parse(String q, DateTime now) {
    if (q.isEmpty) return null;
    if (RegExp(r'\d{1,2}/\d{1,2}/\d{1,3}(?!\d)').hasMatch(q))
      return _Period(now, now, '', '', invalid: true);
    final date = RegExp(r'\b(?:ngay\s*)?(\d{1,2})/(\d{1,2})(?:/(\d{4}))?\b')
        .firstMatch(q);
    // Month/year has only one slash and is preceded by "thang".
    final month =
        RegExp(r'\bthang\s+(\d{1,2})(?:[/\-](\d{4}))?\b').firstMatch(q);
    if (month != null) {
      final m = int.parse(month[1]!),
          y = int.tryParse(month[2] ?? '') ?? now.year;
      final d = DateTime(y, m);
      return m < 1 || m > 12
          ? _Period(now, now, '', '', invalid: true)
          : _Period.month(d);
    }
    if (date != null) {
      final day = int.parse(date[1]!),
          m = int.parse(date[2]!),
          y = int.tryParse(date[3] ?? '') ?? now.year;
      final d = DateTime(y, m, day);
      if (d.day != day || d.month != m || d.year != y)
        return _Period(now, now, '', '', invalid: true);
      return _Period(
          d, DateTime(y, m, day + 1), 'Ngày $day/$m/$y', 'ngày $day/$m/$y');
    }
    if (AssistantLedgerAnswers.has(q, 'thang truoc'))
      return _Period.month(DateTime(now.year, now.month - 1));
    if (AssistantLedgerAnswers.has(q, 'thang nay')) return _Period.month(now);
    final n =
        RegExp(r'\b(\d{1,3}) ngay (?:gan day|vua qua|qua)\b').firstMatch(q);
    if (n != null) {
      final count = int.parse(n[1]!);
      if (count < 1 || count > 366)
        return _Period(now, now, '', '', invalid: true);
      final start = DateTime(now.year, now.month, now.day - count + 1),
          end = DateTime(now.year, now.month, now.day + 1);
      return _Period(start, end, '$count ngày gần đây', '$count ngày gần đây');
    }
    if (AssistantLedgerAnswers.has(q, 'tuan nay|tuan truoc')) {
      final start = DateTime(now.year, now.month,
          now.day - now.weekday + 1 - (q.contains('tuan truoc') ? 7 : 0));
      final end = q.contains('tuan truoc')
          ? DateTime(start.year, start.month, start.day + 7)
          : DateTime(now.year, now.month, now.day + 1);
      return _Period(
          start,
          end,
          '${q.contains('tuan truoc') ? 'Tuần trước' : 'Tuần này'} · ${start.day}/${start.month}–${end.subtract(const Duration(days: 1)).day}/${end.subtract(const Duration(days: 1)).month}',
          q.contains('tuan truoc') ? 'tuần trước' : 'tuần này');
    }
    if (AssistantLedgerAnswers.has(q, 'hom nay|hom qua|hom kia')) {
      final days = q.contains('hom kia')
          ? 2
          : q.contains('hom qua')
              ? 1
              : 0;
      final d = DateTime(now.year, now.month, now.day - days);
      return _Period(
          d,
          DateTime(d.year, d.month, d.day + 1),
          'Ngày ${d.day}/${d.month}/${d.year}',
          'ngày ${d.day}/${d.month}/${d.year}');
    }
    return null;
  }
}
