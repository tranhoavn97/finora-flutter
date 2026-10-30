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
  /// Clean amount string like "50,000", "50.000", "50000 VND" into double
  static double? parseAmount(String raw) {
    var clean = raw
        .replaceAll('VND', '')
        .replaceAll('vnd', '')
        .replaceAll('₫', '')
        .replaceAll('đ', '')
        .replaceAll('Đ', '')
        .trim();

    clean = clean.replaceAll(RegExp(r'\s'), '').replaceAll('−', '-');
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf('.') < clean.lastIndexOf(',')) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        clean = clean.replaceAll(',', '');
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

    return double.tryParse(clean);
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
    if (lower.contains('phuc long') || lower.contains('phúc lộc') || lower.contains('phúc long')) {
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

  /// Resolve bank or shopping app code and brand name from package name or title
  static ({String code, String name}) resolveBank(String pkg, String title) {
    final p = pkg.toLowerCase();
    final t = title.toLowerCase();

    if (p.contains('shopee.vn') ||
        (t.contains('shopee') && !t.contains('shopeepay'))) {
      return (code: 'shopee', name: 'Shopee');
    }
    if (p.contains('musically') ||
        p.contains('trill') ||
        t.contains('tiktok')) {
      return (code: 'tiktok', name: 'TikTok Shop');
    }
    if (p.contains('lazada') || t.contains('lazada')) {
      return (code: 'lazada', name: 'Lazada');
    }

    if (p.contains('vietcombank') ||
        p.contains('vcb') ||
        t.contains('vietcombank') ||
        t.contains('vcb')) {
      return (code: 'vcb', name: 'Vietcombank');
    }
    if (p.contains('techcombank') ||
        t.contains('techcombank') ||
        t.contains('tcb')) {
      return (code: 'techcombank', name: 'Techcombank');
    }
    if (p.contains('mb.mbbank') ||
        p.contains('mbmobile') ||
        t.contains('mb bank') ||
        t.contains('mbbank') ||
        t.contains('mb ')) {
      return (code: 'mbbank', name: 'MB Bank');
    }
    if (p.contains('acb') || t.contains('acb')) {
      return (code: 'acb', name: 'ACB');
    }
    if (p.contains('vpbank') || t.contains('vpbank')) {
      return (code: 'vpbank', name: 'VPBank');
    }
    if (p.contains('bidv') || t.contains('bidv')) {
      return (code: 'bidv', name: 'BIDV');
    }
    if (p.contains('vietinbank') || t.contains('vietinbank')) {
      return (code: 'vietinbank', name: 'VietinBank');
    }
    if (p.contains('tpb') || t.contains('tpbank')) {
      return (code: 'tpbank', name: 'TPBank');
    }
    if (p.contains('cake') || t.contains('cake')) {
      return (code: 'cake', name: 'Cake by VPBank');
    }
    if (p.contains('timo') || t.contains('timo')) {
      return (code: 'timo', name: 'Timo Digital Bank');
    }
    if (p.contains('mservice') || t.contains('momo')) {
      return (code: 'momo', name: 'Ví MoMo');
    }
    if (p.contains('zalopay') || t.contains('zalopay')) {
      return (code: 'zalopay', name: 'ZaloPay');
    }
    if (p.contains('vtpay') ||
        p.contains('bankplus') ||
        t.contains('viettel')) {
      return (code: 'viettelmoney', name: 'Viettel Money');
    }
    if (p.contains('sacombank') || t.contains('sacombank')) {
      return (code: 'sacombank', name: 'Sacombank');
    }
    if (p.contains('agribank') || t.contains('agribank')) {
      return (code: 'agribank', name: 'Agribank');
    }
    if (p.contains('vib') || t.contains('vib')) {
      return (code: 'vib', name: 'VIB');
    }
    if (p.contains('ocb') || t.contains('ocb')) {
      return (code: 'ocb', name: 'OCB');
    }
    if (p.contains('msb') || t.contains('msb')) {
      return (code: 'msb', name: 'MSB');
    }

    for (final entry in const {
      'hdbank': 'HDBank',
      'shb': 'SHB',
      'eximbank': 'Eximbank',
      'seabank': 'SeABank',
      'liobank': 'Liobank',
      'namabank': 'Nam A Bank',
      'bacabank': 'Bac A Bank',
      'vietbank': 'VietBank',
      'pvcombank': 'PVcomBank',
      'ncb': 'NCB',
      'abbank': 'ABBank',
      'kienlongbank': 'KienlongBank',
      'bvbank': 'BVBank',
      'saigonbank': 'Saigonbank',
      'pgbank': 'PGBank',
      'shinhan': 'Shinhan Bank',
      'woori': 'Woori Bank',
      'hsbc': 'HSBC',
      'uob': 'UOB',
      'cimb': 'CIMB',
      'publicbank': 'Public Bank',
      'vietabank': 'VietABank',
      'vnpay': 'VNPay',
      'airpay': 'ShopeePay',
    }.entries) {
      if (p.contains(entry.key) || t.contains(entry.key)) {
        return (code: entry.key, name: entry.value);
      }
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
    final lower = combined.toLowerCase();

    // Drop security / OTP notices
    if (lower.contains('otp') ||
        lower.contains('mã xác thực') ||
        lower.contains('ma xac thuc') ||
        lower.contains('password') ||
        lower.contains('mật khẩu') ||
        lower.contains('cảnh báo bảo mật') ||
        lower.contains('mat khau') ||
        lower.contains('verification code') ||
        lower.contains('security code')) {
      return null;
    }

    final bank = resolveBank(packageName, title);
    final dt = timestampMs != null
        ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
        : DateTime.now();

    // Require a transaction direction; never treat an offer or a balance as spending.
    if (RegExp(
            r'không thành công|khong thanh cong|thất bại|that bai|failed|ưu đãi|uu dai|khuyến mãi|khuyen mai|voucher|mã giảm giá',
            caseSensitive: false)
        .hasMatch(combined)) return null;
    final normalized = combined.replaceAll('−', '-').replaceAll('–', '-');
    final signedAfter = RegExp(
            r'(?<![\d/.-])([+-])\s*(\d[\d.,]*)\s*(?:VND|VNĐ|đ|₫|dong|đồng|d\b)(?![a-z])',
            caseSensitive: false)
        .firstMatch(normalized);
    final signedBefore = RegExp(
            r'(?:VND|VNĐ|đ|₫)\s*([+-])\s*(\d[\d.,]+)',
            caseSensitive: false)
        .firstMatch(normalized);
    final signedContext = RegExp(
            r'(?:GD|PS|Biến động|Bien dong|SD|Số dư|So du|TK|Tài khoản|Tai khoan)[^+\-\d]{0,25}([+-])\s*(\d[\d.,]{3,})',
            caseSensitive: false)
        .firstMatch(normalized);
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
      // Bank debit/credit or Shopee/TikTok order wording before the transaction amount.
      final directed = RegExp(
        r'(ghi có|ghi co|báo có|bao co|nhận được|nhan duoc|nhận tiền|nhan tien|tiền vào|tien vao|cộng|cong|tăng|tang|credited|hoàn tiền|hoan tien|ghi nợ|ghi no|báo nợ|bao no|thanh toán|thanh toan|đã chuyển|da chuyen|chuyển khoản|chuyen khoan|chuyển tiền|chuyen tien|rút tiền|rut tien|trừ|tru|giảm|giam|debited|đặt đơn|dat don|đơn hàng|don hang|mua hàng|mua hang|tổng tiền|tong tien)[^0-9]{0,35}?(\d[\d.,]+)\s*(?:VND|VNĐ|đ|₫|dong|đồng|d\b)?',
        caseSensitive: false,
      ).firstMatch(normalized);
      if (directed != null) {
        type = RegExp(
                    r'ghi có|ghi co|báo có|bao co|nhận|nhan|tiền vào|tien vao|cộng|cong|tăng|tang|credited|hoàn tiền|hoan tien',
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

    // Extract account number: TK 102xxx or TK ...xxx
    String? accountNo;
    final acctMatch = RegExp(
            r'(?:TK|tai khoan|Tài khoản|STK|the|Thẻ)\s*:?\s*([0-9xX*]{3,24})',
            caseSensitive: false)
        .firstMatch(combined);
    if (acctMatch != null) {
      accountNo = acctMatch.group(1);
    }

    // Extract note: Content / Noi dung / ND / tai
    String note = '';
    final ndMatch = RegExp(
            r'(?:ND|Nội dung|Noi dung|tai|tại|Ref|Giao dịch|GD)\s*:?\s*([^.\n]+)')
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
    final bank = resolveBank(
      packageName.isNotEmpty ? packageName : rawId,
      title,
    );
    final isIncome = RegExp(
      r'\+|ghi có|ghi co|báo có|bao co|nhận|nhan|tiền vào|tien vao|cộng|cong|tăng|tang|credited',
      caseSensitive: false,
    ).hasMatch(combined);

    double fallbackAmount = 0;
    final numMatches = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,12})')
        .allMatches(combined);
    for (final m in numMatches) {
      final candidate = parseAmount(m.group(0) ?? '');
      if (candidate != null && candidate >= 1000 && candidate <= 100000000000) {
        fallbackAmount = candidate;
        break;
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
