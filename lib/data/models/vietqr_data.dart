/// Finora VietQR Data Model
///
/// Encapsulates parsed VietQR (EMVCo) and payment payload details.
class VietQrData {
  /// 6-digit NAPAS Bank BIN (e.g. "970436" for Vietcombank)
  final String? bankBin;

  /// Full Bank Name (e.g. "Vietcombank")
  final String bankName;

  /// Short Bank Code (e.g. "VCB")
  final String bankShortName;

  /// Bank Icon Asset Path (e.g. "assets/banks/vcb.png")
  final String? bankLogo;

  /// Beneficiary Account Number (Số tài khoản nhận)
  final String accountNumber;

  /// Beneficiary Account Name if available (Tên chủ tài khoản)
  final String? accountName;

  /// Transaction Amount (Số tiền chuyển nếu là QR động)
  final double? amount;

  /// Transfer Purpose / Memo (Nội dung chuyển khoản)
  final String? memo;

  /// Raw QR payload string
  final String rawPayload;

  /// Android package name of the beneficiary bank (for App-to-App)
  final String? androidPackage;

  /// iOS Custom URL Scheme (for App-to-App)
  final String? iosScheme;

  const VietQrData({
    this.bankBin,
    required this.bankName,
    required this.bankShortName,
    this.bankLogo,
    required this.accountNumber,
    this.accountName,
    this.amount,
    this.memo,
    required this.rawPayload,
    this.androidPackage,
    this.iosScheme,
  });

  /// Check whether amount is already fixed in the QR
  bool get hasFixedAmount => amount != null && amount! > 0;

  /// Formats formatted text for clipboard copying
  String toClipboardSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Ngân hàng: $bankName ($bankShortName)');
    buffer.writeln('Số tài khoản: $accountNumber');
    if (accountName != null && accountName!.isNotEmpty) {
      buffer.writeln('Chủ tài khoản: $accountName');
    }
    if (amount != null && amount! > 0) {
      buffer.writeln('Số tiền: ${amount!.toStringAsFixed(0)} đ');
    }
    if (memo != null && memo!.isNotEmpty) {
      buffer.writeln('Nội dung: $memo');
    }
    return buffer.toString().trim();
  }

  /// Generates VietQR standard image URL
  String toVietQrImageUrl() {
    final bin = bankBin ?? '970436';
    final amt = amount?.toInt() ?? 0;
    final note = Uri.encodeComponent(memo ?? '');
    return 'https://api.vietqr.io/$bin/$accountNumber/$amt/$note/vietqr_net_2.jpg';
  }

  VietQrData copyWith({
    String? bankBin,
    String? bankName,
    String? bankShortName,
    String? bankLogo,
    String? accountNumber,
    String? accountName,
    double? amount,
    String? memo,
    String? rawPayload,
    String? androidPackage,
    String? iosScheme,
  }) {
    return VietQrData(
      bankBin: bankBin ?? this.bankBin,
      bankName: bankName ?? this.bankName,
      bankShortName: bankShortName ?? this.bankShortName,
      bankLogo: bankLogo ?? this.bankLogo,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      rawPayload: rawPayload ?? this.rawPayload,
      androidPackage: androidPackage ?? this.androidPackage,
      iosScheme: iosScheme ?? this.iosScheme,
    );
  }
}
