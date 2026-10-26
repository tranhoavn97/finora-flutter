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
    final type = toStringValue(d['type']);
    final rawDate = toLongValue(d['date']);
    final date = (rawDate > 0 && rawDate < 100000000000) ? rawDate * 1000 : rawDate;
    final rawCreatedAt = toLongValue(d['createdAt']);
    final createdAt = (rawCreatedAt > 0 && rawCreatedAt < 100000000000) ? rawCreatedAt * 1000 : rawCreatedAt;
    return TransactionModel(
      id: id,
      userId: toStringValue(d['userId']),
      amount: toLongValue(d['amount']),
      type: type.isEmpty ? 'expense' : type,
      date: date,
      note: toStringOrNull(d['note']),
      categoryId: toStringOrNull(d['categoryId']),
      categoryName: toStringOrNull(d['categoryName']),
      categoryIcon: toStringOrNull(d['categoryIcon']),
      categoryColor: toStringOrNull(d['categoryColor']),
      categoryGroup: toStringOrNull(d['categoryGroup']),
      merchantId: toStringOrNull(d['merchantId']),
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
      creatorTag: toStringOrNull(d['creatorTag']),
      createdBy: toStringOrNull(d['createdBy']),
      creatorName: toStringOrNull(d['creatorName']),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  /// Field map written to Firestore (createdAt/updatedAt are added by the repository).
  Map<String, dynamic> toMap() => {
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
        'tags': tags,
        'creatorTag': creatorTag,
        'createdBy': createdBy,
        'creatorName': creatorName,
      };

  TransactionModel copyWith(
      {String? id, String? userId, int? amount, String? type}) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date,
      note: note,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      categoryGroup: categoryGroup,
      merchantId: merchantId,
      walletId: walletId,
      walletName: walletName,
      owner: owner,
      ownerName: ownerName,
      fromWalletId: fromWalletId,
      fromWalletName: fromWalletName,
      toWalletId: toWalletId,
      toWalletName: toWalletName,
      fromOwner: fromOwner,
      toOwner: toOwner,
      creditCardId: creditCardId,
      creditCardName: creditCardName,
      paidByOwner: paidByOwner,
      cardOwner: cardOwner,
      loanId: loanId,
      direction: direction,
      goalId: goalId,
      goalName: goalName,
      assetId: assetId,
      assetName: assetName,
      investmentSubtype: investmentSubtype,
      investmentAction: investmentAction,
      tags: tags,
      creatorTag: creatorTag,
      createdBy: createdBy,
      creatorName: creatorName,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
