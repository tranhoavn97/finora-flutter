import 'coerce.dart';

class TransactionModel {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final int date;
  final String? note;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? categoryGroup;
  final String? merchantId;
  final String? merchantName;
  final String? walletId;
  final String? walletName;
  final String? owner;
  final String? ownerName;
  final String? fromWalletId;
  final String? fromWalletName;
  final String? toWalletId;
  final String? toWalletName;
  final String? fromOwner;
  final String? toOwner;
  final String? creditCardId;
  final String? creditCardName;
  final String? paidByOwner;
  final String? cardOwner;
  final String? loanId;
  final String? direction;
  final String? goalId;
  final String? goalName;
  final String? assetId;
  final String? assetName;
  final String? investmentSubtype;
  final String? investmentAction;
  final List<String> tags;
  final String? bankTransactionCode;
  final String? rawBankNotification;
  final String? creatorTag;
  final String? createdBy;
  final String? creatorName;
  final int createdAt;
  final int updatedAt;

  const TransactionModel({
    this.id = '',
    this.userId = '',
    this.amount = 0,
    this.type = 'expense',
    this.date = 0,
    this.note,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.categoryGroup,
    this.merchantId,
    this.merchantName,
    this.walletId,
    this.walletName,
    this.owner,
    this.ownerName,
    this.fromWalletId,
    this.fromWalletName,
    this.toWalletId,
    this.toWalletName,
    this.fromOwner,
    this.toOwner,
    this.creditCardId,
    this.creditCardName,
    this.paidByOwner,
    this.cardOwner,
    this.loanId,
    this.direction,
    this.goalId,
    this.goalName,
    this.assetId,
    this.assetName,
    this.investmentSubtype,
    this.investmentAction,
    this.tags = const [],
    this.bankTransactionCode,
    this.rawBankNotification,
    this.creatorTag,
    this.createdBy,
    this.creatorName,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final rawTags = d['tags'];
    List<String> tags;
    if (rawTags is List) {
      tags =
          rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String) {
      tags = rawTags
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      tags = const [];
    }

    String? parsedBankCode = toStringOrNull(d['bankTransactionCode']);
    String? parsedRawNotif = toStringOrNull(d['rawBankNotification']);
    for (final tag in tags) {
      if ((parsedBankCode == null || parsedBankCode.isEmpty) &&
          tag.startsWith('bank_code:')) {
        parsedBankCode = tag.substring('bank_code:'.length).trim();
      } else if ((parsedRawNotif == null || parsedRawNotif.isEmpty) &&
          tag.startsWith('bank_notif:')) {
        parsedRawNotif = tag.substring('bank_notif:'.length).trim();
      }
    }

    final type = toStringValue(d['type']);
    final rawDate = toLongValue(d['date']);
    final date =
        (rawDate > 0 && rawDate < 100000000000) ? rawDate * 1000 : rawDate;
    return TransactionModel(
      id: id,
      userId: toStringValue(d['userId']),
      amount: toMoneyValue(d['amount']),
      type: type.isEmpty ? 'expense' : type,
      date: date,
      note: toStringOrNull(d['note']),
      categoryId: toStringOrNull(d['categoryId']),
      categoryName: toStringOrNull(d['categoryName']),
      categoryIcon: toStringOrNull(d['categoryIcon']),
      categoryColor: toStringOrNull(d['categoryColor']),
      categoryGroup: toStringOrNull(d['categoryGroup']),
      merchantId: toStringOrNull(d['merchantId']),
      merchantName: toStringOrNull(d['merchantName']),
      walletId: toStringOrNull(d['walletId']),
      walletName: toStringOrNull(d['walletName']),
      owner: toStringOrNull(d['owner']),
      ownerName: toStringOrNull(d['ownerName']),
      fromWalletId: toStringOrNull(d['fromWalletId']),
      fromWalletName: toStringOrNull(d['fromWalletName']),
      toWalletId: toStringOrNull(d['toWalletId']),
      toWalletName: toStringOrNull(d['toWalletName']),
      fromOwner: toStringOrNull(d['fromOwner']),
      toOwner: toStringOrNull(d['toOwner']),
      creditCardId: toStringOrNull(d['creditCardId']),
      creditCardName: toStringOrNull(d['creditCardName']),
      paidByOwner: toStringOrNull(d['paidByOwner']),
      cardOwner: toStringOrNull(d['cardOwner']),
      loanId: toStringOrNull(d['loanId']),
      direction: toStringOrNull(d['direction']),
      goalId: toStringOrNull(d['goalId']),
      goalName: toStringOrNull(d['goalName']),
      assetId: toStringOrNull(d['assetId']),
      assetName: toStringOrNull(d['assetName']),
      investmentSubtype: toStringOrNull(d['investmentSubtype']),
      investmentAction: toStringOrNull(d['investmentAction']),
      tags: tags,
      bankTransactionCode: parsedBankCode,
      rawBankNotification: parsedRawNotif,
      creatorTag: toStringOrNull(d['creatorTag']),
      createdBy: toStringOrNull(d['createdBy']),
      creatorName: toStringOrNull(d['creatorName']),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  /// Field map written to Firestore / Supabase (createdAt/updatedAt are added by the repository).
  Map<String, dynamic> toMap() {
    final mergedTags = List<String>.from(
      tags.where(
        (t) => !t.startsWith('bank_code:') && !t.startsWith('bank_notif:'),
      ),
    );
    if (bankTransactionCode != null &&
        bankTransactionCode!.trim().isNotEmpty) {
      mergedTags.add('bank_code:${bankTransactionCode!.trim()}');
    }
    if (rawBankNotification != null &&
        rawBankNotification!.trim().isNotEmpty) {
      mergedTags.add('bank_notif:${rawBankNotification!.trim()}');
    }
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'date': date,
      'note': note,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'categoryGroup': categoryGroup,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'walletId': walletId,
      'walletName': walletName,
      'owner': owner,
      'ownerName': ownerName,
      'fromWalletId': fromWalletId,
      'fromWalletName': fromWalletName,
      'toWalletId': toWalletId,
      'toWalletName': toWalletName,
      'fromOwner': fromOwner,
      'toOwner': toOwner,
      'creditCardId': creditCardId,
      'creditCardName': creditCardName,
      'paidByOwner': paidByOwner,
      'cardOwner': cardOwner,
      'loanId': loanId,
      'direction': direction,
      'goalId': goalId,
      'goalName': goalName,
      'assetId': assetId,
      'assetName': assetName,
      'investmentSubtype': investmentSubtype,
      'investmentAction': investmentAction,
      'tags': mergedTags,
      'bankTransactionCode': bankTransactionCode,
      'rawBankNotification': rawBankNotification,
      'creatorTag': creatorTag,
      'createdBy': createdBy,
      'creatorName': creatorName,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    int? amount,
    String? type,
    int? date,
    String? note,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? categoryGroup,
    String? merchantId,
    String? merchantName,
    String? walletId,
    String? walletName,
    String? owner,
    String? ownerName,
    String? fromWalletId,
    String? fromWalletName,
    String? toWalletId,
    String? toWalletName,
    String? fromOwner,
    String? toOwner,
    String? creditCardId,
    String? creditCardName,
    String? paidByOwner,
    String? cardOwner,
    String? loanId,
    String? direction,
    String? goalId,
    String? goalName,
    String? assetId,
    String? assetName,
    String? investmentSubtype,
    String? investmentAction,
    List<String>? tags,
    String? bankTransactionCode,
    String? rawBankNotification,
    String? creatorTag,
    String? createdBy,
    String? creatorName,
    int? createdAt,
    int? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      owner: owner ?? this.owner,
      ownerName: ownerName ?? this.ownerName,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      fromWalletName: fromWalletName ?? this.fromWalletName,
      toWalletId: toWalletId ?? this.toWalletId,
      toWalletName: toWalletName ?? this.toWalletName,
      fromOwner: fromOwner ?? this.fromOwner,
      toOwner: toOwner ?? this.toOwner,
      creditCardId: creditCardId ?? this.creditCardId,
      creditCardName: creditCardName ?? this.creditCardName,
      paidByOwner: paidByOwner ?? this.paidByOwner,
      cardOwner: cardOwner ?? this.cardOwner,
      loanId: loanId ?? this.loanId,
      direction: direction ?? this.direction,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      investmentSubtype: investmentSubtype ?? this.investmentSubtype,
      investmentAction: investmentAction ?? this.investmentAction,
      tags: tags ?? this.tags,
      bankTransactionCode: bankTransactionCode ?? this.bankTransactionCode,
      rawBankNotification: rawBankNotification ?? this.rawBankNotification,
      creatorTag: creatorTag ?? this.creatorTag,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLinked =>
      (loanId != null && loanId!.isNotEmpty) ||
      (goalId != null && goalId!.isNotEmpty) ||
      (assetId != null && assetId!.isNotEmpty);

  String? get linkedReason {
    if (loanId != null && loanId!.isNotEmpty) return 'khoản vay / nợ';
    if (goalId != null && goalId!.isNotEmpty) return 'mục tiêu tích lũy';
    if (assetId != null && assetId!.isNotEmpty) return 'tài sản / đầu tư';
    return null;
  }
}
