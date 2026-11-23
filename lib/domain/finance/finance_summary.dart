import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import 'transaction_member.dart';

/// Reporting semantics, independent of persistence and wallet ledger effects.
class FinanceSummary {
  final int income;
  final int expense;
  const FinanceSummary({this.income = 0, this.expense = 0});
  int get net => income - expense;
  double? get savingsRate => income > 0 ? net / income * 100 : null;

  static bool isIncome(TransactionModel tx) =>
      {'income', 'interest_income'}.contains(tx.type.trim().toLowerCase());
  static bool isExpense(TransactionModel tx) =>
      {'expense', 'interest_expense'}.contains(tx.type.trim().toLowerCase());

  factory FinanceSummary.from(Iterable<TransactionModel> transactions) {
    var income = 0, expense = 0;
    for (final tx in transactions) {
      if (isIncome(tx)) income += tx.amount;
      if (isExpense(tx)) expense += tx.amount;
    }
    return FinanceSummary(income: income, expense: expense);
  }
}

class FinanceScope {
  final DateTime? start;
  final DateTime? end;
  final String? walletId;
  final String? owner;
  final Map<String, Wallet>? walletMap;
  const FinanceScope({
    this.start,
    this.end,
    this.walletId,
    this.owner,
    this.walletMap,
  });
  factory FinanceScope.month(DateTime date) => FinanceScope(
      start: DateTime(date.year, date.month),
      end: DateTime(date.year, date.month + 1));
  bool contains(TransactionModel tx) {
    if (start != null && tx.date < start!.millisecondsSinceEpoch) return false;
    if (end != null && tx.date >= end!.millisecondsSinceEpoch) return false;
    if (walletId != null &&
        ![tx.walletId, tx.fromWalletId, tx.toWalletId, tx.creditCardId]
            .contains(walletId)) {
      return false;
    }
    if (owner != null) {
      final resolved = resolveTransactionMember(tx, walletMap: walletMap);
      if (resolved != TransactionMember.unknown) {
        return resolved.value == owner;
      }
      return [tx.owner, tx.fromOwner, tx.cardOwner].contains(owner);
    }
    return true;
  }
}
