import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/services/bank_notification_source.dart';

void main() {
  const ncbTitle = 'Nhận chuyển khoản';
  const ncbBody = '''Ngày 15/11/2026 00:04
Tài khoản: 108542480958
Phát sinh: +1,000,000 VND
Số dư: +2,734,539 VND
Nội dung: TRAN MANH HOA chuyen tien''';

  group('NCB (Ngân hàng Quốc Dân) notification capture & balance parsing', () {
    test('BankNotificationSource accepts all NCB package variants even when title/body omits word NCB', () {
      for (final pkg in const [
        'com.ncb.bank',
        'com.ncb.izimobile',
        'vn.com.ncb.izimobile',
        'com.vnpay.ncb',
      ]) {
        expect(
          BankNotificationSource.accepts(pkg, ncbTitle),
          isTrue,
          reason: 'Expected NCB package $pkg to be accepted',
        );
      }
    });

    test('Parses exact NCB screenshot notification delta (+1,000,000) and signed ending balance (+2,734,539)', () {
      final parsed = BankNotificationParser.parse(
        rawId: 'ncb_real_1',
        packageName: 'com.ncb.bank',
        title: ncbTitle,
        text: ncbBody,
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode, 'ncb');
      expect(parsed.bankName.toUpperCase(), contains('NCB'));
      expect(parsed.type, 'income');
      expect(parsed.amount, 1000000);
      expect(parsed.balanceAfter, 2734539);
      expect(parsed.accountNumber, '108542480958');
    });

    test('Parses NCB outgoing transfer and keeps Số dư separate from Phát sinh', () {
      const ncbExpense = '''Ngày 15/11/2026 08:15
Tài khoản: 108542480958
Phát sinh: -500,000 VND
Số dư: +2,234,539 VND
Nội dung: Thanh toan hoa don''';

      final parsed = BankNotificationParser.parse(
        rawId: 'ncb_real_2',
        packageName: 'com.ncb.bank',
        title: 'Biến động số dư',
        text: ncbExpense,
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode, 'ncb');
      expect(parsed.type, 'expense');
      expect(parsed.amount, 500000);
      expect(parsed.balanceAfter, 2234539);
    });
  });
}
