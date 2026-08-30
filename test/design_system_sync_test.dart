import 'package:finora/core/utils/formatters.dart';
import 'package:finora/core/widgets/bank_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web ↔ Flutter identity registry', () {
    test('contains every bank code currently declared by the web app', () {
      const webCodes = {
        'vcb',
        'mbbank',
        'tcb',
        'bidv',
        'vtb',
        'acb',
        'vpb',
        'tpb',
        'stb',
        'shb',
        'hdb',
        'vib',
        'msb',
        'ocb',
        'sea',
        'eib',
        'agri',
        'cake',
        'timo',
        'momo',
        'zalo',
        'vnpay',
        'cash',
      };
      expect(BankIconRegistry.brands.map((e) => e.code).toSet(), webCodes);
    });

    test('normalizes common legacy bank aliases', () {
      expect(BankIconRegistry.resolve('MB').code, 'mbbank');
      expect(BankIconRegistry.resolve('Techcombank').code, 'tcb');
      expect(BankIconRegistry.resolve('ZaloPay').code, 'zalo');
    });

    test('parses web hex colors and falls back safely', () {
      expect(
          BankIconRegistry.parseThemeColor('#EA0029').toARGB32(), 0xFFEA0029);
      expect(
        BankIconRegistry.parseThemeColor('invalid',
                fallback: BankIconRegistry.resolve('vcb').color)
            .toARGB32(),
        0xFF61A928,
      );
    });

    test('known web category keys never use the generic fallback', () {
      const keys = [
        'wallet',
        'credit-card',
        'utensils',
        'shopping-bag',
        'stethoscope',
        'badge-percent',
        'party-popper',
        'construction',
        'youtube',
      ];
      for (final key in keys) {
        expect(CategoryIconHelper.resolveIcon(key), isNot('💸'), reason: key);
      }
    });
  });
}
