import '../../data/models/transaction.dart';

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
  const FinanceScope({this.start, this.end, this.walletId, this.owner});
  factory FinanceScope.month(DateTime date) => FinanceScope(
      start: DateTime(date.year, date.month),
      end: DateTime(date.year, date.month + 1));
  bool contains(TransactionModel tx) =>
      (start == null || tx.date >= start!.millisecondsSinceEpoch) &&
      (end == null || tx.date < end!.millisecondsSinceEpoch) &&
      (walletId == null ||
          [tx.walletId, tx.fromWalletId, tx.toWalletId, tx.creditCardId]
              .contains(walletId)) &&
      (owner == null ||
          [tx.owner, tx.fromOwner, tx.toOwner, tx.cardOwner].contains(owner));
}
