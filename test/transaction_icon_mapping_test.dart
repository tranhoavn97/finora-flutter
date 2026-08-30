import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/utils/formatters.dart';

void main() {
  group('system transaction icon mapping', () {
    test('does not fall back to a category icon for transfers', () {
      expect(
        CategoryIconHelper.resolveTransactionIcon(
          transactionType: 'transfer',
          categoryIcon: 'landmark',
        ),
        '⇄',
      );
    });

    test('distinguishes card payment and debt operations', () {
      expect(
        CategoryIconHelper.resolveTransactionIcon(
          transactionType: 'credit_card_payment',
        ),
        '💳',
      );
      expect(
        CategoryIconHelper.resolveTransactionIcon(
          transactionType: 'loan_repayment_received',
        ),
        '🪙',
      );
      expect(
        CategoryIconHelper.resolveTransactionIcon(
          transactionType: 'debt_repayment_paid',
        ),
        '🧾',
      );
    });
  });
}
