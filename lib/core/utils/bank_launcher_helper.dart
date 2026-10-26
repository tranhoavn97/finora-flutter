import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/vietqr_data.dart';
import 'vietqr_parser.dart';

/// Helper for dispatching App-to-App payment to Vietnamese Banking apps
class BankLauncherHelper {
  BankLauncherHelper._();

  /// Automatically copy transfer details to user's system clipboard
  static Future<void> copyTransferDetails(
    VietQrData data, {
    double? customAmount,
    String? customMemo,
  }) async {
    final amt = customAmount ?? data.amount;
    final memo = customMemo ?? data.memo;

    final formatted = StringBuffer()
      ..writeln('STK: ${data.accountNumber}')
      ..writeln('Ngân hàng: ${data.bankName}');
    if (amt != null && amt > 0) {
      formatted.writeln('Số tiền: ${amt.toStringAsFixed(0)}');
    }
    if (memo != null && memo.isNotEmpty) {
      formatted.writeln('Nội dung: $memo');
    }

    await Clipboard.setData(ClipboardData(text: formatted.toString().trim()));
  }

  /// Copies only the account number for 1-tap paste in bank app
  static Future<void> copyAccountNumber(String accountNumber) async {
    await Clipboard.setData(ClipboardData(text: accountNumber));
  }

  /// Launch banking app or fallback to browser/deep link
  static Future<bool> launchBankApp({
    required BuildContext context,
    required BankInfo bank,
    required VietQrData data,
    double? customAmount,
    String? customMemo,
  }) async {
    // 1. Copy account and memo to clipboard first so user can paste immediately
    await copyTransferDetails(
      data,
      customAmount: customAmount,
      customMemo: customMemo,
    );

    // 2. Try launching on Android via explicit package Intent
    final pkg = bank.androidPackage;
    if (pkg != null && pkg.isNotEmpty) {
      try {
        final intentUri = Uri.parse(
          'intent:#Intent;package=$pkg;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;end',
        );
        final launched = await launchUrl(
          intentUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) {
          if (context.mounted) {
            _showLaunchedToast(context, bank.name);
          }
          return true;
        }
      } catch (_) {}

      // Fallback 2b: android-app URI
      try {
        final androidAppUri = Uri.parse('android-app://$pkg');
        final launched = await launchUrl(
          androidAppUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) {
          if (context.mounted) {
            _showLaunchedToast(context, bank.name);
          }
          return true;
        }
      } catch (_) {}
    }

    // 3. Try launching custom URL scheme (e.g. vcb://, mbmobile://)
    final scheme = bank.iosScheme;
    if (scheme != null && scheme.isNotEmpty) {
      final uri = Uri.parse(scheme);
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          if (context.mounted) {
            _showLaunchedToast(context, bank.name);
          }
          return true;
        }
      } catch (_) {}
    }

    // 4. Try launching via universal VietQR quick URL
    try {
      final quickUrl = Uri.parse(data.toVietQrImageUrl());
      final launchedWeb = await launchUrl(
        quickUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launchedWeb) {
        if (context.mounted) {
          _showLaunchedToast(context, bank.name);
        }
        return true;
      }
    } catch (_) {}

    // 5. If app is not installed or launch failed, show friendly helper with Play Store option
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: pkg != null
              ? SnackBarAction(
                  label: 'Cài App',
                  textColor: const Color(0xFF38BDF8),
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse('market://details?id=$pkg'),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      await launchUrl(
                        Uri.parse('https://play.google.com/store/apps/details?id=$pkg'),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                )
              : null,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã sao chép STK ${data.accountNumber}. Mở ${bank.shortName} để dán và hoàn tất.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    return false;
  }

  static void _showLaunchedToast(BuildContext context, String bankName) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã sao chép thông tin chuyển khoản. Đang chuyển sang $bankName...',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
