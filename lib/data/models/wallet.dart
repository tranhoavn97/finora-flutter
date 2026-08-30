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
  final int balance;
  final int creditLimit;
  final int initialDebt;
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
    this.balance = 0,
    this.creditLimit = 0,
    this.initialDebt = 0,
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
      initialBalance: toLongValue(d['initialBalance']),
      balance: toLongValue(d['balance']),
      creditLimit: toLongValue(d['creditLimit']),
      initialDebt: toLongValue(d['initialDebt']),
      currentDebt: toLongValue(d['currentDebt']),
      statementDay: maxInt(toLongValue(d['statementDay']), 1),
      paymentDueDay: maxInt(toLongValue(d['paymentDueDay']), 1),
      minimumPaymentPercent: maxInt(toLongValue(d['minimumPaymentPercent']), 5),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    String? owner,
    String? ownerName,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? themeColor,
    int? initialBalance,
    int? balance,
    int? creditLimit,
    int? initialDebt,
    int? currentDebt,
    int? statementDay,
    int? paymentDueDay,
    int? minimumPaymentPercent,
    int? createdAt,
    int? updatedAt,
  }) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        owner: owner ?? this.owner,
        ownerName: ownerName ?? this.ownerName,
        bankCode: bankCode ?? this.bankCode,
        bankName: bankName ?? this.bankName,
        accountNumber: accountNumber ?? this.accountNumber,
        themeColor: themeColor ?? this.themeColor,
        initialBalance: initialBalance ?? this.initialBalance,
        balance: balance ?? this.balance,
        creditLimit: creditLimit ?? this.creditLimit,
        initialDebt: initialDebt ?? this.initialDebt,
        currentDebt: currentDebt ?? this.currentDebt,
        statementDay: statementDay ?? this.statementDay,
        paymentDueDay: paymentDueDay ?? this.paymentDueDay,
        minimumPaymentPercent: minimumPaymentPercent ?? this.minimumPaymentPercent,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
