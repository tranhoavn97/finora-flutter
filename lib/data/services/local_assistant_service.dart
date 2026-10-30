import '../models/category.dart';
import '../models/finance_models.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'ai_finance_reply.dart';
import 'assistant_ledger_answers.dart';
import 'finora_nlp_engine.dart';

class LocalAssistantReply {
  final String text;
  final List<SmartTransactionParsed> transactions;
  final String? contextPrompt;
  const LocalAssistantReply(this.text,
      [this.transactions = const [], this.contextPrompt]);
}

/// Deterministic, on-device assistant. No network, credentials or ledger writes.
class LocalAssistantService {
  static const help = '## Trợ lí FINORA · Ngắn gọn & Trọng tâm\n'
      'Xử lý thu chi trực tiếp trên máy, không phải ChatGPT.\n\n'
      '• **Ghi nhanh:** nhập “Ăn trưa 45k” hoặc “Nhận lương 8tr” (mỗi khoản 1 dòng).\n'
      '• **Tra cứu:** hỏi thu chi hôm nay, tuần này, tháng này/trước theo danh mục, ví, nơi mua.\n'
      '• **Phân tích:** xem số dư ví, nợ thẻ, so sánh 2 tháng, gợi ý tiết kiệm.\n\n'
      'Kiểm tra số tiền, ví, danh mục rồi bấm **Lưu**.';

  static String _norm(String value) => FinoraNlpEngine.normalize(value);
  static bool _has(String text, String pattern) =>
      RegExp('\\b(?:$pattern)\\b').hasMatch(text);

  // Explicit units avoid interpreting dates, quantities and account numbers as money.
  static final _money = RegExp(
      r'(?<![\w.,])(?:\d+\s*(?:tr|triệu|trieu)\s*\d{1,3}|\d+(?:[.,]\d+)*\s*(?:triệu|trieu|nghìn|nghin|ngàn|ngan|tr|k|tỷ|ty|vnd|vnđ|đ|dong|đồng))(?!\w)',
      caseSensitive: false);
  static final _date =
      RegExp(r'\b(?:ngay\s*)?(\d{1,2})[/-](\d{1,2})(?:[/-](\d{4}))?\b');

  static LocalAssistantReply reply({
    required String prompt,
    required List<TransactionModel> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
    required bool dataReady,
    required DateTime now,
    String previousPrompt = '',
    List<Budget> budgets = const [],
    bool budgetsReady = false,
  }) {
    final amountOnly = _money.firstMatch(prompt.trim());
    if (amountOnly?.group(0) == prompt.trim() &&
        !_money.hasMatch(previousPrompt) &&
        _has(_norm(previousPrompt),
            'an|uong|cafe|ca phe|mua|chi|nhan luong|nhan tien') &&
        !_has(_norm(previousPrompt),
            'bao nhieu|thu chi|so sanh|so du|chi tieu|huong dan|ngan sach')) {
      prompt = '$previousPrompt $prompt';
    }
    final q = _norm(prompt);
    if (q.isEmpty ||
        RegExp(r'^(chao|hello|hi)[!. ]*$').hasMatch(q) ||
        _has(q, 'xin chao|huong dan|giup do|ban la ai|lam duoc gi')) {
      return const LocalAssistantReply(help);
    }
    if (_has(q, 'cam on')) {
      return const LocalAssistantReply(
          'Rất vui được giúp bạn. Bạn có thể hỏi về thu chi hoặc nhập khoản vừa chi để soạn bản nháp.');
    }
    if (_has(q, 'ngan sach') && _has(q, 'dat|tao|sua|xoa')) {
      return const LocalAssistantReply(
          'Bạn có thể đặt hoặc sửa hạn mức trong **Kế hoạch → Ngân sách**. Mình đọc và phân tích ngân sách đã lưu; chưa thay đổi hạn mức qua chat.');
    }
    final query = prompt.contains('?') ||
        _has(q,
            'bao nhieu|so sanh|thong ke|tong hop|bao cao|kiem tra|xem|goi y|tu van|so du|tong tien|tong tai san|thu chi|phan tich|han muc|no the|sao ke|phan bo|cat giam|mo phong|du bao|ngan sach|nhung gi|nhung khoan|cac khoan|liet ke|chi tiet|nhieu nhat|lon nhat|gan nhat|o dau|vi sao|tai sao|tang|giam|con hom|con thang|con tuan') ||
        (_has(q, 'tiet kiem') && !_has(q, 'nhan|luong|thu nhap|thu')) ||
        !_money.hasMatch(prompt);
    if (RegExp(r'^(?:hay |giup toi |giup minh )?(?:xoa|sua)\b').hasMatch(q) ||
        _has(q,
            'huy giao dich|chuyen tien|chuyen khoan|chuyen sang|nap vi|rut tien|cho vay|cho muon|vay|tra no|thu no')) {
      return const LocalAssistantReply(
          'Trợ lí hiện chỉ soạn **thu nhập hoặc chi tiêu**. Với chuyển tiền, vay nợ hoặc sửa/xóa, hãy dùng màn giao dịch tương ứng để kiểm tra đủ thông tin. Chưa có dữ liệu nào thay đổi.');
    }
    if (!query &&
        _has(q,
            'ngay mai|tuan sau|thang sau|du dinh|du tinh|se chi|se mua|gia su|neu|chua|khong|vi du')) {
      return const LocalAssistantReply(
          'Mình chưa lập bản nháp từ kế hoạch, giả định hoặc câu phủ định. Hãy nhập riêng khoản đã phát sinh, kèm số tiền và đơn vị, chẳng hạn “Đã chi ăn trưa 45k”.');
    }
    if (!dataReady) {
      return const LocalAssistantReply(
          '## Chưa đủ dữ liệu\nVí, danh mục hoặc giao dịch chưa tải xong hay đang lỗi kết nối. Hãy mở lại sổ giao dịch để tải dữ liệu rồi thử lại. Mình chưa tính tổng hoặc tạo bản nháp từ dữ liệu thiếu.');
    }
    if (!query) return _drafts(prompt, categories, wallets, now);

    final ledgerQuery = _has(q,
        'thu|chi|tieu|luong|thu nhap|so sanh|tiet kiem|bao cao|thong ke|tong hop|phan tich|ngan sach|con hom|con thang|con tuan|vi sao|tai sao|khoan nao|liet ke|chi tiet|tang|giam');
    final followUp =
        previousPrompt.isNotEmpty && RegExp(r'^(?:con|the|vay)\b').hasMatch(q);
    if ((ledgerQuery || followUp) &&
        !_has(q, 'so du|no the|sao ke|phan bo|han muc the')) {
      if (_has(q, 'nam nay|nam truoc|nam sau|ngay mai|thang sau|du bao')) {
        return const LocalAssistantReply(
            'Bạn chọn một ngày, tuần hoặc tháng đã phát sinh để mình đối chiếu sổ; phần này chưa dự báo thu chi tương lai hay tổng hợp cả năm.');
      }
      final answer = AssistantLedgerAnswers.answer(
          prompt: prompt,
          previous: previousPrompt,
          transactions: transactions,
          wallets: wallets,
          categories: categories,
          budgets: budgets,
          budgetsReady: budgetsReady,
          now: now);
      return LocalAssistantReply(answer.text, const [], answer.contextPrompt);
    }
    if (_has(
        q, 'so du|tong tien|tong tai san|the tin dung|no the|sao ke|phan bo')) {
      if (_has(q, 'hom qua|tuan nay|thang nay|thang truoc')) {
        return const LocalAssistantReply(
            'Mình chỉ có thể tổng hợp **số dư ví và nợ thẻ hiện tại**. Chưa hỗ trợ dựng lại số dư tại một ngày trong quá khứ.');
      }
      final report = AiFinanceReply.build(
          prompt: prompt,
          transactions: transactions,
          wallets: wallets,
          budgets: const [],
          now: now);
      if (report != null)
        return LocalAssistantReply(
            '${report.text}\n\nSố liệu từ sổ FINORA đã tải, không phải truy vấn số dư trực tiếp tại ngân hàng.');
    }
    if (!_money.hasMatch(prompt) &&
        _has(q, 'an|uong|cafe|ca phe|mua|chi|nhan luong|nhan tien')) {
      return LocalAssistantReply(
          'Bạn nhập thêm **số tiền kèm đơn vị** cho khoản **$prompt** nhé. Mình sẽ soạn bản nháp để bạn kiểm tra.',
          const [],
          prompt);
    }
    return const LocalAssistantReply(
        'Mình chưa hiểu yêu cầu này. Bạn thử **“Thu chi tháng này”**, **“Số dư từng ví”** hoặc nhập khoản đã phát sinh như **“Ăn trưa 45k”**. Câu chat tự do và dự báo phức tạp chưa được hỗ trợ.');
  }

  static LocalAssistantReply _drafts(String prompt, List<Category> categories,
      List<Wallet> wallets, DateTime now) {
    final drafts = <SmartTransactionParsed>[];
    // A comma can be a decimal separator; only explicit lines/semicolons split entries.
    final lines = prompt
        .split(RegExp(r'[;\n]|(?<!\d),(?!\d)|\s+và\s+', caseSensitive: false))
        .where((p) => p.trim().isNotEmpty);
    if (lines.length > 10)
      return const LocalAssistantReply(
          'Mỗi lần hãy nhập tối đa 10 khoản, mỗi khoản một dòng.');
    for (final line in lines) {
      final q = _norm(line);
      final dates = _date.allMatches(q).toList();
      if (RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{1,3}(?!\d)').hasMatch(q)) {
        return const LocalAssistantReply(
            'Hãy ghi năm bằng bốn chữ số, ví dụ 20/10/2026. Chưa tạo bản nháp.');
      }
      if (dates.length > 1 ||
          _has(
              q, r'thang nay|thang truoc|tuan nay|thu \d|ngay \d+(?![/\d-])')) {
        return const LocalAssistantReply(
            'Hãy ghi ngày cụ thể dạng **ngày/tháng/năm**, hoặc “hôm nay”, “hôm qua”. Chưa tạo bản nháp vì ngày chưa rõ.');
      }
      DateTime date = FinoraNlpEngine.parseTransactionDate(line, now: now);
      if (dates.isNotEmpty) {
        final match = dates.single;
        final day = int.parse(match[1]!);
        final month = int.parse(match[2]!);
        final year = int.tryParse(match[3] ?? '') ?? now.year;
        date = DateTime(year, month, day, 12);
        if (date.year != year || date.month != month || date.day != day) {
          return const LocalAssistantReply(
              'Ngày không hợp lệ. Hãy kiểm tra ngày/tháng/năm rồi nhập lại.');
        }
      }
      if (date.isAfter(DateTime(now.year, now.month, now.day + 1))) {
        return const LocalAssistantReply(
            'Ngày này ở tương lai. Trợ lí chỉ soạn khoản đã phát sinh; hãy kiểm tra ngày.');
      }
      final amounts = _money.allMatches(line).toList();
      if (amounts.length != 1 ||
          line.contains('+') ||
          RegExp(r'[-−]\s*\d').hasMatch(
              line.replaceAll(RegExp(r'\d{1,2}-\d{1,2}(?:-\d{4})?'), ''))) {
        return const LocalAssistantReply(
            'Chưa tạo bản nháp. Mỗi dòng cần **một số tiền có đơn vị** (45k, 2tr5, 50.000đ) và nội dung thu/chi. Hãy tách riêng các khoản, không nhập phép tính.');
      }
      final amountText = amounts.single.group(0)!;
      final amount = _parseExplicitAmount(amountText);
      final hasIncome = _has(
          q, 'nhan|luong|thuong|thu nhap|hoan tien|ban hang|thu|duoc tang');
      final hasExpense = _has(q,
          'chi|mua|an|uong|cafe|ca phe|tra tien|thanh toan|do xang|xang|gui xe');
      if ((!hasIncome && !hasExpense) ||
          (hasIncome && hasExpense) ||
          amount <= 0 ||
          amount > 1000000000000) {
        return const LocalAssistantReply(
            'Chưa rõ khoản thu hay chi hoặc số tiền chưa hợp lệ. Hãy nhập rõ **“Chi … 45k”** hoặc **“Nhận lương 8tr”**.');
      }
      final type = hasIncome ? 'income' : 'expense';
      final category = FinoraNlpEngine.matchCategoryName(
          line,
          type,
          categories
              .where((c) => !c.isArchived && c.categoryGroup == type)
              .toList());
      // Never infer a wallet by a shared token, owner, or the first item.
      final matches = wallets
          .where((w) =>
              w.name.trim().isNotEmpty && _has(q, RegExp.escape(_norm(w.name))))
          .toList();
      drafts.add(SmartTransactionParsed(
          type: type,
          amount: amount,
          note: line.trim(),
          categoryName: category,
          walletName: matches.length == 1 ? matches.single.name : null,
          date: date.millisecondsSinceEpoch));
    }
    return LocalAssistantReply(
        '## Kiểm tra bản nháp\nĐã soạn **${drafts.length} khoản** (chưa ghi vào sổ). Chọn ví, danh mục rồi bấm **Lưu**.',
        drafts);
  }

  static int _parseExplicitAmount(String text) {
    final raw = _norm(text).replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^\d+(?:tr|trieu)\d{1,3}$').hasMatch(raw)) {
      return FinoraNlpEngine.parseMoney(raw);
    }
    final match =
        RegExp(r'^(\d+(?:[.,]\d+)*)(k|nghin|ngan|tr|trieu|ty|vnd|d|dong)$')
            .firstMatch(raw);
    if (match == null) return 0;
    final number = match[1]!;
    final unit = match[2]!;
    final multiplier = switch (unit) {
      'k' || 'nghin' || 'ngan' => 1000,
      'tr' || 'trieu' => 1000000,
      'ty' => 1000000000,
      _ => 1,
    };
    // For VND only grouped thousands or plain whole dong are supported.
    if (multiplier == 1) {
      if (RegExp(r'^\d+$').hasMatch(number)) return int.tryParse(number) ?? 0;
      if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(number) ||
          RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(number)) {
        return int.tryParse(number.replaceAll(RegExp('[.,]'), '')) ?? 0;
      }
      return 0;
    }
    // Compact units use one decimal separator, never grouped thousands.
    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(number)) return 0;
    final value = double.tryParse(number.replaceAll(',', '.'));
    if (value == null || !value.isFinite || value * multiplier > 1000000000000)
      return 0;
    return (value * multiplier).round();
  }
}
