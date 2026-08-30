import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction.dart';
import '../models/coerce.dart';

/// users/{userId}/transactions  (+ cascades into assets / loans / goals)
class TransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339',
  );

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection('users').doc(userId);
  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _userDoc(userId).collection('transactions');

  Stream<List<TransactionModel>> watchTransactions(String userId) async* {
    final Map<String, TransactionModel> cache = {};
    await for (final snap in _txCol(userId).snapshots()) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          cache.remove(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data != null) {
            cache[change.doc.id] = TransactionModel.fromMap(change.doc.id, data);
          }
        }
      }
      yield cache.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snap = await _txCol(userId).get();
    return snap.docs.map((d) => TransactionModel.fromMap(d.id, d.data())).toList();
  }

  Future<String> createTransaction(String userId, TransactionModel transaction) async {
    final batch = _db.batch();
    final ts = FieldValue.serverTimestamp();
    final txRef = _txCol(userId).doc();
    final data = transaction.toMap()
      ..['createdAt'] = ts
      ..['updatedAt'] = ts;

    // Auto-create an asset for a fresh investment transaction.
    if (transaction.type == 'investment' && transaction.assetId == null) {
      final assetRef = _userDoc(userId).collection('assets').doc();
      batch.set(assetRef, removeNulls({
        'userId': userId,
        'name': transaction.categoryName ?? transaction.assetName ?? 'Tài sản',
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
        'transactionId': txRef.id,
        'createdAt': ts,
        'updatedAt': ts,
      }));
      data['assetId'] = assetRef.id;
    }

    batch.set(txRef, removeNulls(data));
    await batch.commit();
    return txRef.id;
  }

  Future<void> updateTransaction(
      String userId, String transactionId, TransactionModel transaction) async {
    final data = transaction.toMap()..['updatedAt'] = FieldValue.serverTimestamp();
    await _txCol(userId).doc(transactionId).update(removeNulls(data));
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _txCol(userId).doc(transactionId).delete();
  }

  /// Deletes a transaction and reverses its side effects on the linked
  /// asset / loan / goal. Mirrors deleteTransactionAndReverse.
  Future<void> deleteTransactionAndReverse(
      String userId, TransactionModel transaction) async {
    final batch = _db.batch();
    final ts = FieldValue.serverTimestamp();
    batch.delete(_txCol(userId).doc(transaction.id));

    // --- Asset cascade ---
    if (transaction.assetId != null) {
      final assetRef = _userDoc(userId).collection('assets').doc(transaction.assetId);
      final remaining = (await _txCol(userId)
              .where('assetId', isEqualTo: transaction.assetId)
              .get())
          .docs
          .map((d) => TransactionModel.fromMap(d.id, d.data()))
          .where((t) => t.id != transaction.id)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (remaining.isEmpty) {
        batch.delete(assetRef);
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
        final profitPct = costBasis > 0 ? (profitLoss / costBasis) * 100.0 : 0.0;
        batch.update(assetRef, {
          'quantity': totalQty,
          'buyPrice': avgBuy.round(),
          'purchasePrice': avgBuy.round(),
          'costBasis': costBasis,
          'currentPrice': currentPrice,
          'marketValue': marketValue,
          'profitLoss': profitLoss,
          'profitLossPercent': profitPct,
          'updatedAt': ts,
        });
      }
    }

    // --- Loan cascade ---
    if (transaction.loanId != null) {
      final loanRef = _userDoc(userId).collection('loans').doc(transaction.loanId);
      final loanSnap = await loanRef.get();
      if (loanSnap.exists) {
        final d = loanSnap.data() ?? {};
        if (transaction.type == 'debt_repayment' ||
            transaction.type == 'loan_repayment_received') {
          final principal = (d['principalAmount'] as num?)?.toInt() ?? 0;
          final paid = (d['paidAmount'] as num?)?.toInt() ?? 0;
          final newPaid = (paid - transaction.amount).clamp(0, 1 << 62);
          final newRemaining = (principal - newPaid).clamp(0, 1 << 62);
          batch.update(loanRef, {
            'paidAmount': newPaid,
            'remainingPrincipal': newRemaining,
            'status': newRemaining <= 0 ? 'completed' : 'active',
            'updatedAt': ts,
          });
        } else if (transaction.type == 'borrowing' || transaction.type == 'lending') {
          batch.delete(loanRef);
        }
      }
    }

    // --- Goal cascade ---
    if (transaction.goalId != null && transaction.type == 'saving') {
      final goalRef = _userDoc(userId).collection('goals').doc(transaction.goalId);
      final goalSnap = await goalRef.get();
      if (goalSnap.exists) {
        final saved = (goalSnap.data()?['savedAmount'] as num?)?.toInt() ?? 0;
        batch.update(goalRef, {
          'savedAmount': (saved - transaction.amount).clamp(0, 1 << 62),
          'updatedAt': ts,
        });
      }
    }

    await batch.commit();
  }
}
