import 'coerce.dart';

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int limitAmount;
  final String monthKey;
  final bool isRecurring;
  final bool isArchived;
  final int alertThreshold;
  final int createdAt;
  final int updatedAt;

  const Budget({
    this.id = '',
    this.userId = '',
    this.categoryId = '',
    this.categoryName = '',
    this.categoryIcon,
    this.categoryColor,
    this.limitAmount = 0,
    this.monthKey = '',
    this.isRecurring = true,
    this.isArchived = false,
    this.alertThreshold = 80,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory Budget.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    return Budget(
      id: id,
      userId: toStringValue(d['userId']),
      categoryId: toStringValue(d['categoryId']),
      categoryName: toStringValue(d['categoryName']),
      categoryIcon: toStringOrNull(d['categoryIcon']),
      categoryColor: toStringOrNull(d['categoryColor']),
      limitAmount: toLongValue(d['limitAmount']),
      monthKey: toStringValue(d['monthKey']),
      isRecurring: data?.containsKey('isRecurring') == true ? toBoolValue(d['isRecurring']) : true,
      isArchived: toBoolValue(d['isArchived']),
      alertThreshold: maxInt(toLongValue(d['alertThreshold']), 80),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryIcon': categoryIcon,
        'categoryColor': categoryColor,
        'limitAmount': limitAmount,
        'monthKey': monthKey,
        'isRecurring': isRecurring,
        'isArchived': isArchived,
        'alertThreshold': alertThreshold,
      };
}

class Goal {
  final String id;
  final String userId;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final int? targetDate;
  final String status;
  final int createdAt;
  final int updatedAt;

  const Goal({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.targetAmount = 0,
    this.savedAmount = 0,
    this.targetDate,
    this.status = 'active',
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory Goal.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final status = toStringValue(d['status']);
    return Goal(
      id: id,
      userId: toStringValue(d['userId']),
      name: toStringValue(d['name']),
      targetAmount: toLongValue(d['targetAmount']),
      savedAmount: toLongValue(d['savedAmount']),
      targetDate: d['targetDate'] == null ? null : toLongValue(d['targetDate']),
      status: status.isEmpty ? 'active' : status,
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': targetDate,
        'status': status,
      };

  Goal copyWith({int? savedAmount, String? status}) => Goal(
        id: id,
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        targetDate: targetDate,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class Loan {
  final String id;
  final String userId;
  final String personName;
  final String? name;
  final String type; // borrowed | lent
  final int principalAmount;
  final int amount;
  final int paidAmount;
  final int remainingPrincipal;
  final int startDate;
  final int? dueDate;
  final String walletId;
  final String? walletName;
  final double interestRate;
  final String? note;
  final String status;
  final int createdAt;
  final int updatedAt;

  const Loan({
    this.id = '',
    this.userId = '',
    this.personName = '',
    this.name,
    this.type = 'borrowed',
    this.principalAmount = 0,
    this.amount = 0,
    this.paidAmount = 0,
    this.remainingPrincipal = 0,
    this.startDate = 0,
    this.dueDate,
    this.walletId = '',
    this.walletName,
    this.interestRate = 0.0,
    this.note,
    this.status = 'active',
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory Loan.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final type = toStringValue(d['type']);
    final status = toStringValue(d['status']);
    return Loan(
      id: id,
      userId: toStringValue(d['userId']),
      personName: toStringValue(d['personName']),
      name: toStringOrNull(d['name']),
      type: type.isEmpty ? 'borrowed' : type,
      principalAmount: toLongValue(d['principalAmount']),
      amount: toLongValue(d['amount']),
      paidAmount: toLongValue(d['paidAmount']),
      remainingPrincipal: toLongValue(d['remainingPrincipal']),
      startDate: toLongValue(d['startDate']),
      dueDate: d['dueDate'] == null ? null : toLongValue(d['dueDate']),
      walletId: toStringValue(d['walletId']),
      walletName: toStringOrNull(d['walletName']),
      interestRate: toDoubleValue(d['interestRate']),
      note: toStringOrNull(d['note']),
      status: status.isEmpty ? 'active' : status,
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'personName': personName,
        'name': name,
        'type': type,
        'principalAmount': principalAmount,
        'amount': amount,
        'paidAmount': paidAmount,
        'remainingPrincipal': remainingPrincipal,
        'startDate': startDate,
        'dueDate': dueDate,
        'walletId': walletId,
        'walletName': walletName,
        'interestRate': interestRate,
        'note': note,
        'status': status,
      };

  Loan copyWith({String? userId}) => Loan(
        id: id,
        userId: userId ?? this.userId,
        personName: personName,
        name: name,
        type: type,
        principalAmount: principalAmount,
        amount: amount,
        paidAmount: paidAmount,
        remainingPrincipal: remainingPrincipal,
        startDate: startDate,
        dueDate: dueDate,
        walletId: walletId,
        walletName: walletName,
        interestRate: interestRate,
        note: note,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class Asset {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String? assetTypeId;
  final String? assetTypeName;
  final String? assetTypeKey;
  final String? assetIcon;
  final String? assetColor;
  final String? investmentSubtype;
  final double quantity;
  final String? unit;
  final int buyPrice;
  final int purchasePrice;
  final int costBasis;
  final int currentPrice;
  final int marketValue;
  final int profitLoss;
  final double profitLossPercent;
  final String status;
  final String? sourceWalletId;
  final String? walletId;
  final String? transactionId;
  final double interestRate;
  final int termMonths;
  final int periodAmount;
  final int totalPeriods;
  final int currentPeriod;
  final int contributedAmount;
  final int receivedAmount;
  final int feeAmount;
  final int remainingContribution;
  final int netPosition;
  final int createdAt;
  final int updatedAt;

  const Asset({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.type = 'investment',
    this.assetTypeId,
    this.assetTypeName,
    this.assetTypeKey = 'simple_asset',
    this.assetIcon,
    this.assetColor,
    this.investmentSubtype = 'simple_asset',
    this.quantity = 1.0,
    this.unit = 'lần',
    this.buyPrice = 0,
    this.purchasePrice = 0,
    this.costBasis = 0,
    this.currentPrice = 0,
    this.marketValue = 0,
    this.profitLoss = 0,
    this.profitLossPercent = 0.0,
    this.status = 'active',
    this.sourceWalletId,
    this.walletId,
    this.transactionId,
    this.interestRate = 0.0,
    this.termMonths = 0,
    this.periodAmount = 0,
    this.totalPeriods = 12,
    this.currentPeriod = 1,
    this.contributedAmount = 0,
    this.receivedAmount = 0,
    this.feeAmount = 0,
    this.remainingContribution = 0,
    this.netPosition = 0,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory Asset.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final type = toStringValue(d['type']);
    final status = toStringValue(d['status']);
    return Asset(
      id: id,
      userId: toStringValue(d['userId']),
      name: toStringValue(d['name']),
      type: type.isEmpty ? 'investment' : type,
      assetTypeId: toStringOrNull(d['assetTypeId']),
      assetTypeName: toStringOrNull(d['assetTypeName']),
      assetTypeKey: toStringOrNull(d['assetTypeKey']) ?? 'simple_asset',
      assetIcon: toStringOrNull(d['assetIcon']),
      assetColor: toStringOrNull(d['assetColor']),
      investmentSubtype: toStringOrNull(d['investmentSubtype']) ?? 'simple_asset',
      quantity: toDoubleValue(d['quantity']) < 1.0 ? 1.0 : toDoubleValue(d['quantity']),
      unit: toStringOrNull(d['unit']) ?? 'lần',
      buyPrice: toLongValue(d['buyPrice']),
      purchasePrice: toLongValue(d['purchasePrice']),
      costBasis: toLongValue(d['costBasis']),
      currentPrice: toLongValue(d['currentPrice']),
      marketValue: toLongValue(d['marketValue']),
      profitLoss: toLongValue(d['profitLoss']),
      profitLossPercent: toDoubleValue(d['profitLossPercent']),
      status: status.isEmpty ? 'active' : status,
      sourceWalletId: toStringOrNull(d['sourceWalletId']),
      walletId: toStringOrNull(d['walletId']),
      transactionId: toStringOrNull(d['transactionId']),
      interestRate: toDoubleValue(d['interestRate']),
      termMonths: toLongValue(d['termMonths']),
      periodAmount: toLongValue(d['periodAmount']),
      totalPeriods: maxInt(toLongValue(d['totalPeriods']), 12),
      currentPeriod: maxInt(toLongValue(d['currentPeriod']), 1),
      contributedAmount: toLongValue(d['contributedAmount']),
      receivedAmount: toLongValue(d['receivedAmount']),
      feeAmount: toLongValue(d['feeAmount']),
      remainingContribution: toLongValue(d['remainingContribution']),
      netPosition: toLongValue(d['netPosition']),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'type': type,
        'assetTypeId': assetTypeId,
        'assetTypeName': assetTypeName,
        'assetTypeKey': assetTypeKey,
        'assetIcon': assetIcon,
        'assetColor': assetColor,
        'investmentSubtype': investmentSubtype,
        'quantity': quantity,
        'unit': unit,
        'buyPrice': buyPrice,
        'purchasePrice': purchasePrice,
        'costBasis': costBasis,
        'currentPrice': currentPrice,
        'marketValue': marketValue,
        'profitLoss': profitLoss,
        'profitLossPercent': profitLossPercent,
        'status': status,
        'sourceWalletId': sourceWalletId,
        'walletId': walletId,
        'transactionId': transactionId,
        'interestRate': interestRate,
        'termMonths': termMonths,
        'periodAmount': periodAmount,
        'totalPeriods': totalPeriods,
        'currentPeriod': currentPeriod,
        'contributedAmount': contributedAmount,
        'receivedAmount': receivedAmount,
        'feeAmount': feeAmount,
        'remainingContribution': remainingContribution,
        'netPosition': netPosition,
      };
}

class AppNotification {
  final String id;
  final String userId;
  final String? key;
  final String? title;
  final String? message;
  final String? type;
  final bool isRead;
  final Map<String, dynamic> data;
  final int createdAt;

  const AppNotification({
    this.id = '',
    this.userId = '',
    this.key,
    this.title,
    this.message,
    this.type = 'info',
    this.isRead = false,
    this.data = const {},
    this.createdAt = 0,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final raw = d['data'];
    return AppNotification(
      id: id,
      userId: toStringValue(d['userId']),
      key: toStringOrNull(d['key']),
      title: toStringOrNull(d['title']),
      message: toStringOrNull(d['message']),
      type: toStringOrNull(d['type']) ?? 'info',
      isRead: toBoolValue(d['isRead']),
      data: raw is Map ? Map<String, dynamic>.from(raw) : const {},
      createdAt: toLongValue(d['createdAt']),
    );
  }
}

class AppSettings {
  final String currency;
  final bool allowNegativeBalance;
  final int financeMonthStartDay;
  final String dateFormat;
  final String fontValue;
  final int updatedAt;

  const AppSettings({
    this.currency = 'VND',
    this.allowNegativeBalance = false,
    this.financeMonthStartDay = 1,
    this.dateFormat = 'DD/MM/YYYY',
    this.fontValue = 'inter',
    this.updatedAt = 0,
  });

  factory AppSettings.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const {};
    final currency = toStringValue(d['currency']);
    final dateFormat = toStringValue(d['dateFormat']);
    final fontValue = toStringValue(d['fontValue']);
    return AppSettings(
      currency: currency.isEmpty ? 'VND' : currency,
      allowNegativeBalance: toBoolValue(d['allowNegativeBalance']),
      financeMonthStartDay: maxInt(toLongValue(d['financeMonthStartDay']), 1),
      dateFormat: dateFormat.isEmpty ? 'DD/MM/YYYY' : dateFormat,
      fontValue: fontValue.isEmpty ? 'inter' : fontValue,
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'currency': currency,
        'allowNegativeBalance': allowNegativeBalance,
        'financeMonthStartDay': financeMonthStartDay,
        'dateFormat': dateFormat,
        'fontValue': fontValue,
      };

  AppSettings copyWith({
    String? currency,
    bool? allowNegativeBalance,
    int? financeMonthStartDay,
    String? dateFormat,
  }) =>
      AppSettings(
        currency: currency ?? this.currency,
        allowNegativeBalance: allowNegativeBalance ?? this.allowNegativeBalance,
        financeMonthStartDay: financeMonthStartDay ?? this.financeMonthStartDay,
        dateFormat: dateFormat ?? this.dateFormat,
        fontValue: fontValue,
        updatedAt: updatedAt,
      );
}

class SmartTransactionParsed {
  final String type;
  final int amount;
  final String note;
  final String? categoryName;
  final String? walletName;
  final String? owner;
  final String? ownerName;
  final int date;
  final double confidence;

  const SmartTransactionParsed({
    required this.type,
    required this.amount,
    required this.note,
    this.categoryName,
    this.walletName,
    this.owner,
    this.ownerName,
    required this.date,
    this.confidence = 1.0,
  });
}

class SmartChatResult {
  final String? intent;
  final String? replyText;
  final String? reply;
  final List<dynamic> transactions;
  final List<String> suggestions;
  final Map<String, dynamic>? data;

  const SmartChatResult({
    this.intent,
    this.replyText,
    this.reply,
    this.transactions = const [],
    this.suggestions = const [],
    this.data,
  });
}
