import '../widgets/finora_notice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/vietqr_data.dart';
import 'vietqr_parser.dart';

class BankLauncherHelper {
  BankLauncherHelper._();
  static const _channel = MethodChannel('com.finora/bank_apps');
  static bool supportsAutofill(BankInfo bank) => bank.bin == '970422';

  /// Casso public API: MB autofill=1, TCB autofill=0. Launch is not payment proof.
  static Uri buildPaymentLink(
      {required BankInfo bank,
      required VietQrData data,
      required double amount,
      required String memo}) {
    final recipient = VietQrParser.findBank(data.bankBin ?? data.bankShortName);
    if (!supportsAutofill(bank) ||
        recipient == null ||
        !RegExp(r'^[A-Za-z0-9]{4,34}$').hasMatch(data.accountNumber) ||
        !amount.isFinite ||
        amount <= 0 ||
        amount != amount.truncateToDouble() ||
        amount > 999999999999) {
      throw const FormatException(
          'Thông tin chưa hợp lệ hoặc ngân hàng chưa hỗ trợ tự điền.');
    }
    return Uri.https('dl.vietqr.io', '/pay', {
      'app': 'mb',
      'am': amount.toInt().toString(),
      'tn': memo,
      'ba': '${data.accountNumber}@${recipient.shortName.toLowerCase()}',
      'url': kIsWeb
          ? Uri.base
              .replace(path: '/', query: 'qrReturn=1', fragment: '')
              .toString()
          : 'finora://qr-return',
    });
  }

  static Future<void> copyTransferDetails(VietQrData data,
      {double? customAmount, String? customMemo}) async {
    final amount = customAmount ?? data.amount;
    await Clipboard.setData(ClipboardData(
        text: [
      'STK: ${data.accountNumber}',
      'Ngân hàng: ${data.bankName}',
      if (amount != null && amount > 0) 'Số tiền: ${amount.toStringAsFixed(0)}',
      if ((customMemo ?? data.memo ?? '').isNotEmpty)
        'Nội dung: ${customMemo ?? data.memo}',
    ].join('\n')));
  }

  static Future<void> copyAccountNumber(String number) =>
      Clipboard.setData(ClipboardData(text: number));

  /// Resolves a [BankInfo] from wallet fields (`bankCode`, `bankName`, or `wallet.name`)
  /// such as "Chi tiêu của Chồng Techcombank", "Ví VCB Vợ", "TCB", "MB Bank", etc.
  static BankInfo? resolveWalletBank({
    String? bankCode,
    String? bankName,
    String? walletName,
  }) {
    for (final candidate in [bankCode, bankName, walletName]) {
      final direct = VietQrParser.findBank(candidate);
      if (direct != null) return direct;
    }
    final combined =
        '${bankCode ?? ''} ${bankName ?? ''} ${walletName ?? ''}'.toUpperCase();
    if (combined.trim().isEmpty) return null;

    const aliasToBin = <String, String>{
      'TECHCOMBANK': '970407',
      'TECHCOM': '970407',
      'TCB': '970407',
      'VIETCOMBANK': '970436',
      'VCB': '970436',
      'MB BANK': '970422',
      'MBBANK': '970422',
      'QUAN DOI': '970422',
      'QUÂN ĐỘI': '970422',
      'VIETINBANK': '970415',
      'CTG': '970415',
      'BIDV': '970418',
      'ACB': '970416',
      'VPBANK': '970432',
      'VPB': '970432',
      'TPBANK': '970423',
      'TPB': '970423',
      'SACOMBANK': '970403',
      'STB': '970403',
      'AGRIBANK': '970405',
      'VIB': '970441',
      'HDBANK': '970437',
      'MSB': '970426',
      'OCB': '970448',
      'SHB': '970443',
      'SEABANK': '970440',
      'TIMO': '963388',
      'CAKE': '546034',
    };
    for (final entry in aliasToBin.entries) {
      if (RegExp('(^|[^A-Z0-9])${RegExp.escape(entry.key)}([^A-Z0-9]|\$)')
          .hasMatch(combined)) {
        return VietQrParser.supportedBanks[entry.value];
      }
    }
    if (RegExp(r'(^|[^A-Z0-9])MB([^A-Z0-9]|$)').hasMatch(combined)) {
      return VietQrParser.supportedBanks['970422'];
    }
    for (final w in VietQrParser.popularWallets) {
      if (combined.contains(w.shortName.toUpperCase()) ||
          combined.contains(w.name.toUpperCase())) {
        return w;
      }
    }
    return null;
  }

  /// Launches the selected wallet's bank app directly (e.g. Techcombank, MB, VCB)
  /// with transfer details copied and deep-link / package intent triggered.
  static Future<bool> launchBankAppDirect({
    required BuildContext context,
    required BankInfo bank,
    required VietQrData data,
    required double amount,
    required String memo,
  }) async {
    await copyTransferDetails(
      data,
      customAmount: amount,
      customMemo: memo,
    );

    bool opened = false;
    final recipient = VietQrParser.findBank(data.bankBin ?? data.bankShortName);
    final appSlug = switch (bank.bin) {
      '970407' => 'tcb',
      '970422' => 'mb',
      '970436' => 'vcb',
      '970416' => 'acb',
      '970418' => 'bidv',
      '970415' => 'icb',
      '970432' => 'vpb',
      '970423' => 'tpb',
      '970403' => 'stb',
      '970441' => 'vib',
      '970426' => 'msb',
      '970437' => 'hdb',
      '970448' => 'ocb',
      '970405' => 'vba',
      _ => bank.shortName.toLowerCase(),
    };

    // 1. Try VietQR universal deep link FIRST (opens bank transfer screen with pre-filled account, amount & memo)
    if (recipient != null && amount > 0) {
      try {
        final deepLink = Uri.https('dl.vietqr.io', '/pay', {
          'app': appSlug,
          'am': amount.toInt().toString(),
          'tn': memo,
          'ba': '${data.accountNumber}@${recipient.shortName.toLowerCase()}',
          'url': kIsWeb
              ? Uri.base
                  .replace(path: '/', query: 'qrReturn=1', fragment: '')
                  .toString()
              : 'finora://qr-return',
        });
        opened =
            await launchUrl(deepLink, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    // 2. Fallback to native Android package open if deep link handler was unavailable
    if (!opened &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        bank.androidPackage != null) {
      try {
        opened = await _channel.invokeMethod<bool>(
              'openBank',
              {'package': bank.androidPackage},
            ) ??
            false;
      } catch (_) {}
    }

    // 3. Fallback iOS scheme
    if (!opened &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        bank.iosScheme != null) {
      try {
        opened = await launchUrl(
          Uri.parse(bank.iosScheme!),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    if (context.mounted) {
      _notice(
        context,
        opened
            ? 'Đã ghi giao dịch & mở ${bank.name} (${amount.toInt()} ₫ · STK ${data.accountNumber}).'
            : 'Đã ghi giao dịch & sao chép STK ${data.accountNumber} (${amount.toInt()} ₫) để dán vào ${bank.name}.',
      );
    }
    return opened;
  }
  static Future<bool> launchBankApp(
      {required BuildContext context,
      required BankInfo bank,
      required VietQrData data,
      double? customAmount,
      String? customMemo}) async {
    if (supportsAutofill(bank)) {
      final Uri link;
      try {
        link = buildPaymentLink(
            bank: bank,
            data: data,
            amount: customAmount ?? data.amount ?? 0,
            memo: customMemo ?? data.memo ?? '');
      } on FormatException catch (e) {
        if (context.mounted) _notice(context, e.message.toString());
        return false;
      }
      if (!context.mounted) return false;
      final consent = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Mở MB và điền thông tin'),
                  content: Text(
                      'Số tài khoản ${data.accountNumber}, ngân hàng nhận, số tiền ${(customAmount ?? data.amount ?? 0).toInt()} ₫ và nội dung sẽ được gửi qua VietQR.io của Casso để mở MB.\n\nBạn kiểm tra và xác nhận trong MB. Finora không tự chuyển tiền.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Đồng ý mở MB'))
                  ]));
      if (consent != true) return false;
      try {
        final opened =
            await launchUrl(link, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted)
          _notice(context, 'Chưa mở được MB. Bạn có thể sao chép thông tin.');
        return opened;
      } catch (_) {
        if (context.mounted)
          _notice(context, 'Chưa mở được MB. Bản nháp vẫn còn trên máy.');
        return false;
      }
    }
    return launchBankAppDirect(
      context: context,
      bank: bank,
      data: data,
      amount: customAmount ?? data.amount ?? 0,
      memo: customMemo ?? data.memo ?? '',
    );
  }

  static void _notice(BuildContext context, String text) =>
      FinoraNotice.of(context).showSnackBar(SnackBar(content: Text(text)));
}
