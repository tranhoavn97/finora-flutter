import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_parser.dart';

void main() {
  ParsedBankTransaction? parse(String text) => BankNotificationParser.parse(
      rawId: 'real-event',
      packageName: 'com.bank',
      title: 'Ngân hàng',
      text: text);
  test(
      'Never interprets date hyphens, a balance or promotional money as spending',
      () {
    for (final text in [
      'Số dư tài khoản 8.500.000 VND ngày 30-10-2026',
      'Ưu đãi hoàn tiền +50.000 VND khi mở tài khoản',
      'Chuyển tiền -50.000 VND không thành công',
      'Tài khoản 012345678900 cập nhật ngày 30-10-2026',
      'Giao dịch đang chờ xác thực OTP: 123456 -10.000 VND',
    ]) {
      expect(parse(text), isNull, reason: text);
    }
  });
  test('Signed amount wins over date and remaining balance', () {
    final result =
        parse('30-10-2026 TK 0123456 GD: -50.000 VND. SD: 8.500.000 VND');
    expect(result?.amount, 50000);
    expect(result?.type, 'expense');
  });
  test(
      'Supports Vietnamese credit, debit, currency symbol and decimal separators',
      () {
    expect(parse('Tài khoản 0123456 ghi có 1.500.000 VND')?.type, 'income');
    expect(parse('TK 0123456 ghi no 50,000 VND')?.amount, 50000);
    expect(parse('Bạn nhận được 250.000đ từ người gửi')?.type, 'income');
    expect(parse('Bạn đã chuyển 125.000 ₫ thành công')?.amount, 125000);
    expect(BankNotificationParser.parseAmount('1.250,50'), 1250.5);
    expect(BankNotificationParser.parseAmount('1,250.50'), 1250.5);
    expect(BankNotificationParser.parseAmount('1250,50'), 1250.5);
  });
  test('Bank mapping supports brands beyond original four examples', () {
    for (final name in [
      'hdbank',
      'shb',
      'eximbank',
      'seabank',
      'liobank',
      'namabank',
      'cimb',
      'shinhan'
    ]) {
      expect(
          BankNotificationParser.resolveBank('vn.$name.mobile', '').code, name);
    }
  });
}
