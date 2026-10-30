import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/utils/bank_launcher_helper.dart';
import 'package:finora/core/utils/vietqr_parser.dart';
import 'package:finora/data/services/qr_payment_draft_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final qr = VietQrParser.parse('TCB|19034567890012|250000|Ăn trưa & cà phê')!;
  test(
      'MB handoff uses payer MB but keeps recipient Techcombank, amount and memo',
      () {
    final uri = BankLauncherHelper.buildPaymentLink(
        bank: VietQrParser.supportedBanks['970422']!,
        data: qr,
        amount: 85000,
        memo: 'Ăn trưa & cà phê + 1');
    expect(uri.host, 'dl.vietqr.io');
    expect(uri.queryParameters['app'], 'mb');
    expect(uri.queryParameters['ba'], '19034567890012@tcb');
    expect(uri.queryParameters['am'], '85000');
    expect(uri.queryParameters['tn'], 'Ăn trưa & cà phê + 1');
  });
  test('Tech is not advertised as autofill and invalid amounts are refused',
      () {
    final tech = VietQrParser.supportedBanks['970407']!;
    expect(BankLauncherHelper.supportsAutofill(tech), false);
    expect(
        () => BankLauncherHelper.buildPaymentLink(
            bank: tech, data: qr, amount: 1, memo: ''),
        throwsFormatException);
    for (final amount in [0.0, -1.0, 1.5, double.nan, double.infinity]) {
      expect(
          () => BankLauncherHelper.buildPaymentLink(
              bank: VietQrParser.supportedBanks['970422']!,
              data: qr,
              amount: amount,
              memo: ''),
          throwsFormatException);
    }
  });
  test(
      'local drafts persist updates serially, isolate users and retain id for retry',
      () async {
    await Future.wait(List.generate(
        5,
        (i) => QrPaymentDraftStore.save(
            'u1',
            QrPaymentDraft(
                id: 'same',
                data: qr,
                amount: i,
                memo: 'm$i',
                walletId: 'mb',
                categoryId: 'food'))));
    final list = await QrPaymentDraftStore.list('u1');
    expect(list, hasLength(1));
    expect(list.single.amount, 4);
    expect(list.single.memo, 'm4');
    expect(list.single.data.accountNumber, qr.accountNumber);
    expect(await QrPaymentDraftStore.list('u2'), isEmpty);
    await QrPaymentDraftStore.remove('u1', 'same');
    expect(await QrPaymentDraftStore.list('u1'), isEmpty);
  });
}
