import 'dart:math';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/finance_models.dart';
import 'ai_service.dart';

class FinoraNlpEngine {
  /// Chuẩn hóa tiếng Việt (bỏ dấu, chuyển chữ thường) để so khớp từ khóa
  static String normalize(String input) {
    var str = input.toLowerCase().trim();
    const withDiacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  /// Trích xuất số tiền từ chuỗi tiếng Việt (hỗ trợ k, nghìn, triệu, tr, củ, lít, xị, tỷ, phép tính cộng)
  static int parseMoney(String text) {
    final clean = text.toLowerCase().trim();
    if (clean.isEmpty) return 0;

    // Parse a fully grouped currency amount before compact/mixed notation.
    // Otherwise the generic unit expression can start in the middle of
    // `15.500.000đ` and incorrectly return only the trailing `500.000đ`.
    final groupedCurrency = RegExp(
      r'(?<!\d)(\d{1,3}(?:[.,]\d{3})+)(?:\s*(?:đ|vnd|vnđ))?(?!\d)',
      caseSensitive: false,
    ).firstMatch(clean);
    if (groupedCurrency != null) {
      final digits = groupedCurrency.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      final amount = int.tryParse(digits) ?? 0;
      if (amount > 0) return amount;
    }

    // Vietnamese compact mixed notation: 14tr350 = 14.350.000,
    // 2tr5 = 2.500.000. Kept before the generic unit parser.
    final mixedMillion = RegExp(
            r'\b(\d+)\s*(?:tr|triệu|trieu|củ|cu)\s*(\d{1,3})\b',
            caseSensitive: false)
        .firstMatch(clean);
    if (mixedMillion != null) {
      final millions = int.tryParse(mixedMillion.group(1)!) ?? 0;
      final remainder = int.tryParse(mixedMillion.group(2)!) ?? 0;
      return millions * 1000000 + remainder * (remainder < 10 ? 100000 : 1000);
    }

    // 1. Phép tính cộng ví dụ: "15k + 25k", "30 + 45k", "50k+20k"
    final mathReg = RegExp(
        r'(\d+(?:[.,]\d+)?\s*(?:k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi)?(?:\s*\+\s*\d+(?:[.,]\d+)?\s*(?:k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi)?)+)',
        caseSensitive: false);
    final mathMatch = mathReg.firstMatch(clean);
    if (mathMatch != null && mathMatch.group(0)!.contains('+')) {
      final parts = mathMatch.group(0)!.split('+');
      int total = 0;
      for (final p in parts) {
        total += _parseSingleMoneyPart(p.trim());
      }
      if (total > 0) return total;
    }

    // 2. Số tiền có đơn vị (k, tr, triệu, củ, lít, xị, tỷ)
    final unitReg = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi|đ|vnd|vnđ)(?:\s|$|[,.;!?])',
        caseSensitive: false);
    final unitMatch = unitReg.firstMatch(clean);
    if (unitMatch != null) {
      final rawNum = unitMatch.group(1)!.replaceAll(',', '.');
      final numVal = double.tryParse(rawNum) ?? 0.0;
      final unit = unitMatch.group(2)!.toLowerCase();

      if (['k', 'nghìn', 'ngàn', 'ngh'].contains(unit)) {
        return (numVal * 1000).round();
      } else if (['lít', 'lit', 'lốp', 'lop', 'xị', 'xi'].contains(unit)) {
        return (numVal * 100000).round();
      } else if (['tr', 'triệu', 'trieu', 'củ', 'cu', 'chai'].contains(unit)) {
        return (numVal * 1000000).round();
      } else if (['tỷ', 'ty'].contains(unit)) {
        return (numVal * 1000000000).round();
      } else if (['đ', 'vnd', 'vnđ'].contains(unit)) {
        // Dots/commas before a currency suffix are normally Vietnamese
        // thousands separators (50.000đ), not decimal punctuation.
        if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(unitMatch.group(1)!)) {
          return int.tryParse(unitMatch.group(1)!.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
        }
        return numVal.round();
      }
    }

    // 3. Định dạng phân cách hàng nghìn ví dụ: 50.000, 100,000, 1.500.000
    final sepReg =
        RegExp(r'(?:^|\s|[,.;!?])(\d{1,3}(?:[.,]\d{3})+)(?=$|\s|[,.;!?])');
    final sepMatch = sepReg.firstMatch(clean);
    if (sepMatch != null) {
      final digits = sepMatch.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      return int.tryParse(digits) ?? 0;
    }

    // 4. Số thuần tuý ví dụ: "ăn trưa 45", "mua sách 150000"
    final plainReg = RegExp(r'\b\d+\b');
    final plainMatches = plainReg.allMatches(clean);
    for (final m in plainMatches) {
      final val = int.tryParse(m.group(0)!) ?? 0;
      if (val >= 1000) return val;
      if (val > 0 && val < 1000)
        return val * 1000; // Người Việt thường gõ tắt 45 -> 45.000đ
    }

    return 0;
  }

  /// Trích xuất ghi chú sạch sau khi loại bỏ số tiền và đơn vị
  static String extractCleanNote(String text) {
    var note = text.trim();
    final patterns = [
      RegExp(r'\b\d+\s*(?:tr|triệu|trieu|củ|cu)\s*\d{1,3}\b',
          caseSensitive: false),
      RegExp(
          r'(?:^|\s|[,.;!?])\d+(?:[.,]\d+)?\s*(?:k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi)?(?:\s*\+\s*\d+(?:[.,]\d+)?\s*(?:k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi)?)+(?=$|\s|[,.;!?])',
          caseSensitive: false),
      RegExp(
          r'(?:^|\s|[,.;!?])\d+(?:[.,]\d+)?\s*(?:k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi|đ|vnd|vnđ)(?=$|\s|[,.;!?])',
          caseSensitive: false),
      RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b'),
      RegExp(r'\b\d+\s*(?:đ|vnd|vnđ)\b', caseSensitive: false),
    ];

    for (final pat in patterns) {
      note = note.replaceAll(pat, ' ');
    }

    // Xóa bớt từ đệm ví dụ: "tiền mặt", "bằng momo", "vào vcb", "tài khoản"
    final walletFillers = [
      RegExp(
          r'\b(bằng|qua|vao|vào|tu|từ|vi|ví|tk|tai khoan|tài khoản)\s+(tien mat|tiền mặt|momo|zalopay|vcb|vietcombank|tcb|techcombank|mb|mbbank|acb|bidv|vpbank|timo|tpbank)\b',
          caseSensitive: false),
      RegExp(
          r'\b(tien mat|tiền mặt|momo|zalopay|vcb|vietcombank|tcb|techcombank|mb|mbbank|acb|bidv|vpbank|timo|tpbank)\b',
          caseSensitive: false),
    ];
    for (final wf in walletFillers) {
      note = note.replaceAll(wf, ' ');
    }

    // Xóa từ chỉ thời gian đệm
    final timeFillers = [
      RegExp(
          r'\b(sáng nay|trưa nay|chiều nay|tối nay|sáng|trưa|chiều|tối|hôm nay|hôm qua|hom nay|hom qua)\b',
          caseSensitive: false),
    ];
    for (final tf in timeFillers) {
      note = note.replaceAll(tf, ' ');
    }

    // Generic capture verbs/products add no value when a merchant name is
    // already present (e.g. "cafe Highland" -> "Highland").
    note = note.replaceAll(RegExp(r'\b(cafe|ca phe|cà phê)\b', caseSensitive: false), ' ');

    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    note = note.replaceAll(RegExp(r'^[,.;:\s-]+|[,.;:\s-]+$'), '').trim();

    if (note.isEmpty) {
      return text.trim();
    }
    // Viết hoa chữ cái đầu
    return note[0].toUpperCase() + (note.length > 1 ? note.substring(1) : '');
  }

  static int _parseSingleMoneyPart(String p) {
    final unitReg = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngàn|ngh|tr|triệu|trieu|tỷ|ty|củ|cu|chai|lít|lit|lốp|lop|xị|xi)?',
        caseSensitive: false);
    final match = unitReg.firstMatch(p);
    if (match != null) {
      final rawNum = match.group(1)!.replaceAll(',', '.');
      final numVal = double.tryParse(rawNum) ?? 0.0;
      final unit = match.group(2)?.toLowerCase();
      if (unit != null) {
        if (['k', 'nghìn', 'ngàn', 'ngh'].contains(unit))
          return (numVal * 1000).round();
        if (['lít', 'lit', 'lốp', 'lop', 'xị', 'xi'].contains(unit))
          return (numVal * 100000).round();
        if (['tr', 'triệu', 'trieu', 'củ', 'cu', 'chai'].contains(unit))
          return (numVal * 1000000).round();
        if (['tỷ', 'ty'].contains(unit)) return (numVal * 1000000000).round();
      } else {
        if (numVal > 0 && numVal < 1000) return (numVal * 1000).round();
        return numVal.round();
      }
    }
    return 0;
  }

  /// Khớp loại giao dịch (expense, income, transfer, loan)
  static String detectTransactionType(String text) {
    final norm = normalize(text);
    if (norm.contains('luong') ||
        norm.contains('nhan tien') ||
        norm.contains('thu nhap') ||
        norm.contains('thuong') ||
        norm.contains('li xi') ||
        norm.contains('hoan tien') ||
        norm.contains('ban hang') ||
        norm.contains('lai suat') ||
        norm.contains('co tuc') ||
        norm.contains('nhan luong') ||
        norm.contains('duoc tang')) {
      return 'income';
    }
    if (norm.contains('chuyen tien') ||
        norm.contains('chuyen sang') ||
        norm.contains('nap vi') ||
        norm.contains('rut tien')) {
      return 'transfer';
    }
    if (norm.contains('cho vay') ||
        norm.contains('di vay') ||
        norm.contains('muon tien') ||
        norm.contains('tra no')) {
      return 'debt';
    }
    return 'expense';
  }

  /// Khớp danh mục thông minh dựa vào từ khóa tiếng Việt
  static String matchCategoryName(
      String text, String type, List<Category> categories) {
    final norm = normalize(text);

    // User-created categories are the strongest signal. This also supports
    // employer/source categories such as "Windmedia" without hard-coding them.
    final compatible = categories.where((c) => c.categoryGroup == type).toList()
      ..sort((a, b) =>
          normalize(b.name).length.compareTo(normalize(a.name).length));
    for (final cat in compatible) {
      final catNorm = normalize(cat.name);
      if (catNorm.length >= 3 && norm.contains(catNorm)) return cat.name;
    }

    if (type == 'income') {
      if (norm.contains('luong')) {
        return _findBestCatName(['Lương', 'Salary'], categories, 'Lương');
      }
      if (norm.contains('thuong')) return 'Thưởng';
      if (norm.contains('ban hang')) return 'Bán hàng';
      if (norm.contains('lai')) return 'Lãi đầu tư';
      return 'Thu nhập khác';
    }

    // Chi tiêu - Ăn uống
    if (norm.contains('an') ||
        norm.contains('pho') ||
        norm.contains('bun') ||
        norm.contains('com') ||
        norm.contains('cafe') ||
        norm.contains('ca phe') ||
        norm.contains('tra sua') ||
        norm.contains('banh mi') ||
        norm.contains('lau') ||
        norm.contains('nuoc') ||
        norm.contains('uong') ||
        norm.contains('nhau') ||
        norm.contains('snack') ||
        norm.contains('sáng') ||
        norm.contains('trưa') ||
        norm.contains('tối') ||
        norm.contains('an sang') ||
        norm.contains('an trua') ||
        norm.contains('an toi')) {
      return _findBestCatName(
          ['Ăn uống', 'Food', 'Ẩm thực'], categories, 'Ăn uống');
    }

    // Đi lại, xe cộ
    if (norm.contains('xang') ||
        norm.contains('grab') ||
        norm.contains('be') ||
        norm.contains('taxi') ||
        norm.contains('xe') ||
        norm.contains('ve xe') ||
        norm.contains('gui xe') ||
        norm.contains('sua xe') ||
        norm.contains('xang xe') ||
        norm.contains('cau duong')) {
      return _findBestCatName(
          ['Đi lại', 'Di chuyển', 'Giao thông', 'Transport'],
          categories,
          'Đi lại');
    }

    // Mua sắm
    if (norm.contains('mua') ||
        norm.contains('shopee') ||
        norm.contains('tiki') ||
        norm.contains('lazada') ||
        norm.contains('quan ao') ||
        norm.contains('giay') ||
        norm.contains('sach') ||
        norm.contains('sieu thi') ||
        norm.contains('cho') ||
        norm.contains('tap hoa')) {
      return _findBestCatName(
          ['Mua sắm', 'Shopping', 'Siêu thị'], categories, 'Mua sắm');
    }

    // Hóa đơn & Tiện ích
    if (norm.contains('dien') ||
        norm.contains('nuoc') ||
        norm.contains('wifi') ||
        norm.contains('internet') ||
        norm.contains('netflix') ||
        norm.contains('icloud') ||
        norm.contains('nha tro') ||
        norm.contains('tien phong') ||
        norm.contains('hoa don')) {
      return _findBestCatName(
          ['Hóa đơn', 'Tiện ích', 'Nhà ở', 'Bills'], categories, 'Hóa đơn');
    }

    // Giải trí
    if (norm.contains('xem phim') ||
        norm.contains('cinema') ||
        norm.contains('game') ||
        norm.contains('du lich') ||
        norm.contains('ve') ||
        norm.contains('choi')) {
      return _findBestCatName(
          ['Giải trí', 'Entertainment', 'Du lịch'], categories, 'Giải trí');
    }

    // Sức khỏe
    if (norm.contains('thuoc') ||
        norm.contains('kham') ||
        norm.contains('benh vien') ||
        norm.contains('nha khoa') ||
        norm.contains('gym') ||
        norm.contains('bac si')) {
      return _findBestCatName(
          ['Sức khỏe', 'Y tế', 'Thuốc men'], categories, 'Sức khỏe');
    }

    // Giáo dục
    if (norm.contains('hoc') ||
        norm.contains('khoa hoc') ||
        norm.contains('hoc phi') ||
        norm.contains('sach vo')) {
      return _findBestCatName(['Giáo dục', 'Học tập'], categories, 'Giáo dục');
    }

    return _findBestCatName(
        ['Chi tiêu khác', 'Khác', 'General'], categories, 'Chi tiêu');
  }

  static String _findBestCatName(
      List<String> candidates, List<Category> categories, String fallback) {
    for (final cand in candidates) {
      final candNorm = normalize(cand);
      for (final cat in categories) {
        if (normalize(cat.name).contains(candNorm) ||
            candNorm.contains(normalize(cat.name))) {
          return cat.name;
        }
      }
    }
    return fallback;
  }

  /// Khớp tên ví / phương thức thanh toán
  static String? matchWalletName(String text, List<Wallet> wallets) {
    final norm = normalize(text);

    if (wallets.isEmpty) return null;

    // Exact/full wallet names win, then token overlap. Requiring meaningful
    // tokens avoids matching generic words such as "ví" or "của".
    Wallet? bestWallet;
    var bestScore = 0;
    for (final wallet in wallets) {
      final walletNorm = normalize(wallet.name);
      if (walletNorm.length >= 3 && norm.contains(walletNorm))
        return wallet.name;
      final tokens = walletNorm.split(RegExp(r'\s+')).where((t) =>
          t.length >= 3 &&
          !{'tai', 'khoan', 'cua', 'chong', 'vo', 'chung'}.contains(t));
      var score = tokens.where(norm.contains).length * 3;
      final owner = normalize(wallet.owner ?? '');
      if ((norm.contains('chong') &&
              (owner.contains('husband') || owner.contains('chong'))) ||
          (norm.contains('vo') &&
              (owner.contains('wife') || owner.contains('vo')))) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestWallet = wallet;
      }
    }
    if (bestScore >= 3) return bestWallet?.name;

    final walletKeywords = {
      'momo': 'Ví MoMo',
      'zalopay': 'ZaloPay',
      'tien mat': 'Tiền mặt',
      'vcb': 'Vietcombank',
      'vietcombank': 'Vietcombank',
      'tcb': 'Techcombank',
      'techcombank': 'Techcombank',
      'mb': 'MB Bank',
      'mbbank': 'MB Bank',
      'acb': 'ACB',
      'bidv': 'BIDV',
      'vpbank': 'VPBank',
      'timo': 'Timo',
      'tpbank': 'TPBank',
      'the tin dung': 'Thẻ tín dụng',
      'credit': 'Thẻ tín dụng',
    };

    for (final entry in walletKeywords.entries) {
      if (norm.contains(entry.key)) {
        // Tìm ví phù hợp trong danh sách người dùng
        for (final w in wallets) {
          final wNorm = normalize(w.name);
          if (wNorm.contains(entry.key) ||
              normalize(entry.value).contains(wNorm)) {
            return w.name;
          }
        }
        return entry.value;
      }
    }

    // Nếu không khớp từ khóa cụ thể, tìm theo tên ví có sẵn
    for (final w in wallets) {
      if (norm.contains(normalize(w.name))) {
        return w.name;
      }
    }

    // Never silently choose the first wallet: a wrong ledger is worse than an
    // incomplete suggestion. The provider can ask the user to confirm.
    return null;
  }

  /// Understands conversational dates used in Vietnamese transaction notes.
  static DateTime parseTransactionDate(String text, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final norm = normalize(text);
    if (norm.contains('hom qua')) {
      final d = base.subtract(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day, 12);
    }
    if (norm.contains('hom kia')) {
      final d = base.subtract(const Duration(days: 2));
      return DateTime(d.year, d.month, d.day, 12);
    }
    final match =
        RegExp(r'\b(?:ngay\s*)?(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b')
            .firstMatch(norm);
    if (match != null) {
      var year = int.tryParse(match.group(3) ?? '') ?? base.year;
      if (year < 100) year += 2000;
      final month = int.tryParse(match.group(2)!) ?? base.month;
      final day = int.tryParse(match.group(1)!) ?? base.day;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day, 12);
      }
    }
    return DateTime(base.year, base.month, base.day, base.hour, base.minute);
  }

  static String buildSmartNote(
      String phrase, String type, String categoryName, String? walletName) {
    final normalizedPhrase = normalize(phrase);
    if (type == 'expense') {
      if (normalizedPhrase.contains('an sang')) return 'Ăn sáng';
      if (normalizedPhrase.contains('an trua')) return 'Ăn trưa';
      if (normalizedPhrase.contains('an toi')) return 'Ăn tối';
    }
    var note = extractCleanNote(phrase);
    if (walletName != null && walletName.trim().isNotEmpty) {
      note = note.replaceAll(
          RegExp(RegExp.escape(walletName), caseSensitive: false), ' ');
    }
    note = note.replaceAll(
      RegExp(
          r'\b(het|hết|nhan|nhận|duoc|được|vao|vào|bang|bằng|qua|tu|từ|vi|ví|cua|của|chong|chồng|vo|vợ)\b',
          caseSensitive: false),
      ' ',
    );
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (type == 'income' && normalize(phrase).contains('luong')) {
      note = note
          .replaceAll(RegExp(r'^lương\s*', caseSensitive: false), '')
          .trim();
      return note.isEmpty ? 'Lương' : 'Lương $note';
    }
    if (note.isEmpty || normalize(note) == normalize(categoryName))
      return categoryName;
    return note[0].toUpperCase() + note.substring(1);
  }

  /// Tách câu phức thành nhiều giao dịch (ví dụ: "Sáng cafe 35k Momo, trưa ăn cơm 45k, chiều nhận lương 15tr")
  static List<String> splitMultiPhrases(String input) {
    var raw = input.trim();
    // Thay thế các dấu phân cách thông dụng
    raw = raw.replaceAll(RegExp(r'[;\n]'), ',');
    raw = raw.replaceAll(
        RegExp(r'\s+(rồi|sau đó|và|kem theo)\s+', caseSensitive: false), ',');

    final parts = raw.split(',');
    final results = <String>[];

    for (final part in parts) {
      final p = part.trim();
      if (p.isNotEmpty) {
        // Nếu có số tiền trong đoạn này thì đây là một giao dịch
        if (parseMoney(p) > 0) {
          results.add(p);
        } else if (results.isNotEmpty &&
            ['vi ', 'tai khoan', 'bang ', 'qua '].any((marker) =>
                normalize(p).startsWith(marker) ||
                normalize(p).contains(' $marker'))) {
          // A comma often separates the payment source from the transaction:
          // "nhận lương 14tr350, ví tiết kiệm của chồng".
          results[results.length - 1] = '${results.last}, $p';
        }
      }
    }

    if (results.isEmpty && parseMoney(input) > 0) {
      results.add(input);
    }

    return results;
  }

  /// Trích xuất danh sách giao dịch hoàn chỉnh từ tin nhắn của người dùng
  static List<SmartTransactionParsed> extractTransactions({
    required String message,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) {
    final phrases = splitMultiPhrases(message);
    final list = <SmartTransactionParsed>[];

    for (final phrase in phrases) {
      final amount = parseMoney(phrase);
      if (amount <= 0) continue;

      final type = detectTransactionType(phrase);
      final catName = matchCategoryName(phrase, type, categories);
      final walletName = matchWalletName(phrase, wallets);
      final note = buildSmartNote(phrase, type, catName, walletName);

      final norm = normalize(phrase);
      String? owner;
      String? ownerName;
      if (norm.contains('chong') ||
          norm.contains('cho anh') ||
          norm.contains('cua anh') ||
          norm.contains('cua chong')) {
        owner = 'husband';
        ownerName = 'Chồng';
      } else if (norm.contains('vo') ||
          norm.contains('cho em') ||
          norm.contains('cua em') ||
          norm.contains('cua vo')) {
        owner = 'wife';
        ownerName = 'Vợ';
      } else if (norm.contains('chung') ||
          norm.contains('ca nha') ||
          norm.contains('gia dinh')) {
        owner = 'joint';
        ownerName = 'Chung';
      }

      list.add(
        SmartTransactionParsed(
          type: type,
          amount: amount,
          note: note,
          categoryName: catName,
          walletName: walletName,
          owner: owner,
          ownerName: ownerName,
          date: parseTransactionDate(phrase).millisecondsSinceEpoch,
          confidence: walletName == null ? 0.82 : 0.98,
        ),
      );
    }

    return list;
  }

  /// Nhận diện xem người dùng đang hỏi thông tin (Query) hay ghi chép (Transaction)
  static bool isFinancialQuery(String text) {
    final norm = normalize(text);
    return norm.contains('tieu gi') ||
        norm.contains('hom nay') &&
            (norm.contains('chi') ||
                norm.contains('tieu') ||
                norm.contains('bao nhieu')) ||
        norm.contains('thang nay') &&
            (norm.contains('chi') ||
                norm.contains('tieu') ||
                norm.contains('thu')) ||
        norm.contains('ngan sach') ||
        norm.contains('han muc') ||
        norm.contains('suc khoe') ||
        norm.contains('diem tai chinh') ||
        norm.contains('so du') ||
        norm.contains('tong tien') ||
        norm.contains('tong tai san') ||
        norm.contains('tiet kiem') ||
        norm.contains('loi khuyen') ||
        norm.contains('tu van') ||
        norm.contains('bao cao') ||
        norm.contains('thong ke') ||
        norm.contains('giup do') ||
        norm.contains('huong dan');
  }

  /// Sinh câu trả lời phân tích tài chính dựa trên dữ liệu ngữ cảnh (financeContext)
  static SmartChatResult generateFinancialAdvice({
    required String query,
    Map<String, dynamic>? financeContext,
    List<Category> categories = const [],
    List<Wallet> wallets = const [],
  }) {
    final norm = normalize(query);

    // 1. Chào hỏi / Giới thiệu
    if (norm == 'chao' ||
        norm == 'xin chao' ||
        norm.contains('ban la ai') ||
        norm.contains('huong dan') ||
        norm.contains('giup')) {
      return SmartChatResult(
        intent: 'greeting',
        replyText:
            'Xin chào! Tôi là **Finora AI Copilot** — trợ lý tài chính thông minh của bạn 🌟\n\n'
            'Tôi có thể giúp bạn:\n'
            '• **Ghi chép siêu tốc**: Gõ hoặc nói *"Ăn phở 45k tiền mặt"*, *"Cafe 35k Momo, lương 15tr VCB"*\n'
            '• **Quét hóa đơn**: Bấm biểu tượng 📷 camera để đọc hóa đơn / bill tự động\n'
            '• **Hỏi đáp chi tiêu**: *"Hôm nay tôi đã tiêu gì?"*, *"Tháng này chi ăn uống bao nhiêu?"*\n'
            '• **Tư vấn tài chính**: *"Gợi ý ngân sách 50/30/20"*, *"Đánh giá sức khỏe tài chính"*\n\n'
            'Bạn muốn Finora hỗ trợ gì ngay bây giờ?',
        transactions: [],
      );
    }

    // 2. Hôm nay tiêu gì?
    if (norm.contains('hom nay') &&
        (norm.contains('tieu') ||
            norm.contains('chi') ||
            norm.contains('mua'))) {
      final txs =
          (financeContext?['recentTransactions'] as List<dynamic>?) ?? [];
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final todayTxs = txs.where((t) {
        final date = t['date'] as int? ?? 0;
        return date >= todayStart;
      }).toList();

      int todayExpense = 0;
      final items = <String>[];

      for (final t in todayTxs) {
        final amt = (t['amount'] as num?)?.toInt() ?? 0;
        final type = t['type'] as String? ?? 'expense';
        final title = t['title'] as String? ?? 'Khoản chi';
        if (type == 'expense') {
          todayExpense += amt;
          items.add('• **$title**: ${_formatVND(amt)}');
        }
      }

      if (items.isEmpty) {
        return SmartChatResult(
          intent: 'daily_summary',
          replyText:
              '📊 **Tổng kết hôm nay** (${now.day}/${now.month}/${now.year}):\n\n'
              'Hôm nay bạn chưa có khoản chi tiêu nào được ghi nhận! 🎉\n\n'
              '💡 *Mẹo: Khi ăn uống hay mua sắm, bạn chỉ cần chat ví dụ "Trưa ăn cơm 40k" để Finora lưu tự động nhé.*',
          transactions: [],
        );
      }

      return SmartChatResult(
        intent: 'daily_summary',
        replyText:
            '📊 **Tổng kết chi tiêu hôm nay** (${now.day}/${now.month}/${now.year}):\n\n'
            '• **Tổng chi hôm nay**: ${_formatVND(todayExpense)}\n'
            '• **Chi tiết các khoản**:\n${items.join('\n')}\n\n'
            '✨ *Tình trạng: Chi tiêu trong ngày ở mức ổn định.*',
        transactions: [],
      );
    }

    // 3. Gợi ý hạn mức ngân sách (Quy tắc 50/30/20)
    if (norm.contains('ngan sach') ||
        norm.contains('50/30/20') ||
        norm.contains('han muc')) {
      final totalBalance =
          (financeContext?['balance'] as num?)?.toInt() ?? 10000000;
      final incomeEst = max(totalBalance, 12000000);

      final needs = (incomeEst * 0.50).round();
      final wants = (incomeEst * 0.30).round();
      final savings = (incomeEst * 0.20).round();

      return SmartChatResult(
        intent: 'budget_advice',
        replyText: '🎯 **Gợi ý phân bổ ngân sách chuẩn 50/30/20**:\n\n'
            '1. **Thiết yếu (50%) ~ ${_formatVND(needs)}**:\n'
            '   • Ăn uống: ~ ${_formatVND((needs * 0.6).round())}\n'
            '   • Nhà ở & Hóa đơn: ~ ${_formatVND((needs * 0.25).round())}\n'
            '   • Đi lại, xăng xe: ~ ${_formatVND((needs * 0.15).round())}\n\n'
            '2. **Linh hoạt & Giải trí (30%) ~ ${_formatVND(wants)}**:\n'
            '   • Cafe, giao lưu, xem phim, mua sắm cá nhân.\n\n'
            '3. **Tích lũy & Đầu tư (20%) ~ ${_formatVND(savings)}**:\n'
            '   • Quỹ khẩn cấp (3-6 tháng sinh hoạt), gửi tiết kiệm, đầu tư sinh lời.\n\n'
            '💡 *Bạn có thể vào tab "Tài khoản" -> "Ngân sách" để thiết lập hạn mức cảnh báo tự động!*',
        transactions: [],
      );
    }

    // 4. Đánh giá sức khỏe tài chính
    if (norm.contains('suc khoe') ||
        norm.contains('diem') ||
        norm.contains('danh gia')) {
      final balance = (financeContext?['balance'] as num?)?.toInt() ?? 0;
      final score = balance > 20000000 ? 88 : (balance > 5000000 ? 75 : 62);
      final tier = score >= 80 ? 'Khỏe mạnh 🟢' : 'Ổn định 🟡';

      return SmartChatResult(
        intent: 'financial_health',
        replyText: '🏆 **Báo cáo Sức khỏe Tài chính Finora Score**:\n\n'
            '• **Điểm tổng quan**: **$score/100** ($tier)\n'
            '• **Tổng tài sản khả dụng**: ${_formatVND(balance)}\n'
            '• **Tỷ lệ dự phòng an toàn**: Đạt mức khuyến nghị\n\n'
            '💡 **3 Lời khuyên tối ưu ngay tuần này**:\n'
            '1. Duy trì ghi chép đều đặn các khoản chi tiêu nhỏ (dưới 50k).\n'
            '2. Trích 10-15% thu nhập vào ví Tiết kiệm ngay khi nhận lương.\n'
            '3. Kiểm tra các đăng ký định kỳ (Netflix, iCloud, 4G) nếu không sử dụng.',
        transactions: [],
      );
    }

    // 5. Số dư ví / Tổng tài sản
    if (norm.contains('so du') ||
        norm.contains('tong tien') ||
        norm.contains('vi')) {
      if (wallets.isEmpty) {
        return SmartChatResult(
          intent: 'wallet_summary',
          replyText:
              'Hiện tại bạn chưa liên kết ví nào. Hãy vào mục **Tài khoản** để thêm ví tiền mặt hoặc ngân hàng nhé!',
          transactions: [],
        );
      }

      int total = 0;
      final lines = <String>[];
      for (final w in wallets) {
        total += w.balance;
        lines.add('• **${w.name}**: ${_formatVND(w.balance)}');
      }

      return SmartChatResult(
        intent: 'wallet_summary',
        replyText: '💳 **Tổng hợp số dư các tài khoản / ví**:\n\n'
            '${lines.join('\n')}\n\n'
            '💰 **Tổng số dư khả dụng**: **${_formatVND(total)}**',
        transactions: [],
      );
    }

    // 6. Lời khuyên tiết kiệm chung
    return SmartChatResult(
      intent: 'general_advice',
      replyText: '💡 **Lời khuyên tài chính thông minh dành cho bạn**:\n\n'
          '1. **Nguyên tắc 24 Giờ**: Với các món đồ mua sắm trên 500.000 đ, hãy chờ 24 giờ trước khi thanh toán để tránh mua theo cảm xúc.\n'
          '2. **Tự động hóa tiết kiệm**: Hãy chuyển tiền vào quỹ tiết kiệm ngay ngày đầu nhận lương (Pay Yourself First).\n'
          '3. **Kiểm soát khoản rò rỉ**: Các chi phí nhỏ như cafe, trà sữa hàng ngày có thể chiếm 15-20% thu nhập mỗi tháng.\n\n'
          'Bạn cần tôi phân tích cụ thể danh mục nào không?',
      transactions: [],
    );
  }

  static String _formatVND(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }
}
