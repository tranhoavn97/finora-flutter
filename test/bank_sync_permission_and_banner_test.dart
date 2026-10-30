import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/widgets/finora_bank_sync_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bank Sync Permission & Banner Tests', () {
    test('BankNotificationParser accurately categorizes common Vietnamese bank transfers', () {
      final parsedVcb = BankNotificationParser.parse(
        rawId: 'vcb_1',
        packageName: 'com.VCB',
        title: 'Vietcombank',
        text: 'So du TK 0123456789 thay doi -45,000 VND luc 12:30. Ref: Highland Coffee',
      );

      expect(parsedVcb, isNotNull);
      expect(parsedVcb!.bankCode, equals('vcb'));
      expect(parsedVcb.amount, equals(45000));
      expect(parsedVcb.isExpense, isTrue);
      expect(parsedVcb.suggestedCategoryId, equals('ca_phe'));

      final parsedTcbIncome = BankNotificationParser.parse(
        rawId: 'tcb_1',
        packageName: 'vn.com.techcombank.bb.app',
        title: 'Techcombank',
        text: 'TK 1902837493 +15.000.000 VND luc 08:30. Ref: Cty TNHH FINORA tra Luong thang 10',
      );

      expect(parsedTcbIncome, isNotNull);
      expect(parsedTcbIncome!.bankCode, equals('techcombank'));
      expect(parsedTcbIncome.amount, equals(15000000));
      expect(parsedTcbIncome.isIncome, isTrue);
      expect(parsedTcbIncome.suggestedCategoryId, equals('luong'));
    });

    test('BankNotificationParser drops OTP security messages completely', () {
      final otpNotice = BankNotificationParser.parse(
        rawId: 'vcb_otp',
        packageName: 'com.VCB',
        title: 'Vietcombank Smart OTP',
        text: 'Ma OTP cua ban la 654321 de xac thuc giao dich 2,000,000 VND. Tuyet doi khong chia se.',
      );

      expect(otpNotice, isNull);
    });

    testWidgets('FinoraBankSyncBanner renders gracefully on test environment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinoraBankSyncBanner(userId: 'test_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // On web/test environment where permission is false, the activation banner or container renders
      expect(find.byType(FinoraBankSyncBanner), findsOneWidget);
    });
  });
}

