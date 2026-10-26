import 'coerce.dart';

class Wallet {
  final String id;
  final String name;
  final String type;
  final String owner;
  final String ownerName;
  final String? bankCode;
  final String? bankName;
  final String? accountNumber;
  final String? themeColor;
  final int initialBalance;
  final bool hasInitialBalance;
  final int balance;
  final int creditLimit;
  final int initialDebt;
  final bool hasInitialDebt;
  final int currentDebt;
  final int statementDay;
  final int paymentDueDay;
  final int minimumPaymentPercent;
  final int createdAt;
  final int updatedAt;

  const Wallet({
    this.id = '',
    this.name = '',
    this.type = 'cash',
    this.owner = 'husband',
    this.ownerName = 'Chồng',
    this.bankCode,
    this.bankName,
    this.accountNumber,
    this.themeColor,
    this.initialBalance = 0,
    this.hasInitialBalance = true,
    this.balance = 0,
    this.creditLimit = 0,
    this.initialDebt = 0,
    this.hasInitialDebt = true,
    this.currentDebt = 0,
    this.statementDay = 1,
    this.paymentDueDay = 15,
    this.minimumPaymentPercent = 5,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  bool get isCreditCard => type == 'credit_card';

  factory Wallet.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final type = toStringValue(d['type']);
    final owner = toStringValue(d['owner']);
    final ownerName = toStringValue(d['ownerName']);
    return Wallet(
      id: id,
      name: toStringValue(d['name']),
      type: type.isEmpty ? 'cash' : type,
      owner: owner.isEmpty ? 'husband' : owner,
      ownerName: ownerName.isEmpty ? 'Chồng' : ownerName,
      bankCode: toStringOrNull(d['bankCode']),
      bankName: toStringOrNull(d['bankName']),
      accountNumber: toStringOrNull(d['accountNumber']),
      themeColor: toStringOrNull(d['themeColor']),
      initialBalance: toLongValue(
        d.containsKey('rawInitialBalance')
            ? d['rawInitialBalance']
            : d['initialBalance'],
      ),
      hasInitialBalance:
          d.containsKey('initialBalance') || d.containsKey('rawInitialBalance'),
      balance: toLongValue(d['balance']),
      creditLimit: toLongValue(d['creditLimit']),
      initialDebt: toLongValue(
        d.containsKey('rawInitialDebt')
            ? d['rawInitialDebt']
            : d['initialDebt'],
      ),
      // `initialBalance` belongs to cash/bank wallets. Some legacy credit-card
      // documents contain `initialBalance: 0`; treating that as a debt
      // baseline replays the whole ledger from zero and discards the stored
      // currentDebt.
      hasInitialDebt:
          d.containsKey('initialDebt') || d.containsKey('rawInitialDebt'),
      currentDebt: toLongValue(d['currentDebt']),
      statementDay: maxInt(toLongValue(d['statementDay']), 1),
      paymentDueDay: maxInt(toLongValue(d['paymentDueDay']), 1),
      minimumPaymentPercent: maxInt(toLongValue(d['minimumPaymentPercent']), 5),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Wallet copyWith({int? balance, int? currentDebt}) => Wallet(
        id: id,
        name: name,
        type: type,
        owner: owner,
        ownerName: ownerName,
        bankCode: bankCode,
        bankName: bankName,
        accountNumber: accountNumber,
        themeColor: themeColor,
        initialBalance: initialBalance,
        hasInitialBalance: hasInitialBalance,
        balance: balance ?? this.balance,
        creditLimit: creditLimit,
        initialDebt: initialDebt,
        hasInitialDebt: hasInitialDebt,
        currentDebt: currentDebt ?? this.currentDebt,
        statementDay: statementDay,
        paymentDueDay: paymentDueDay,
        minimumPaymentPercent: minimumPaymentPercent,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
