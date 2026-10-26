import '../models/transaction.dart';
import '../models/coerce.dart';
import 'supabase_bridge.dart';

/// users/{userId}/transactions (+ cascades into assets / loans / goals)
/// Also seamlessly supports families/{familyId}/transactions when familyId is active.
class TransactionRepository {
  Stream<List<TransactionModel>> watchTransactions(String userId,
      {String? familyId}) {
    return SupabaseBridge.watchUserCollection(
      userId: userId,
      collection: 'transactions',
    ).map((rows) {
      final result = rows
          .where((data) => data['deletedAt'] == null)
          .map((data) => TransactionModel.fromMap(data['id'].toString(), data))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return result;
    });
  }

  Future<List<TransactionModel>> getTransactions(String userId,
      {String? familyId}) async {
    final rows = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'transactions');
    return rows
        .where((data) => data['deletedAt'] == null)
        .map((data) => TransactionModel.fromMap(data['id'].toString(), data))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<String> createTransaction(String userId, TransactionModel transaction,
      {String? familyId}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final transactionId = transaction.id.trim().isNotEmpty
        ? transaction.id
        : SupabaseBridge.newDocumentId();
    final data = transaction.toMap()
      ..['userId'] = userId
      ..['createdAt'] = now
      ..['updatedAt'] = now;

    // Auto-create an asset for a fresh investment transaction.
    if (transaction.type == 'investment' && transaction.assetId == null) {
      final assetId = 'transaction_$transactionId';
      await SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: 'assets',
        documentId: assetId,
        replace: true,
        data: removeNulls({
          'userId': userId,
          'name':
              transaction.categoryName ?? transaction.assetName ?? 'Tài sản',
          'type': 'investment',
          'investmentSubtype': transaction.investmentSubtype ?? 'simple_asset',
          'assetTypeKey': 'simple_asset',
          'quantity': 1.0,
          'unit': 'lần',
          'buyPrice': transaction.amount,
          'purchasePrice': transaction.amount,
          'currentPrice': transaction.amount,
          'costBasis': transaction.amount,
          'marketValue': transaction.amount,
          'profitLoss': 0,
          'profitLossPercent': 0.0,
          'status': 'active',
          'transactionId': transactionId,
          'createdAt': now,
          'updatedAt': now,
        }),
      );
      data['assetId'] = assetId;
    }
    await SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: 'transactions',
      documentId: transactionId,
      data: removeNulls(data),
      replace: true,
    );
    return transactionId;
  }

  String newOperationId(String userId, {String? familyId}) =>
      SupabaseBridge.newDocumentId();

  /// One atomic operation updates the liability and the wallet ledger.
  /// A stable operationId makes retries safe after an uncertain response.
  Future<void> recordLoanRepayment(String userId,
      {required String loanId,
      required String walletId,
      required int amount,
      required String operationId,
      String? familyId}) async {
    if (amount <= 0) throw ArgumentError('Số tiền phải lớn hơn 0');
    final transactions = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'transactions');
    if (transactions.any((row) => row['id'] == operationId)) return;
    final loans = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'loans');
    final wallets = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'wallets');
    final data = loans.where((row) => row['id'] == loanId).firstOrNull;
    final wallet = wallets.where((row) => row['id'] == walletId).firstOrNull;
    if (data == null || wallet == null) {
      throw StateError('Khoản nợ hoặc ví không còn tồn tại');
    }
    if (wallet['type'] == 'credit_card') {
      throw StateError('Chọn ví tiền mặt hoặc ngân hàng');
    }
    final remaining = toLongValue(data['remainingPrincipal']);
    if (amount > remaining) throw StateError('Số tiền vượt gốc còn lại');
    final paid = toLongValue(data['paidAmount']);
    final isLent = data['type'] == 'lent';
    final tx = TransactionModel(
        id: operationId,
        userId: userId,
        loanId: loanId,
        type: isLent ? 'loan_repayment_received' : 'debt_repayment',
        amount: amount,
        date: DateTime.now().millisecondsSinceEpoch,
        walletId: walletId,
        walletName: toStringValue(wallet['name']),
        owner: toStringOrNull(wallet['owner']),
        ownerName: toStringOrNull(wallet['ownerName']),
        note: isLent ? 'Thu gốc nợ' : 'Trả gốc nợ',
        categoryName: isLent ? 'Thu gốc nợ' : 'Trả gốc nợ');
    await createTransaction(userId, tx);
    await SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: 'loans',
      documentId: loanId,
      data: {
        'paidAmount': paid + amount,
        'remainingPrincipal': remaining - amount,
        'status': remaining == amount ? 'completed' : 'active',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> updateTransaction(
      String userId, String transactionId, TransactionModel transaction,
      {String? familyId}) async {
    final rows = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'transactions');
    final previous =
        rows.where((row) => row['id'] == transactionId).firstOrNull;
    if (previous != null &&
        (previous['loanId'] != null ||
            previous['goalId'] != null ||
            previous['assetId'] != null)) {
      throw StateError('Chưa hỗ trợ sửa trực tiếp giao dịch liên kết');
    }
    await SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: 'transactions',
      documentId: transactionId,
      data: removeNulls({
        ...transaction.toMap(),
        'userId': userId,
        'createdAt':
            previous?['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      replace: true,
    );
  }

  Future<void> deleteTransaction(String userId, String transactionId,
      {String? familyId}) async {
    await SupabaseBridge.deleteUserDocument(
      userId: userId,
      collection: 'transactions',
      documentId: transactionId,
    );
  }

  /// Deletes a transaction and reverses its side effects on the linked
  /// asset / loan / goal. Mirrors deleteTransactionAndReverse.
  Future<void> deleteTransactionAndReverse(
      String userId, TransactionModel transaction,
      {String? familyId}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    if (transaction.assetId != null) {
      final remaining = (await getTransactions(userId))
          .where((t) => t.assetId == transaction.assetId)
          .where((t) => t.id != transaction.id)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (remaining.isEmpty) {
        await SupabaseBridge.deleteUserDocument(
            userId: userId,
            collection: 'assets',
            documentId: transaction.assetId!);
      } else {
        double totalQty = 0;
        double totalCost = 0;
        for (final t in remaining) {
          if (t.investmentAction == 'buy') {
            totalQty += 1.0;
            totalCost += t.amount.toDouble();
          } else if (t.investmentAction == 'sell') {
            final avg = totalQty > 0 ? totalCost / totalQty : 0.0;
            totalQty = (totalQty - 1.0).clamp(0.0, double.infinity);
            totalCost = totalQty * avg;
          }
        }
        final currentPrice = remaining.last.amount;
        final avgBuy = totalQty > 0 ? totalCost / totalQty : 0.0;
        final marketValue = (totalQty * currentPrice).round();
        final costBasis = totalCost.round();
        final profitLoss = marketValue - costBasis;
        final profitPct =
            costBasis > 0 ? (profitLoss / costBasis) * 100.0 : 0.0;
        await SupabaseBridge.saveUserDocument(
          userId: userId,
          collection: 'assets',
          documentId: transaction.assetId!,
          data: {
            'quantity': totalQty,
            'buyPrice': avgBuy.round(),
            'purchasePrice': avgBuy.round(),
            'costBasis': costBasis,
            'currentPrice': currentPrice,
            'marketValue': marketValue,
            'profitLoss': profitLoss,
            'profitLossPercent': profitPct,
            'updatedAt': now,
          },
        );
      }
    }
    if (transaction.loanId != null) {
      final loans = await SupabaseBridge.loadUserCollection(
          userId: userId, collection: 'loans');
      final loan =
          loans.where((row) => row['id'] == transaction.loanId).firstOrNull;
      if (loan != null) {
        if (transaction.type == 'debt_repayment' ||
            transaction.type == 'loan_repayment_received') {
          final principal = toLongValue(loan['principalAmount']);
          final paid = toLongValue(loan['paidAmount']);
          final newPaid = (paid - transaction.amount).clamp(0, 1 << 62);
          final newRemaining = (principal - newPaid).clamp(0, 1 << 62);
          await SupabaseBridge.saveUserDocument(
              userId: userId,
              collection: 'loans',
              documentId: transaction.loanId!,
              data: {
                'paidAmount': newPaid,
                'remainingPrincipal': newRemaining,
                'status': newRemaining <= 0 ? 'completed' : 'active',
                'updatedAt': now,
              });
        } else if (transaction.type == 'borrowing' ||
            transaction.type == 'lending') {
          await SupabaseBridge.deleteUserDocument(
              userId: userId,
              collection: 'loans',
              documentId: transaction.loanId!);
        }
      }
    }
    if (transaction.goalId != null && transaction.type == 'saving') {
      final goals = await SupabaseBridge.loadUserCollection(
          userId: userId, collection: 'goals');
      final goal =
          goals.where((row) => row['id'] == transaction.goalId).firstOrNull;
      if (goal != null) {
        final saved = toLongValue(goal['savedAmount']);
        await SupabaseBridge.saveUserDocument(
            userId: userId,
            collection: 'goals',
            documentId: transaction.goalId!,
            data: {
              'savedAmount': (saved - transaction.amount).clamp(0, 1 << 62),
              'updatedAt': now,
            });
      }
    }
    await SupabaseBridge.deleteUserDocument(
      userId: userId,
      collection: 'transactions',
      documentId: transaction.id,
    );
  }
}
