/// Represents a parsed financial transaction from a bank or e-commerce push notification.
class ParsedBankTransaction {
  final String rawId;
  final String packageName;
  final String bankCode;
  final String bankName;
  final double amount;
  final String type; // 'expense', 'income', or 'transfer'
  final String? accountNumber;
  final double? balanceAfter;
  final String note;
  final String transactionCode;
  final String rawNotificationText;
  final String suggestedCategoryId;
  final String suggestedCategoryName;
  final String suggestedCategoryIcon;
  final String? suggestedMerchant;
  final bool isCreditCardPayment;
  final bool isInternalTransferCandidate;
  final String? matchedTransferBankCode;
  final String? matchedTransferBankName;
  final String? matchedTransferRawId;
  final DateTime timestamp;

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer' || isInternalTransferCandidate;

  const ParsedBankTransaction({
    required this.rawId,
    required this.packageName,
    required this.bankCode,
    required this.bankName,
    required this.amount,
    required this.type,
    this.accountNumber,
    this.balanceAfter,
    required this.note,
    this.transactionCode = '',
    this.rawNotificationText = '',
    this.suggestedCategoryId = 'khac',
    required this.suggestedCategoryName,
    required this.suggestedCategoryIcon,
    this.suggestedMerchant,
    this.isCreditCardPayment = false,
    this.isInternalTransferCandidate = false,
    this.matchedTransferBankCode,
    this.matchedTransferBankName,
    this.matchedTransferRawId,
    required this.timestamp,
  });

  ParsedBankTransaction copyWith({
    String? rawId,
    String? packageName,
    String? bankCode,
    String? bankName,
    double? amount,
    String? type,
    String? accountNumber,
    double? balanceAfter,
    String? note,
    String? transactionCode,
    String? rawNotificationText,
    String? suggestedCategoryId,
    String? suggestedCategoryName,
    String? suggestedCategoryIcon,
    String? suggestedMerchant,
    bool? isCreditCardPayment,
    bool? isInternalTransferCandidate,
    String? matchedTransferBankCode,
    String? matchedTransferBankName,
    String? matchedTransferRawId,
    DateTime? timestamp,
  }) {
    return ParsedBankTransaction(
      rawId: rawId ?? this.rawId,
      packageName: packageName ?? this.packageName,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      accountNumber: accountNumber ?? this.accountNumber,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      note: note ?? this.note,
      transactionCode: transactionCode ?? this.transactionCode,
      rawNotificationText: rawNotificationText ?? this.rawNotificationText,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestedCategoryName:
          suggestedCategoryName ?? this.suggestedCategoryName,
      suggestedCategoryIcon:
          suggestedCategoryIcon ?? this.suggestedCategoryIcon,
      suggestedMerchant: suggestedMerchant ?? this.suggestedMerchant,
      isCreditCardPayment: isCreditCardPayment ?? this.isCreditCardPayment,
      isInternalTransferCandidate:
          isInternalTransferCandidate ?? this.isInternalTransferCandidate,
      matchedTransferBankCode:
          matchedTransferBankCode ?? this.matchedTransferBankCode,
      matchedTransferBankName:
          matchedTransferBankName ?? this.matchedTransferBankName,
      matchedTransferRawId: matchedTransferRawId ?? this.matchedTransferRawId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'rawId': rawId,
        'packageName': packageName,
        'bankCode': bankCode,
        'bankName': bankName,
        'amount': amount,
        'type': type,
        'accountNumber': accountNumber,
        'balanceAfter': balanceAfter,
        'note': note,
        'transactionCode': transactionCode,
        'rawNotificationText': rawNotificationText,
        'suggestedCategoryId': suggestedCategoryId,
        'suggestedCategoryName': suggestedCategoryName,
        'suggestedCategoryIcon': suggestedCategoryIcon,
        'suggestedMerchant': suggestedMerchant,
        'isCreditCardPayment': isCreditCardPayment,
        'isInternalTransferCandidate': isInternalTransferCandidate,
        'matchedTransferBankCode': matchedTransferBankCode,
        'matchedTransferBankName': matchedTransferBankName,
        'matchedTransferRawId': matchedTransferRawId,
        'timestamp': timestamp.toIso8601String(),
      };
}

class BankNotificationParser {
  /// Fold Vietnamese characters (including NFD combining diacritics) to ASCII lowercase
  /// while preserving digits, symbols, signs, and whitespace.
  static String foldVietnamese(String input) {
    if (input.isEmpty) return '';
    // Strip Unicode combining diacritical marks (NFD decomposed accents from Android/iOS notifications)
    var s = input.replaceAll(RegExp(r'[\u0300-\u036f\u1dc0-\u1dff\u20d0-\u20ff]'), '');
    s = s.toLowerCase();
    const map = <String, String>{
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'đ': 'd',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  /// Clean amount string like "50,000", "50.000", "1 250 000", "50000 VND" into double
  static double? parseAmount(String raw) {
    var clean = raw
        .replaceAll(
            RegExp(r'VND|VNĐ|vnd|vnđ|đồng|dong|₫|đ|Đ', caseSensitive: false),
            '')
        .replaceAll(RegExp(r'[dD]\s*$'), '')
        .trim();

    clean = clean
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('+', '');
    if (clean.isEmpty) return null;

    final isNegative = clean.startsWith('-');
    if (isNegative) {
      clean = clean.substring(1);
    }

    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf('.') < clean.lastIndexOf(',')) {
        final tail = clean.substring(clean.lastIndexOf(',') + 1);
        if (tail.length == 3) {
          clean = clean.replaceAll('.', '').replaceAll(',', '');
        } else {
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        }
      } else {
        final tail = clean.substring(clean.lastIndexOf('.') + 1);
        if (tail.length == 3) {
          clean = clean.replaceAll(',', '').replaceAll('.', '');
        } else {
          clean = clean.replaceAll(',', '');
        }
      }
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    final parsed = double.tryParse(clean);
    if (parsed == null) return null;
    return isNegative ? -parsed : parsed;
  }

  /// Extract post-transaction account balance (Số dư cuối / SD khả dụng / SD / NCB / all VN banks) from notification text.
  static double? extractBalanceAfter(String raw) {
    // Normalize dashes and fold Vietnamese accents (handles both NFC and NFD combining marks from NCB iziMobile, etc.)
    final normalized = foldVietnamese(raw)
        .replaceAll('−', '-')
        .replaceAll('–', '-');

    // Mask out balance-change title/intro phrases so they don't get mistaken for ending balance
    final masked = normalized
        .replaceAll(
          RegExp(
            r'bien\s+dong\s+so\s+du|thay\s+doi\s+so\s+du|thong\s+bao\s+so\s+du|so\s+du\s+bien\s+dong|so\s+du\s+thay\s+doi',
            caseSensitive: false,
          ),
          'bd_tk',
        )
        // Also mask "so du tk [subtype] <acct> thay doi/bien dong/tang/giam [+-]amount"
        .replaceAllMapped(
          RegExp(
            r'\b(?:so\s+du|sd)\s+(?:tk|tai\s+khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?\s+[0-9a-zxX*.-]{3,24}\s*(?:tai\s+[a-z0-9\s]{1,16}\s*)?(?:thay\s+doi|bien\s+dong|tang|giam|vua\s+thay\s+doi|phat\s+sinh|gd|ps)',
            caseSensitive: false,
          ),
          (m) => 'bd_tk_acct',
        );

    // 1. Explicit Ending-Balance Keywords (Highest Confidence — e.g. SD khả dụng, SDKD, Số dư cuối, Số dư sau GD, Số dư thực tế, Số dư hiện tại, Số dư hiện có, Số dư TK tiết kiệm hiện tại)
    // Supports optional "TK [tiết kiệm] <acct>" before or after keyword, and ":", "=", " - ", "la", or space separator, and optional "+" prefix on positive balance.
    final explicitMatches = RegExp(
      r'\b(?:(?:so\s*du|sd)\s+(?:(?:(?:tk|tai\s*khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?(?:\s+[0-9a-zxX*.-]{3,24})?\s+)?(?:kha\s+dung|cuoi(?:\s+ky)?|sau\s+gd|sau\s+giao\s+dich|thuc\s+te|hien\s+tai|hien\s+co|con\s+lai|moi))|sdkd|sdtt|sdc|available\s+balance|avail\s+bal|ending\s+balance|han\s*muc\s*(?:con\s*lai|kha\s*dung))(?:\s+(?:tk|tai\s*khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?(?:\s+[0-9a-zxX*.-]{3,24})?)?\s*(?:[:=]|\s+-\s+|\bla\b|\s)\s*([+-]?\s*\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)?',
      caseSensitive: false,
    ).allMatches(masked);

    double? bestExplicit;
    for (final m in explicitMatches) {
      final rawVal = (m.group(1) ?? '').trim();
      // Ending account balance is never a negative debit delta
      if (rawVal.startsWith('-')) continue;
      final val = parseAmount(rawVal);
      if (val != null && val.isFinite && val >= 0) {
        bestExplicit = val;
      }
    }
    if (bestExplicit != null) return bestExplicit;

    // 1b. Explicit savings account balance phrasing without leading "Số dư" ("Tài khoản tiết kiệm <acct> hiện có 50,000,000 VND")
    final savingsExplicitMatches = RegExp(
      r'\b(?:tk|tai\s*khoan|so)\s+(?:tiet\s+kiem|tich\s+luy)(?:\s+[0-9a-zxX*.-]{3,24})?\s+(?:hien\s+(?:co|tai)|con\s+lai|so\s*du(?:\s+la)?)\s*(?:[:=]|\s+-\s+|\bla\b|\s)\s*([+]?\s*\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)?',
      caseSensitive: false,
    ).allMatches(masked);
    for (final m in savingsExplicitMatches) {
      final rawVal = (m.group(1) ?? '').trim();
      final val = parseAmount(rawVal);
      if (val != null && val.isFinite && val >= 0) {
        bestExplicit = val;
      }
    }
    if (bestExplicit != null) return bestExplicit;

    // 2. "SD TK [tiết kiệm] <acct>: <balance>" / "So du tai khoan tiet kiem - 50,000,000 VND"
    // Note: in NCB & some banks, the FIRST "So du TK <acct>: -500,000" is the transaction delta,
    // while a non-negative or subsequent match is the ending balance.
    final acctBalanceMatches = RegExp(
      r'\b(?:sd|so\s*du)\s+(?:tk|tai\s*khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?(?:\s+[0-9a-zxX*.-]{3,24})?\s*(?:(?:[:=]|\s+-\s+|\bla\b|\bhien\s+(?:co|tai)\b)\s*([+-]?\s*\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)?|\s+([+-]?\s*\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)\b)',
      caseSensitive: false,
    ).allMatches(masked);
    double? acctCandidate;
    for (final m in acctBalanceMatches) {
      final rawVal = (m.group(1) ?? m.group(2) ?? '').trim();
      if (rawVal.isEmpty || rawVal.startsWith('-')) continue;
      // If it starts with '+', only accept as balance if there is already another signed transaction amount earlier
      if (rawVal.startsWith('+')) {
        final beforeText = masked.substring(0, m.start);
        if (!RegExp(r'[+-]\s*\d').hasMatch(beforeText)) continue;
      }
      final val = parseAmount(rawVal);
      if (val != null && val.isFinite && val >= 0) {
        acctCandidate = val;
      }
    }

    // 3. Generic "SD:" / "So du:" / "Balance:" patterns (take the LAST valid non-negative balance in the notification)
    final genericMatches = RegExp(
      r'\b(?:sd|so\s*du|balance)\s*(?:[:=]|\s+-\s+|\bla\b|\s)\s*([+-]?\s*\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)?',
      caseSensitive: false,
    ).allMatches(masked);

    double? genericCandidate;
    for (final m in genericMatches) {
      final fullMatch = m.group(0) ?? '';
      // Skip if this matched "SD TK <account_number>" where the captured number is the account number
      final afterMatch = masked.substring(m.start);
      if (RegExp(r'^(?:sd|so\s*du)\s+(?:tk|tai\s*khoan|so)\b', caseSensitive: false)
          .hasMatch(afterMatch) ||
          RegExp(r'^(?:sd|so\s*du)\s+tk\b', caseSensitive: false)
              .hasMatch(fullMatch)) {
        continue;
      }
      final rawVal = (m.group(1) ?? '').trim();
      if (rawVal.startsWith('-')) continue;
      if (rawVal.startsWith('+')) {
        // In NCB/SHB/Agribank, "SD: +12,500,000 VND" has a '+' sign on the ending balance!
        // Accept it if there was an earlier transaction amount in the text.
        final beforeText = masked.substring(0, m.start);
        final hasEarlierAmount = RegExp(
          r'(?:[+-]\s*\d|\b(?:gd|ps|thanh\s+toan|chuyen|nhan|rut|ghi\s+no|ghi\s+co|tru|cong)\b[^0-9]{0,25}\d)',
          caseSensitive: false,
        ).hasMatch(beforeText);
        if (!hasEarlierAmount) continue;
      }
      final val = parseAmount(rawVal);
      if (val != null && val.isFinite && val >= 0) {
        genericCandidate = val;
      }
    }

    return genericCandidate ?? acctCandidate;
  }

  /// Extract bank reference / transaction code (Mã giao dịch chính) from notification text.
  static String extractTransactionCode(String combined, String bankCode) {
    final normalized = combined.replaceAll('\n', ' ').trim();
    // 1. Explicit FT / MBVCB / IBFT / Trace / Ref / Mã GD patterns
    final explicitRef = RegExp(
      r'(?:Mã GD|Ma GD|MGD|Ref|FT|Trace|Số HĐ|So HD|Mã ĐH|Ma DH|Đơn hàng|Don hang)\s*[:#-]?\s*([A-Z0-9._-]{5,32})',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (explicitRef != null) {
      return explicitRef.group(1)!.trim();
    }

    // 2. Standard interbank reference tokens (FT26..., MBVCB..., VCB..., TCB..., etc.)
    final tokenMatch = RegExp(
      r'\b(FT\d{8,20}|MBVCB\.[A-Z0-9.]{6,28}|IBFT[A-Z0-9]{6,24}|NAPAS[A-Z0-9]{5,24}|SPX[A-Z0-9]{6,20}|\d{6,10}\.\d{6,10})\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (tokenMatch != null) {
      return tokenMatch.group(1)!.trim();
    }

    // 3. Fallback: use the primary bank notification content line (ND / Nội dung) or compact header
    final ndMatch = RegExp(
      r'(?:ND|Nội dung|Noi dung|GD)\s*:?\s*([^.\n]+)',
      caseSensitive: false,
    ).firstMatch(combined);
    if (ndMatch != null) {
      final rawNd = ndMatch.group(1)?.trim() ?? '';
      if (rawNd.isNotEmpty) {
        return rawNd.length > 64 ? rawNd.substring(0, 64).trim() : rawNd;
      }
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return compact.length > 64 ? compact.substring(0, 64).trim() : compact;
  }

  /// Detect whether a notification is a Credit Card Repayment transaction.
  static bool detectCreditCardPayment(String combined) {
    final lower = combined.toLowerCase();
    return lower.contains('dư nợ thẻ') ||
        lower.contains('du no the') ||
        lower.contains('sao kê thẻ') ||
        lower.contains('sao ke the') ||
        lower.contains('thanh toán thẻ tín dụng') ||
        lower.contains('thanh toan the tin dung') ||
        lower.contains('trả nợ thẻ') ||
        lower.contains('tra no the') ||
        lower.contains('thanh toan the') ||
        lower.contains('credit card payment') ||
        lower.contains('trả thẻ tín dụng') ||
        lower.contains('tra the tin dung');
  }

  /// Detect merchant from notification content or package
  static String? suggestMerchant(String combined, String pkg) {
    final lower = '$combined $pkg'.toLowerCase();
    if (lower.contains('shopee')) return 'Shopee';
    if (lower.contains('tiktok')) return 'TikTok Shop';
    if (lower.contains('lazada')) return 'Lazada';
    if (lower.contains('tiki')) return 'Tiki';
    if (lower.contains('grab')) return 'Grab';
    if (lower.contains('xanh sm') || lower.contains('green sm')) {
      return 'Xanh SM';
    }
    if (lower.contains('be ') || lower.contains('be,')) return 'Be';
    if (lower.contains('highlands')) return 'Highlands Coffee';
    if (lower.contains('starbucks')) return 'Starbucks';
    if (lower.contains('phuc long') ||
        lower.contains('phúc lộc') ||
        lower.contains('phúc long')) {
      return 'Phúc Long';
    }
    if (lower.contains('winmart')) return 'WinMart';
    if (lower.contains('bachhoaxanh') || lower.contains('bách hóa xanh')) {
      return 'Bách Hóa Xanh';
    }
    if (lower.contains('circle k')) return 'Circle K';
    return null;
  }

  /// Categorize note into standard FINORA categories
  static ({String id, String name, String icon}) suggestCategory(String note) {
    final lower = note.toLowerCase();

    if (detectCreditCardPayment(lower)) {
      return (
        id: 'tra_the_tin_dung',
        name: 'Trả thẻ tín dụng',
        icon: 'credit-card'
      );
    }

    // 1. Coffee & Tea
    if (lower.contains('cà phê') ||
        lower.contains('ca phe') ||
        lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('highlands') ||
        lower.contains('starbucks') ||
        lower.contains('phuc long') ||
        lower.contains('trà sữa') ||
        lower.contains('tra sua') ||
        lower.contains('mixue')) {
      return (id: 'ca_phe', name: 'Cà phê & Trà', icon: 'coffee');
    }

    // 2. Food & Dining
    if (lower.contains('phở') ||
        lower.contains('pho ') ||
        lower.contains('cơm') ||
        lower.contains('com ') ||
        lower.contains('cali') ||
        lower.contains('kfc') ||
        lower.contains('lotteria') ||
        lower.contains('mcdonald') ||
        lower.contains('pizza') ||
        lower.contains('bánh mì') ||
        lower.contains('banh mi') ||
        lower.contains('quán') ||
        lower.contains('quan ') ||
        lower.contains('nhà hàng') ||
        lower.contains('nha hang') ||
        lower.contains('shopeefood') ||
        lower.contains('grabfood') ||
        lower.contains('baemin') ||
        lower.contains('ăn uống') ||
        lower.contains('an uong')) {
      return (id: 'an_uong', name: 'Ăn uống', icon: 'utensils');
    }

    // 3. Transport & Vehicles
    if (lower.contains('grab') ||
        lower.contains('be ') ||
        lower.contains('be,') ||
        lower.contains('green sm') ||
        lower.contains('xanh sm') ||
        lower.contains('taxi') ||
        lower.contains('xăng') ||
        lower.contains('xang') ||
        lower.contains('petrolimex') ||
        lower.contains('pv oil') ||
        lower.contains('gửi xe') ||
        lower.contains('gui xe') ||
        lower.contains('bãi xe') ||
        lower.contains('vé xe') ||
        lower.contains('ve xe') ||
        lower.contains('vé tàu') ||
        lower.contains('vietnam airlines') ||
        lower.contains('vietjet')) {
      return (id: 'di_chuyen', name: 'Di chuyển', icon: 'car');
    }

    // 4. Shopping (including Shopee, TikTok Shop, Lazada)
    if (lower.contains('shopee') ||
        lower.contains('lazada') ||
        lower.contains('tiktok') ||
        lower.contains('tiki') ||
        lower.contains('winmart') ||
        lower.contains('coopmart') ||
        lower.contains('bachhoaxanh') ||
        lower.contains('circle k') ||
        lower.contains('7 eleven') ||
        lower.contains('ministop') ||
        lower.contains('familymart') ||
        lower.contains('siêu thị') ||
        lower.contains('sieu thi') ||
        lower.contains('chợ') ||
        lower.contains('cho ') ||
        lower.contains('quần áo') ||
        lower.contains('quan ao') ||
        lower.contains('zara') ||
        lower.contains('uniqlo') ||
        lower.contains('mua sắm') ||
        lower.contains('mua sam') ||
        lower.contains('đơn hàng') ||
        lower.contains('don hang')) {
      return (id: 'mua_sam', name: 'Mua sắm', icon: 'shopping-bag');
    }

    // 5. Bills & Utilities
    if (lower.contains('tiền điện') ||
        lower.contains('tien dien') ||
        lower.contains('evn') ||
        lower.contains('tiền nước') ||
        lower.contains('tien nuoc') ||
        lower.contains('viettel') ||
        lower.contains('vinaphone') ||
        lower.contains('mobifone') ||
        lower.contains('fpt') ||
        lower.contains('internet') ||
        lower.contains('nạp tiền điện thoại') ||
        lower.contains('nap tien dien thoai') ||
        lower.contains('cước') ||
        lower.contains('cuoc')) {
      return (id: 'hoa_don', name: 'Hóa đơn', icon: 'receipt');
    }

    // 6. Entertainment
    if (lower.contains('cgv') ||
        lower.contains('bhd') ||
        lower.contains('lotte cinema') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('youtube') ||
        lower.contains('game') ||
        lower.contains('steam') ||
        lower.contains('du lịch') ||
        lower.contains('du lich') ||
        lower.contains('khách sạn') ||
        lower.contains('khach san')) {
      return (id: 'giai_tri', name: 'Giải trí', icon: 'gamepad-2');
    }

    // 7. Medical & Health
    if (lower.contains('nhà thuốc') ||
        lower.contains('nha thuoc') ||
        lower.contains('pharmacity') ||
        lower.contains('long châu') ||
        lower.contains('long chau') ||
        lower.contains('bệnh viện') ||
        lower.contains('benh vien') ||
        lower.contains('phòng khám') ||
        lower.contains('phong kham') ||
        lower.contains('thuốc') ||
        lower.contains('thuoc') ||
        lower.contains('khám bệnh')) {
      return (id: 'y_te', name: 'Y tế', icon: 'heart-pulse');
    }

    // 8. Salary & Income
    if (lower.contains('lương') ||
        lower.contains('luong') ||
        lower.contains('thưởng') ||
        lower.contains('thuong') ||
        lower.contains('salary') ||
        lower.contains('bonus') ||
        lower.contains('thu hồi nợ') ||
        lower.contains('chuyển khoản đến') ||
        lower.contains('nhận tiền') ||
        lower.contains('nhan tien')) {
      return (id: 'luong', name: 'Lương & Thưởng', icon: 'wallet');
    }

    return (id: 'khac', name: 'Khác', icon: 'more-horizontal');
  }

  /// Resolve bank or shopping app code and brand name from package name, title, or message text
  static ({String code, String name}) resolveBank(String pkg, String title,
      [String text = '']) {
    final p = pkg.trim().toLowerCase();
    final t = foldVietnamese(title.trim());
    // Sanitize text so interbank routing codes (MBVCB, VCB.IBFT) or counter-party phrases
    // ("tới NH MB", "đến VCB") don't override the actual sender bank.
    final sanitizedText = foldVietnamese(text)
        .replaceAll(
            RegExp(r'\bmbvcb\.[a-z0-9.]*\b', caseSensitive: false), 'ibft_ref')
        .replaceAll(
            RegExp(
                r'(?:toi|den|sang|nhan tu|chuyen den|thu huong)\s+(?:nh|ngan hang|tk|tai khoan)?\s*[a-z0-9\s]{1,20}',
                caseSensitive: false),
            ' ');

    const banks = <({
      String code,
      String name,
      List<String> pkgs,
      List<String> keywords
    })>[
      (
        code: 'vcb',
        name: 'Vietcombank',
        pkgs: ['com.vcb', 'vietcombank'],
        keywords: ['vietcombank', 'vcb digibank', r'\bvcb\b']
      ),
      (
        code: 'techcombank',
        name: 'Techcombank',
        pkgs: ['techcombank'],
        keywords: ['techcombank', 'techcombank mobile', r'\btcb\b']
      ),
      (
        code: 'mbbank',
        name: 'MB Bank',
        pkgs: ['mb.mbbank', 'mbmobile', 'com.mb.'],
        keywords: ['mbbank', 'mb bank', 'ngan hang quan doi', r'\bmb\b']
      ),
      (
        code: 'acb',
        name: 'ACB',
        pkgs: ['mobile.acb', 'com.acb'],
        keywords: ['acb one', 'ngan hang a chau', r'\bacb\b']
      ),
      (
        code: 'vpbank',
        name: 'VPBank',
        pkgs: ['vpbankonline', 'vpbank.online', 'vpbank.neo', 'com.vpbank'],
        keywords: ['vpbank neo', 'vpbank', r'\bvpb\b']
      ),
      (
        code: 'bidv',
        name: 'BIDV',
        pkgs: ['bidv'],
        keywords: ['bidv smartbanking', r'\bbidv\b']
      ),
      (
        code: 'vietinbank',
        name: 'VietinBank',
        pkgs: ['vietinbank', 'ipay'],
        keywords: ['vietinbank ipay', 'vietinbank', 'vietin', r'\bctg\b', r'\bvtb\b']
      ),
      (
        code: 'tpbank',
        name: 'TPBank',
        pkgs: ['tpb.mb', 'tpbank'],
        keywords: ['tpbank', 'tien phong', r'\btpb\b']
      ),
      (
        code: 'sacombank',
        name: 'Sacombank',
        pkgs: ['sacombank'],
        keywords: ['sacombank pay', 'sacombank', r'\bstb\b']
      ),
      (
        code: 'agribank',
        name: 'Agribank',
        pkgs: ['agribank'],
        keywords: ['agribank plus', 'agribank', r'\bagri\b', r'\bvba\b']
      ),
      (
        code: 'vib',
        name: 'VIB',
        pkgs: ['com.vib', 'myvib'],
        keywords: ['myvib', 'ngan hang quoc te', r'\bvib\b']
      ),
      (
        code: 'hdbank',
        name: 'HDBank',
        pkgs: ['hdbank'],
        keywords: ['hdbank', r'\bhdb\b']
      ),
      (
        code: 'shb',
        name: 'SHB',
        pkgs: ['vn.shb', 'shb.mbanking', 'shbmobile'],
        keywords: ['shb mobile', 'shb saigon', r'\bshb\b']
      ),
      (
        code: 'ocb',
        name: 'OCB',
        pkgs: ['com.ocb.omni', 'ocb.omni'],
        keywords: ['ocb omni', 'phuong dong', r'\bocb\b']
      ),
      (
        code: 'msb',
        name: 'MSB',
        pkgs: ['msb'],
        keywords: ['msb m-bank', 'hang hai', r'\bmsb\b']
      ),
      (
        code: 'seabank',
        name: 'SeABank',
        pkgs: ['seabank'],
        keywords: ['seabank', 'seamobile', r'\bsea\b']
      ),
      (
        code: 'eximbank',
        name: 'Eximbank',
        pkgs: ['eximbank', 'edigi'],
        keywords: ['eximbank edigi', 'eximbank', r'\beib\b']
      ),
      (
        code: 'lpbank',
        name: 'LPBank',
        pkgs: ['lienviet', 'lpbank', 'vn.com.lpb'],
        keywords: ['lpbank', 'lienvietpostbank', 'lien viet', r'\blpb\b']
      ),
      (
        code: 'bvbank',
        name: 'BVBank',
        pkgs: ['vietcapitalbank', 'bvbank', 'digimi', 'banvietbank'],
        keywords: ['bvbank', 'digimi', 'ban viet', 'vietcapital']
      ),
      (
        code: 'vikki',
        name: 'Vikki Digital Bank',
        pkgs: ['vikki', 'dongabank'],
        keywords: ['vikki', 'dong a bank', r'\bdab\b']
      ),
      (
        code: 'kbank',
        name: 'KBank',
        pkgs: ['kasikornbank', 'kplus'],
        keywords: ['k plus', 'kplus', 'kasikorn', 'kbank']
      ),
      (
        code: 'abbank',
        name: 'ABBank',
        pkgs: ['abbank', 'abditizen'],
        keywords: ['abbank', 'an binh', 'ab ditizen', r'\babb\b']
      ),
      (
        code: 'namabank',
        name: 'Nam A Bank',
        pkgs: ['namabank', 'openbanking.nama'],
        keywords: ['nam a bank', 'nam a', 'namabank', r'\bnab\b']
      ),
      (
        code: 'bacabank',
        name: 'Bac A Bank',
        pkgs: ['baca', 'bacabank', 'com.bab.'],
        keywords: ['bac a bank', 'bac a', 'bacabank', r'\bbab\b']
      ),
      (
        code: 'vietbank',
        name: 'VietBank',
        pkgs: ['vietbank'],
        keywords: ['vietbank', 'viet thuong tin', r'\bvbb\b']
      ),
      (
        code: 'pvcombank',
        name: 'PVcomBank',
        pkgs: ['pvcombank'],
        keywords: ['pvcombank', 'dai chung', r'\bpvc\b']
      ),
      (
        code: 'ncb',
        name: 'NCB (Quốc Dân)',
        pkgs: ['com.ncb.bank', 'ncb', 'izimobile'],
        keywords: ['ncb izimobile', 'izimobile', 'ngan hang quoc dan', 'quoc dan', r'\bncb\b']
      ),
      (
        code: 'kienlongbank',
        name: 'KienlongBank',
        pkgs: ['kienlongbank', 'klb', 'sunshine.ksbank', 'kienlong'],
        keywords: ['kienlongbank', 'kien long', r'\bklb\b']
      ),
      (
        code: 'saigonbank',
        name: 'Saigonbank',
        pkgs: ['saigonbank'],
        keywords: ['saigonbank', 'sai gon cong thuong', r'\bsgb\b']
      ),
      (
        code: 'pgbank',
        name: 'PGBank',
        pkgs: ['pgbank'],
        keywords: ['pgbank', 'pg bank', 'thinh vuong va phat trien', r'\bpgb\b']
      ),
      (
        code: 'vietabank',
        name: 'VietABank',
        pkgs: ['vietabank', 'ezmobile'],
        keywords: ['vietabank', 'viet a bank', r'\bvab\b']
      ),
      (
        code: 'baovietbank',
        name: 'BaoViet Bank',
        pkgs: ['baovietbank', 'baoviet'],
        keywords: ['baoviet bank', 'bao viet', 'baovietbank']
      ),
      (
        code: 'oceanbank',
        name: 'MBV (OceanBank)',
        pkgs: ['oceanbank', 'com.mbv.mobilebanking'],
        keywords: ['oceanbank', 'ngan hang dai duong', 'modern bank of vietnam', r'\bmbv\b']
      ),
      (
        code: 'gpbank',
        name: 'GPBank',
        pkgs: ['gpbank'],
        keywords: ['gpbank', 'dau khi toan cau', r'\bgpb\b']
      ),
      (
        code: 'cbbank',
        name: 'CBBank',
        pkgs: ['cbbank'],
        keywords: ['cbbank', 'ngan hang xay dung', r'\bcbb\b']
      ),
      (
        code: 'scb',
        name: 'SCB',
        pkgs: ['vnpay.scb', 'scb.mbanking'],
        keywords: ['ngan hang sai gon', 'scb mobile', r'\bscb\b']
      ),
      (
        code: 'coopbank',
        name: 'Co-opBank',
        pkgs: ['coopbank'],
        keywords: ['co-opbank', 'coopbank', 'ngan hang hop tac xa']
      ),
      (
        code: 'vbsp',
        name: 'VBSP (Chính sách XH)',
        pkgs: ['vbsp'],
        keywords: ['vbsp', 'chinh sach xa hoi', 'nhcsxh']
      ),
      (
        code: 'vrb',
        name: 'VRB (Việt - Nga)',
        pkgs: ['vnpay.vrb', 'com.vrb'],
        keywords: ['viet - nga', 'viet nga', r'\bvrb\b']
      ),
      (
        code: 'ivb',
        name: 'Indovina Bank (IVB)',
        pkgs: ['vnpay.ivb', 'ivb.mobilebanking'],
        keywords: ['indovina', r'\bivb\b']
      ),
      (
        code: 'shinhan',
        name: 'Shinhan Bank',
        pkgs: ['shinhan', 'solvn'],
        keywords: ['shinhan', 'shinhan sol']
      ),
      (
        code: 'woori',
        name: 'Woori Bank',
        pkgs: ['woori', 'wonvn'],
        keywords: ['woori bank', 'woori won', 'woori']
      ),
      (
        code: 'hsbc',
        name: 'HSBC',
        pkgs: ['hsbc'],
        keywords: [r'\bhsbc\b']
      ),
      (
        code: 'uob',
        name: 'UOB',
        pkgs: ['uob', 'tmrw'],
        keywords: ['uob tmrw', r'\buob\b', r'\btmrw\b']
      ),
      (
        code: 'cimb',
        name: 'CIMB',
        pkgs: ['cimb', 'octo'],
        keywords: ['cimb octo', r'\bcimb\b']
      ),
      (
        code: 'publicbank',
        name: 'Public Bank',
        pkgs: ['publicbank', 'pbengage'],
        keywords: ['public bank', 'publicbank']
      ),
      (
        code: 'hongleong',
        name: 'Hong Leong Bank',
        pkgs: ['hongleong', 'hlb.connectvn'],
        keywords: ['hong leong', 'hongleong', r'\bhlb\b']
      ),
      (
        code: 'standardchartered',
        name: 'Standard Chartered',
        pkgs: ['standardchartered', 'scmobile', 'sc.mobilebanking'],
        keywords: ['standard chartered', 'sc mobile']
      ),
      (
        code: 'cake',
        name: 'Cake by VPBank',
        pkgs: ['xyz.be.cake', 'com.cake.bank'],
        keywords: ['cake by vpbank', r'\bcake\b']
      ),
      (
        code: 'timo',
        name: 'Timo Digital Bank',
        pkgs: ['timo.vn', 'vn.timo'],
        keywords: ['timo digital', r'\btimo\b']
      ),
      (
        code: 'liobank',
        name: 'Liobank',
        pkgs: ['liobank'],
        keywords: ['liobank', r'\blio\b']
      ),
      (
        code: 'ubank',
        name: 'Ubank by VPBank',
        pkgs: ['vpbank.ubank', 'ubank'],
        keywords: ['ubank by vpbank', r'\bubank\b']
      ),
      (
        code: 'tnex',
        name: 'TNEX',
        pkgs: ['tnex'],
        keywords: [r'\btnex\b']
      ),
      (
        code: 'momo',
        name: 'Ví MoMo',
        pkgs: ['mservice', 'momotransfer', 'momopay'],
        keywords: ['vi momo', r'\bmomo\b']
      ),
      (
        code: 'zalopay',
        name: 'ZaloPay',
        pkgs: ['zalopay'],
        keywords: ['zalopay', 'zalo pay']
      ),
      (
        code: 'viettelmoney',
        name: 'Viettel Money',
        pkgs: ['vtpay', 'bankplus', 'viettelpay', 'viettelmoney'],
        keywords: ['viettel money', 'viettelpay', 'viettel pay']
      ),
      (
        code: 'vnptmoney',
        name: 'VNPT Money',
        pkgs: ['vnptpay', 'vnptmoney', 'vinaphone.vnptpay'],
        keywords: ['vnpt money', 'vnpt pay', 'vnptpay']
      ),
      (
        code: 'vnpay',
        name: 'VNPAY',
        pkgs: ['vn.vnpay', 'vnpay.wallet'],
        keywords: ['vi vnpay', 'vnpay wallet', r'\bvnpay\b']
      ),
      (
        code: 'shopeepay',
        name: 'ShopeePay',
        pkgs: ['airpay', 'shopeepay'],
        keywords: ['shopeepay', 'shopee pay', 'airpay']
      ),
      (
        code: 'payoo',
        name: 'Ví Payoo',
        pkgs: ['vn.payoo', 'payoo'],
        keywords: ['vi payoo', r'\bpayoo\b']
      ),
      (
        code: 'vtcpay',
        name: 'VTC Pay',
        pkgs: ['vtc.paygate', 'vtcpay'],
        keywords: ['vtc pay', 'vtcpay']
      ),
      (
        code: 'foxpay',
        name: 'Foxpay (FPT)',
        pkgs: ['ftel.foxpay', 'foxpay'],
        keywords: [r'\bfoxpay\b']
      ),
      (
        code: 'mobifonemoney',
        name: 'MobiFone Money',
        pkgs: ['mobifone.mmdt', 'mobifonemoney'],
        keywords: ['mobifone money', 'mobifone pay']
      ),
      (
        code: 'smartpay',
        name: 'SmartPay',
        pkgs: ['smartpay'],
        keywords: [r'\bsmartpay\b']
      ),
      (
        code: '9pay',
        name: 'Ví 9Pay',
        pkgs: ['ninepay', '9pay'],
        keywords: ['vi 9pay', r'\b9pay\b', 'ninepay']
      ),
      (
        code: 'appotapay',
        name: 'AppotaPay',
        pkgs: ['wallet.appota', 'appotapay'],
        keywords: ['appotapay', 'appota pay']
      ),
      (
        code: 'vinid',
        name: 'VinID / OneU',
        pkgs: ['com.oneid', 'vinid'],
        keywords: ['vinid pay', r'\bvinid\b', r'\boneu\b']
      ),
      (
        code: 'homecredit',
        name: 'Home Credit',
        pkgs: ['homecredit'],
        keywords: ['home credit', 'homecredit']
      ),
      (
        code: 'fecredit',
        name: 'FE Credit',
        pkgs: ['fecredit'],
        keywords: ['fe credit', 'fecredit']
      ),
      (
        code: 'hdsaison',
        name: 'HD Saison',
        pkgs: ['hdsaison'],
        keywords: ['hd saison', 'hdsaison']
      ),
      (
        code: 'miraeasset',
        name: 'Mirae Asset Finance',
        pkgs: ['mafc.mobileapp', 'miraeasset'],
        keywords: ['mirae asset', 'mafc']
      ),
    ];

    bool matchesKeyword(String haystack, String kw) {
      if (kw.startsWith(r'\b') || kw.endsWith(r'\b')) {
        return RegExp(kw, caseSensitive: false).hasMatch(haystack);
      }
      return haystack.contains(kw);
    }

    // 1. Package name match (highest confidence)
    if (p.isNotEmpty && p != 'manual.bank') {
      for (final b in banks) {
        if (b.pkgs.any((pk) => p.contains(pk))) {
          return (code: b.code, name: b.name);
        }
      }
    }

    // 2. Notification title / SMS sender match (second highest confidence)
    if (t.isNotEmpty) {
      for (final b in banks) {
        if (b.keywords.any((kw) => matchesKeyword(t, kw))) {
          return (code: b.code, name: b.name);
        }
      }
    }

    // 3. Sanitized message body match
    if (sanitizedText.isNotEmpty) {
      for (final b in banks) {
        if (b.keywords.any((kw) => matchesKeyword(sanitizedText, kw))) {
          return (code: b.code, name: b.name);
        }
      }
    }

    final combined = '$t $sanitizedText';
    if (p.contains('shopee.vn') ||
        (combined.contains('shopee') && !combined.contains('shopeepay'))) {
      return (code: 'shopee', name: 'Shopee');
    }
    if (p.contains('musically') ||
        p.contains('trill') ||
        combined.contains('tiktok')) {
      return (code: 'tiktok', name: 'TikTok Shop');
    }
    if (p.contains('lazada') || combined.contains('lazada')) {
      return (code: 'lazada', name: 'Lazada');
    }
    return (code: 'bank', name: title.isNotEmpty ? title : 'Ngân hàng');
  }

  /// Primary parsing entrypoint
  static ParsedBankTransaction? parse({
    required String rawId,
    required String packageName,
    required String title,
    required String text,
    int? timestampMs,
  }) {
    if (text.isEmpty && title.isEmpty) return null;

    final combined = '$title\n$text';
    final foldedCombined = foldVietnamese(combined)
        .replaceAll('₫', 'd')
        .replaceAll('−', '-')
        .replaceAll('–', '-');

    // Drop security / OTP notices
    if (foldedCombined.contains('otp') ||
        foldedCombined.contains('ma xac thuc') ||
        foldedCombined.contains('password') ||
        foldedCombined.contains('mat khau') ||
        foldedCombined.contains('canh bao bao mat') ||
        foldedCombined.contains('verification code') ||
        foldedCombined.contains('security code')) {
      return null;
    }

    final bank = resolveBank(packageName, title, text);
    final dt = timestampMs != null
        ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
        : DateTime.now();

    // Require a transaction direction; never treat an offer or a balance as spending.
    if (RegExp(
            r'khong thanh cong|that bai|failed|uu dai|khuyen mai|voucher|ma giam gia',
            caseSensitive: false)
        .hasMatch(foldedCombined)) return null;
    final normalized = combined.replaceAll('−', '-').replaceAll('–', '-');
    // Pure static balance statements ("Số dư tài khoản tiết kiệm 50.000.000 VND",
    // "Số dư tài khoản tiết kiệm - 50,000,000 VND", "Số dư: -50.000 VND")
    // have no transaction delta and must NEVER be parsed as an expense.
    if (isStaticBalanceOnlyMessage(foldedCombined)) return null;

    // Extract post-transaction balance first
    final balanceAfter = extractBalanceAfter(normalized);

    // Strip fee segments (Phí: 1,100đ) and explicit ending balance clauses ("SD khả dụng: 12,450,000VND")
    // from a copy used for transaction amount extraction so fees or ending balances are never picked as tx amount.
    final amountTarget = stripBalanceAndFeeClauses(foldedCombined);

    final signedAfter = RegExp(
            r'(?<![\d/.-])([+-])\s*(\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)(?![a-z])',
            caseSensitive: false)
        .firstMatch(amountTarget);
    final signedBefore = RegExp(
            r'(?:vnd|d\b)\s*([+-])\s*(\d(?:[\d.,\s]*\d)?)',
            caseSensitive: false)
        .firstMatch(amountTarget);
    final signedContext = RegExp(
            r'(?:gd|ps|bien dong|thay doi|sd|so du|tk|tai khoan|the)[^+\-\d]{0,35}([+-])\s*(\d[\d.,\s]{2,})',
            caseSensitive: false)
        .firstMatch(amountTarget);
    String? type;
    double? extractedAmount;
    if (signedAfter != null) {
      type = signedAfter.group(1) == '+' ? 'income' : 'expense';
      extractedAmount = parseAmount(signedAfter.group(2)!);
    } else if (signedBefore != null) {
      type = signedBefore.group(1) == '+' ? 'income' : 'expense';
      extractedAmount = parseAmount(signedBefore.group(2)!);
    } else if (signedContext != null) {
      type = signedContext.group(1) == '+' ? 'income' : 'expense';
      extractedAmount = parseAmount(signedContext.group(2)!);
    } else {
      // Bank debit/credit, credit card swipe, or Shopee/TikTok order wording before the transaction amount.
      final directed = RegExp(
        r'(ghi co|bao co|nhan duoc|nhan tien|tien vao|cong|tang|credited|hoan tien|ghi no|bao no|thanh toan|chi tieu|giao dich the|gd the|da dung|spent|charged|da chuyen|chuyen khoan|chuyen tien|rut tien|tru|giam|debited|dat don|don hang|mua hang|tong tien|so tien)[^0-9]{0,35}?(\d(?:[\d.,\s]*\d)?)\s*(?:vnd|d\b|dong)(?![a-z])',
        caseSensitive: false,
      ).firstMatch(amountTarget);
      if (directed != null) {
        type = RegExp(
                    r'ghi co|bao co|nhan|tien vao|cong|tang|credited|hoan tien',
                    caseSensitive: false)
                .hasMatch(directed.group(1)!)
            ? 'income'
            : 'expense';
        extractedAmount = parseAmount(directed.group(2)!);
      }
    }
    if (type == null ||
        extractedAmount == null ||
        !extractedAmount.isFinite ||
        extractedAmount <= 0) return null;
    extractedAmount = extractedAmount.abs();

    // Extract account number: TK 102xxx, Tài khoản tiết kiệm 108542..., or Thẻ 4123*9988
    final accountNo = extractAccountNumber(combined);

    // Extract note: Content / Noi dung / ND / tai
    String note = '';
    final ndMatch = RegExp(
            r'(?:ND|Nội dung|Noi dung|tai|tại|Ref|Giao dịch|GD|Lý do|Ly do|Mô tả|Mo ta)\s*:?\s*([^.\n]+)',
            caseSensitive: false)
        .firstMatch(combined);
    if (ndMatch != null) {
      note = ndMatch.group(1)?.trim() ?? '';
    } else {
      note = text.trim();
    }

    if (note.length > 80) {
      note = note.substring(0, 80).trim();
    }
    if (note.isEmpty) {
      note = '${type == 'expense' ? 'Chi tiêu' : 'Thu tiền'} ${bank.name}';
    }

    final txCode = extractTransactionCode(combined, bank.code);
    final isCreditCardRepay = detectCreditCardPayment(combined);
    final isSelfTransferHint = RegExp(
      r'chuyển khoản nội bộ|chuyen khoan noi bo|chuyển tiền qua|chuyen tien qua|nạp ví|nap vi',
      caseSensitive: false,
    ).hasMatch(combined);
    final merchant = suggestMerchant(combined, packageName);

    // Category
    final cat = suggestCategory('$note $combined');

    return ParsedBankTransaction(
      rawId: rawId,
      packageName: packageName,
      bankCode: bank.code,
      bankName: bank.name,
      amount: extractedAmount,
      type: type,
      accountNumber: accountNo,
      balanceAfter: balanceAfter,
      note: note,
      transactionCode: txCode,
      rawNotificationText: combined.trim(),
      suggestedCategoryId: cat.id,
      suggestedCategoryName: cat.name,
      suggestedCategoryIcon: cat.icon,
      suggestedMerchant: merchant,
      isCreditCardPayment: isCreditCardRepay,
      isInternalTransferCandidate: isSelfTransferHint,
      timestamp: dt,
    );
  }

  /// Strip fee segments and ending-balance clauses before scanning for a transaction delta.
  static String stripBalanceAndFeeClauses(String foldedCombined) {
    return foldedCombined
        .replaceAll(
          RegExp(
            r'(?:phi(?:\s+gd)?|fee|vat)\s*[:=-]?\s*[+-]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)?',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(?:(?:so\s*du|sd)\s+(?:(?:(?:tk|tai\s*khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?(?:\s+[0-9a-zxX*.-]{3,24})?\s+)?(?:kha\s+dung|cuoi(?:\s+ky)?|sau\s+gd|sau\s+giao\s+dich|thuc\s+te|hien\s+tai|hien\s+co|con\s+lai|moi))|sdkd|sdtt|sdc|available\s+balance|avail\s+bal|ending\s+balance|han\s*muc\s*(?:con\s*lai|kha\s*dung))(?:\s+(?:tk|tai\s*khoan|so)(?:\s+(?:tiet\s+kiem|tich\s+luy|thanh\s+toan|tin\s+dung))?(?:\s+[0-9a-zxX*.-]{3,24})?)?\s*(?:[:=]|\s+-\s+|\bla\b|\s)\s*[+]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)?',
            caseSensitive: false,
          ),
          ' ',
        )
        // Strip savings-account balance clauses ("Số dư TK tiết kiệm [123456]: 50,000,000 VND", "Số dư tài khoản tiết kiệm - 50,000,000 VND")
        .replaceAll(
          RegExp(
            r'\b(?:sd|so\s*du)\s+(?:tk|tai\s*khoan|so)\s+(?:tiet\s+kiem|tich\s+luy)(?:\s+[0-9a-zxX*.-]{3,24})?\s*(?:(?:[:=]|\s+-\s+|\bla\b|\bhien\s+(?:co|tai)\b)\s*[+]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)?|\s+[+]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)\b)',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(?:tk|tai\s*khoan|so)\s+(?:tiet\s+kiem|tich\s+luy)(?:\s+[0-9a-zxX*.-]{3,24})?\s+(?:hien\s+(?:co|tai)|con\s+lai|so\s*du(?:\s+la)?)\s*(?:[:=]|\s+-\s+|\bla\b|\s)\s*[+]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)?',
            caseSensitive: false,
          ),
          ' ',
        )
        // Strip explicit ending balance snippets ("SD: 12,450,000", "Số dư: +2,734,539 VND") so delta amount stays unambiguous.
        .replaceAll(
          RegExp(
            r'\b(?:sd|so\s*du|so\s*du\s*hien\s*tai|so\s*du\s*kha\s*dung|balance)\s*(?:[:=]|\s+-\s+)\s*[+]?\s*\d[\d.,\s]*(?:vnd|d\b|dong)?',
            caseSensitive: false,
          ),
          ' ',
        );
  }

  /// True when the notification only states an account/savings balance without a transaction movement.
  static bool isStaticBalanceOnlyMessage(String foldedCombined) {
    final hasBalanceKeyword = RegExp(
      r'\b(?:so\s*du|sd\s*[:=]|sd\s+(?:tk|tai\s*khoan|so|kha\s+dung|hien\s+tai|hien\s+co|cuoi|con\s+lai|thuc\s+te)|sdkd|sdtt|sdc|balance|(?:tk|tai\s*khoan|so)\s+(?:tiet\s+kiem|tich\s+luy)\b[^.\n]{0,40}\b(?:hien\s+(?:co|tai)|con\s+lai|so\s*du))',
      caseSensitive: false,
    ).hasMatch(foldedCombined);
    if (!hasBalanceKeyword) return false;

    final hasTransactionVerb = RegExp(
      r'\bgd\b|\bps\b|phat\s+sinh|bien\s+dong|thay\s+doi|ghi\s+no|ghi\s+co|bao\s+no|bao\s+co|thanh\s+toan|chi\s+tieu|giao\s+dich|da\s+chuyen|chuyen\s+khoan|chuyen\s+tien|rut\s+tien|nhan\s+tien|nhan\s+duoc|tien\s+vao|hoan\s+tien|debited|credited|spent|charged|dat\s+don|don\s+hang|mua\s+hang|\bref\b|\bnd\b|noi\s+dung',
      caseSensitive: false,
    ).hasMatch(foldedCombined);
    if (hasTransactionVerb) return false;

    // If stripping an ending-balance clause still leaves an explicit signed delta
    // (e.g., "SD TK 1000234567 -150,000 VND. SD: 12,450,000 VND"), it IS a real transaction.
    final stripped = stripBalanceAndFeeClauses(foldedCombined);
    final strippedEndingBalance = stripped != foldedCombined;
    final hasSignedDeltaRemaining = RegExp(
      r'(?<![\d/.-])[+-]\d(?:[\d.,\s]*\d)?\s*(?:vnd|d\b|dong)(?![a-z])',
      caseSensitive: false,
    ).hasMatch(stripped);
    if (strippedEndingBalance && hasSignedDeltaRemaining) return false;

    return true;
  }

  /// Extract bank/savings account number without mistaking formatted money amounts for account numbers.
  static String? extractAccountNumber(String combined) {
    final matches = RegExp(
      r'(?:TK|tai khoan|Tài khoản|STK|sổ tiết kiệm|so tiet kiem|the|Thẻ|Card)\s*(?:thanh toán|thanh toan|tt|tín dụng|tin dung|td|tiết kiệm|tiet kiem|tích lũy|tich luy)?\s*[:#-]?\s*([0-9xX*.]{3,24})(?![0-9xX*.,])(?!\s*(?:vnd|đ|₫|d\b|dong\b))',
      caseSensitive: false,
    ).allMatches(combined);
    for (final m in matches) {
      final candidate = (m.group(1) ?? '').replaceAll(RegExp(r'^[.]+|[.]+$'), '');
      if (candidate.isEmpty) continue;
      // Reject thousands-grouped amounts like 50.000.000 or 8.500.000
      if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(candidate)) continue;
      final digits = candidate.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 3) return candidate;
    }
    return null;
  }

  /// Strictly detect husband/wife word tokens (never matches "vốn", "với", "vô", "vòng", "chống", etc.).
  static String? detectMemberHint(String raw) {
    if (raw.trim().isEmpty) return null;
    final tokens = raw
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toSet();
    final hasHusband = tokens.contains('husband') ||
        tokens.contains('chồng') ||
        tokens.contains('chong');
    final hasWife = tokens.contains('wife') ||
        tokens.contains('vợ') ||
        tokens.contains('vo');
    if (hasHusband && !hasWife) return 'husband';
    if (hasWife && !hasHusband) return 'wife';
    return null;
  }

  /// True when the notification or wallet name refers to a savings account / savings book.
  static bool isSavingsContext(String raw) {
    final folded = foldVietnamese(raw);
    return RegExp(
      r'\b(?:tiet\s+kiem|so\s+tiet\s+kiem|tich\s+luy|saving|savings|heo\s+dat)\b',
      caseSensitive: false,
    ).hasMatch(folded);
  }

  /// Build a fallback [ParsedBankTransaction] from an unrecognized bank notification
  /// so the user can still tap it, pick a category, adjust amount if needed, and save.
  static ParsedBankTransaction fromUnrecognized({
    required String rawId,
    required String title,
    required String text,
    String packageName = '',
    int? timestampMs,
  }) {
    final parsed = parse(
      rawId: rawId,
      packageName: packageName.isNotEmpty ? packageName : rawId,
      title: title,
      text: text,
      timestampMs: timestampMs,
    );
    if (parsed != null) return parsed;

    final combined = '$title\n$text';
    final foldedCombined = foldVietnamese(combined)
        .replaceAll('₫', 'd')
        .replaceAll('−', '-')
        .replaceAll('–', '-');
    final bank = resolveBank(
      packageName.isNotEmpty ? packageName : rawId,
      title,
      text,
    );
    final balanceAfter = extractBalanceAfter(combined.replaceAll('−', '-').replaceAll('–', '-'));
    final accountNo = extractAccountNumber(combined);
    final isStaticBalance = isStaticBalanceOnlyMessage(foldedCombined);
    final isIncome = RegExp(
      r'\+|ghi có|ghi co|báo có|bao co|nhận|nhan|tiền vào|tien vao|cộng|cong|tăng|tang|credited',
      caseSensitive: false,
    ).hasMatch(combined);

    double fallbackAmount = 0;
    // Never turn a pure savings/account balance statement into a spending transaction amount.
    if (!isStaticBalance) {
      var scanTarget = stripBalanceAndFeeClauses(foldedCombined)
          .replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b'), ' ');
      if (accountNo != null && accountNo.isNotEmpty) {
        scanTarget = scanTarget.replaceAll(accountNo.toLowerCase(), ' ');
      }
      final numMatches =
          RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,12})').allMatches(scanTarget);
      for (final m in numMatches) {
        final candidate = parseAmount(m.group(0) ?? '');
        if (candidate != null && candidate >= 1000 && candidate <= 100000000000) {
          fallbackAmount = candidate.abs();
          break;
        }
      }
    }

    final note = text.trim().isNotEmpty
        ? (text.trim().length > 80
            ? text.trim().substring(0, 80).trim()
            : text.trim())
        : (title.trim().isNotEmpty ? title.trim() : 'Giao dịch ${bank.name}');
    final cat = suggestCategory('$note $combined');
    final txCode = extractTransactionCode(combined, bank.code);
    final merchant = suggestMerchant(combined, packageName);
    final isCreditCardRepay = detectCreditCardPayment(combined);

    return ParsedBankTransaction(
      rawId: rawId,
      packageName: packageName.isNotEmpty ? packageName : rawId,
      bankCode: bank.code,
      bankName: bank.name,
      amount: fallbackAmount,
      type: isIncome ? 'income' : 'expense',
      accountNumber: accountNo,
      balanceAfter: balanceAfter,
      note: note,
      transactionCode: txCode,
      rawNotificationText: combined.trim(),
      suggestedCategoryId: cat.id,
      suggestedCategoryName: cat.name,
      suggestedCategoryIcon: cat.icon,
      suggestedMerchant: merchant,
      isCreditCardPayment: isCreditCardRepay,
      timestamp: timestampMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
    );
  }
}
