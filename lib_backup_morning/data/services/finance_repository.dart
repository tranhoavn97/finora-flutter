import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/finance_models.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/coerce.dart';

FirebaseFirestore _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339',
);
CollectionReference<Map<String, dynamic>> _col(String scopeId, String name) =>
    _db.collection('families').doc(scopeId).collection(name);

String _currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

class BudgetRepository {
  Stream<List<Budget>> watchBudgets(String userId) => _col(userId, 'budgets')
      .snapshots()
      .map((s) => s.docs.map((d) => Budget.fromMap(d.id, d.data())).toList());

  Future<String> createBudget(String userId, Budget budget) async {
    final ts = FieldValue.serverTimestamp();
    final ref = await _col(userId, 'budgets').add(removeNulls(budget.toMap()
      ..['createdAt'] = ts
      ..['updatedAt'] = ts));
    return ref.id;
  }

  Future<void> updateBudget(String userId, String budgetId, Budget budget) async {
    await _col(userId, 'budgets').doc(budgetId).update(removeNulls({
      'limitAmount': budget.limitAmount,
      'isRecurring': budget.isRecurring,
      'alertThreshold': budget.alertThreshold,
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  Future<void> deleteBudget(String userId, String budgetId) =>
      _col(userId, 'budgets').doc(budgetId).delete();

  /// Auto-creates recurring budgets for the current month (+ a notification).
  Future<void> ensureBudgets(
      String userId, List<Budget> budgets, List<TransactionModel> transactions) async {
    final monthKey = _currentMonthKey();
    final currentCategoryIds = budgets
        .where((b) => b.monthKey == monthKey)
        .map((b) => b.categoryId)
        .toSet();
    final templates = budgets.where((b) => b.isRecurring && b.monthKey != monthKey);

    final batch = _db.batch();
    var hasOps = false;
    for (final t in templates) {
      if (currentCategoryIds.contains(t.categoryId)) continue;
      currentCategoryIds.add(t.categoryId);
      hasOps = true;
      final ts = FieldValue.serverTimestamp();
      final budgetRef = _col(userId, 'budgets').doc();
      batch.set(budgetRef, removeNulls(t.toMap()
        ..['monthKey'] = monthKey
        ..['createdAt'] = ts
        ..['updatedAt'] = ts));
      final notifRef = _col(userId, 'notifications').doc();
      batch.set(notifRef, removeNulls({
        'userId': userId,
        'title': 'Ngân sách định kỳ mới',
        'message': 'Ngân sách cho ${t.categoryName} đã được tự động tạo cho tháng này.',
        'type': 'info',
        'isRead': false,
        'createdAt': ts,
      }));
    }
    if (hasOps) await batch.commit();
  }
}

class AssetRepository {
  Stream<List<Asset>> watchAssets(String userId) => _col(userId, 'assets')
      .snapshots()
      .map((s) => s.docs.map((d) => Asset.fromMap(d.id, d.data())).toList());

  Future<String> createAsset(String userId, Asset asset) async {
    final ts = FieldValue.serverTimestamp();
    final ref = await _col(userId, 'assets').add(removeNulls(asset.toMap()
      ..['createdAt'] = ts
      ..['updatedAt'] = ts));
    return ref.id;
  }

  Future<void> updateAsset(String userId, String assetId, Asset asset) =>
      _col(userId, 'assets').doc(assetId).update(removeNulls(asset.toMap()
        ..['updatedAt'] = FieldValue.serverTimestamp()));

  Future<void> deleteAsset(String userId, String assetId) =>
      _col(userId, 'assets').doc(assetId).delete();
}

class LoanRepository {
  Stream<List<Loan>> watchLoans(String userId) => _col(userId, 'loans')
      .snapshots()
      .map((s) => s.docs.map((d) => Loan.fromMap(d.id, d.data())).toList());

  Future<String> createLoan(String userId, Loan loan) async {
    final ts = FieldValue.serverTimestamp();
    final ref = await _col(userId, 'loans').add(removeNulls(loan.toMap()
      ..['createdAt'] = ts
      ..['updatedAt'] = ts));
    return ref.id;
  }

  Future<void> updateLoan(String userId, String loanId, Loan loan) =>
      _col(userId, 'loans').doc(loanId).update(removeNulls(loan.toMap()
        ..['updatedAt'] = FieldValue.serverTimestamp()));

  Future<void> deleteLoan(String userId, String loanId) =>
      _col(userId, 'loans').doc(loanId).delete();
}

class GoalRepository {
  Stream<List<Goal>> watchGoals(String userId) => _col(userId, 'goals')
      .snapshots()
      .map((s) => s.docs.map((d) => Goal.fromMap(d.id, d.data())).toList());

  Future<String> createGoal(String userId, Goal goal) async {
    final ts = FieldValue.serverTimestamp();
    final ref = await _col(userId, 'goals').add(removeNulls(goal.toMap()
      ..['createdAt'] = ts
      ..['updatedAt'] = ts));
    return ref.id;
  }

  Future<void> updateGoal(String userId, String goalId, Goal goal) =>
      _col(userId, 'goals').doc(goalId).update(removeNulls(goal.toMap()
        ..['updatedAt'] = FieldValue.serverTimestamp()));

  Future<void> deleteGoal(String userId, String goalId) =>
      _col(userId, 'goals').doc(goalId).delete();
}

class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _col(userId, 'notifications').snapshots().map(
          (s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());

  Future<void> markAsRead(String userId, String id) =>
      _col(userId, 'notifications').doc(id).update({'isRead': true});

  Future<void> deleteNotification(String userId, String id) =>
      _col(userId, 'notifications').doc(id).delete();
}

class CategoryRepository {
  Stream<List<Category>> watchCategories(String userId) => _col(userId, 'categories')
      .snapshots()
      .map((s) => s.docs.map((d) => Category.fromMap(d.id, d.data())).toList());

  Future<String> createCategory(String userId, Category category) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = await _col(userId, 'categories').add(removeNulls({
      'userId': userId,
      'name': category.name,
      'icon': category.icon,
      'color': category.color ?? '#16C784',
      'categoryGroup': category.categoryGroup,
      'isArchived': category.isArchived,
      'createdAt': now,
      'updatedAt': now,
    }));
    return ref.id;
  }

  Future<void> updateCategory(String userId, String categoryId, Category category) =>
      _col(userId, 'categories').doc(categoryId).update(removeNulls({
        'name': category.name,
        'icon': category.icon,
        'color': category.color ?? '#16C784',
        'categoryGroup': category.categoryGroup,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }));

  Future<void> deleteCategory(String userId, String categoryId) =>
      _col(userId, 'categories').doc(categoryId).delete();
}

class SettingsRepository {
  Future<AppSettings> getAppSettings(String userId) async {
    final snap = await _col(userId, 'settings').doc('app').get();
    if (!snap.exists) return const AppSettings();
    return AppSettings.fromMap(snap.data());
  }

  Future<void> saveAppSettings(String userId, AppSettings settings) =>
      _col(userId, 'settings').doc('app').set(removeNulls(settings.toMap()
        ..['updatedAt'] = DateTime.now().millisecondsSinceEpoch));
}
