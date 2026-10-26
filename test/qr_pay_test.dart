import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:finora/core/utils/bank_launcher_helper.dart';
import 'package:finora/data/models/vietqr_data.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/qr_pay/bank_app_selector_sheet.dart';
import 'package:finora/features/qr_pay/qr_confirm_expense_sheet.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleQrData = VietQrData(
    bankBin: '970436',
    bankName: 'Vietcombank',
    bankShortName: 'VCB',
    bankLogo: 'assets/banks/vcb.png',
    accountNumber: '1012345678',
    amount: 150000.0,
    memo: 'Cafe sang',
    rawPayload: 'sample_raw_payload',
    androidPackage: 'com.VCB',
    iosScheme: 'vcb://',
  );

  final sampleWallet = Wallet(
    id: 'w_vcb',
    name: 'Ví VCB',
    bankCode: 'VCB',
    bankName: 'Vietcombank',
    accountNumber: '1012345678',
    balance: 5000000,
  );

  group('QR Pay Unit & Logic Tests', () {
    test('VietQrData clipboard summary formats correctly', () {
      final summary = sampleQrData.toClipboardSummary();
      expect(summary, contains('Vietcombank (VCB)'));
      expect(summary, contains('1012345678'));
      expect(summary, contains('150000 đ'));
      expect(summary, contains('Cafe sang'));
    });

    test('BankLauncherHelper copies transfer details to clipboard', () async {
      await BankLauncherHelper.copyTransferDetails(sampleQrData);
      // Ensure no exceptions thrown
    });
  });

  group('QR Pay Widget & UI Tests', () {
    testWidgets('BankAppSelectorSheet renders recommended bank and other banks',
        (tester) async {
      bool canceled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankAppSelectorSheet(
              qrData: sampleQrData,
              amount: 150000.0,
              memo: 'Cafe sang',
              preferredBankBin: '970436',
              onCancelTransaction: () => canceled = true,
            ),
          ),
        ),
      );

      // Verify header and summary
      expect(find.text('Đã ghi sổ vào Finora!'), findsOneWidget);
      expect(find.text('Mở Vietcombank'), findsOneWidget);
      expect(find.text('Chép STK'), findsOneWidget);

      // Verify undo button
      final undoBtn = find.text('Huỷ ghi sổ (Nếu bạn không thanh toán)');
      expect(undoBtn, findsOneWidget);
      await tester.tap(undoBtn);
      await tester.pump();
      expect(canceled, isTrue);
    });

    testWidgets('QrConfirmExpenseSheet renders inputs and pre-selected details',
        (tester) async {
      final txProvider = TransactionProvider();
      final walletProvider = WalletProvider();
      walletProvider.wallets = [sampleWallet];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: QrConfirmExpenseSheet(
                qrData: sampleQrData,
                userId: 'user_test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bank info
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('STK: 1012345678'), findsOneWidget);

      // Verify pre-filled amount
      expect(find.text('150.000'), findsOneWidget);

      // Verify Action buttons
      expect(find.text('Ghi sổ & Mở App Ngân hàng'), findsOneWidget);
      expect(find.text('Chỉ ghi sổ vào Finora (Đã thanh toán rồi)'), findsOneWidget);
    });

    testWidgets('Defensive Layout Audit: QrConfirmExpenseSheet at 320px & textScaler 1.5',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final txProvider = TransactionProvider();
      final walletProvider = WalletProvider();
      walletProvider.wallets = [sampleWallet];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            size: Size(320, 800),
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
              ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: QrConfirmExpenseSheet(
                  qrData: sampleQrData,
                  userId: 'user_test',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
