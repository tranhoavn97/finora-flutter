import '../models/category.dart';
import '../models/coerce.dart';
import '../models/finance_models.dart';
import '../models/transaction.dart';
import 'supabase_bridge.dart';

String _now() => DateTime.now().toUtc().toIso8601String();

Stream<List<T>> _watch<T>(String userId, String collection,
        T Function(String id, Map<String, dynamic> data) fromMap) =>
    SupabaseBridge.watchUserCollection(userId: userId, collection: collection)
        .map((rows) => rows
            .where((row) => row['deletedAt'] == null)
            .map((row) => fromMap(row['id'].toString(), row))
            .toList());

Future<String> _create(
    String userId, String collection, Map<String, dynamic> data) async {
  final id = SupabaseBridge.newDocumentId();
  await SupabaseBridge.saveUserDocument(
    userId: userId,
    collection: collection,
    documentId: id,
    replace: true,
    data: removeNulls(
        {...data, 'userId': userId, 'createdAt': _now(), 'updatedAt': _now()}),
  );
  return id;
}

Future<void> _update(String userId, String collection, String id,
        Map<String, dynamic> data) =>
    SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: collection,
      documentId: id,
      data: removeNulls({...data, 'userId': userId, 'updatedAt': _now()}),
    );

Future<void> _delete(String userId, String collection, String id) =>
    SupabaseBridge.deleteUserDocument(
        userId: userId, collection: collection, documentId: id);

String _currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

class BudgetRepository {
  Stream<List<Budget>> watchBudgets(String userId, {String? familyId}) =>
      _watch(userId, 'budgets', Budget.fromMap);
  Future<String> createBudget(String userId, Budget budget,
          {String? familyId}) =>
      _create(userId, 'budgets', budget.toMap());
  Future<void> updateBudget(String userId, String id, Budget budget,
          {String? familyId}) =>
      _update(userId, 'budgets', id, budget.toMap());
  Future<void> deleteBudget(String userId, String id, {String? familyId}) =>
      _delete(userId, 'budgets', id);

  Future<void> ensureBudgets(
      String userId, List<Budget> budgets, List<TransactionModel> transactions,
      {String? familyId}) async {
    final monthKey = _currentMonthKey();
    final existing = budgets
        .where((budget) => budget.monthKey == monthKey)
        .map((budget) => budget.categoryId)
        .toSet();
    for (final template
        in budgets.where((b) => b.isRecurring && b.monthKey != monthKey)) {
      if (!existing.add(template.categoryId)) continue;
      await _create(
          userId, 'budgets', template.toMap()..['monthKey'] = monthKey);
      await _create(userId, 'notifications', {
        'title': 'Ngân sách định kỳ mới',
        'message':
            'Ngân sách cho ${template.categoryName} đã được tự động tạo cho tháng này.',
        'type': 'info',
        'isRead': false,
      });
    }
  }
}

class AssetRepository {
  Stream<List<Asset>> watchAssets(String userId, {String? familyId}) =>
      _watch(userId, 'assets', Asset.fromMap);
  Future<String> createAsset(String userId, Asset asset, {String? familyId}) =>
      _create(userId, 'assets', asset.toMap());
  Future<void> updateAsset(String userId, String id, Asset asset,
          {String? familyId}) =>
      _update(userId, 'assets', id, asset.toMap());
  Future<void> deleteAsset(String userId, String id, {String? familyId}) =>
      _delete(userId, 'assets', id);
}

class LoanRepository {
  Stream<List<Loan>> watchLoans(String userId, {String? familyId}) =>
      _watch(userId, 'loans', Loan.fromMap);
  Future<String> createLoan(String userId, Loan loan, {String? familyId}) =>
      _create(userId, 'loans', loan.toMap());
  Future<void> updateLoan(String userId, String id, Loan loan,
          {String? familyId}) =>
      _update(userId, 'loans', id, loan.toMap());
  Future<void> deleteLoan(String userId, String id, {String? familyId}) =>
      _delete(userId, 'loans', id);
}

class GoalRepository {
  Stream<List<Goal>> watchGoals(String userId, {String? familyId}) =>
      _watch(userId, 'goals', Goal.fromMap);
  Future<String> createGoal(String userId, Goal goal, {String? familyId}) =>
      _create(userId, 'goals', goal.toMap());
  Future<void> updateGoal(String userId, String id, Goal goal,
          {String? familyId}) =>
      _update(userId, 'goals', id, goal.toMap());
  Future<void> deleteGoal(String userId, String id, {String? familyId}) =>
      _delete(userId, 'goals', id);
}

class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId,
          {String? familyId}) =>
      _watch(userId, 'notifications', AppNotification.fromMap);
  Future<void> markAsRead(String userId, String id, {String? familyId}) =>
      _update(userId, 'notifications', id, {'isRead': true});
  Future<void> deleteNotification(String userId, String id,
          {String? familyId}) =>
      _delete(userId, 'notifications', id);
}

class CategoryRepository {
  Stream<List<Category>> watchCategories(String userId, {String? familyId}) =>
      _watch(userId, 'categories', Category.fromMap);
  Map<String, dynamic> _map(Category category) => {
        'name': category.name,
        'icon': category.icon,
        'color': category.color ?? '#16C784',
        'categoryGroup': category.categoryGroup,
        'isArchived': category.isArchived,
      };
  Future<String> createCategory(String userId, Category category,
          {String? familyId}) =>
      _create(userId, 'categories', _map(category));
  Future<void> updateCategory(String userId, String id, Category category,
          {String? familyId}) =>
      _update(userId, 'categories', id, _map(category));
  Future<void> deleteCategory(String userId, String id, {String? familyId}) =>
      _delete(userId, 'categories', id);
}

class SettingsRepository {
  Future<AppSettings> getAppSettings(String userId, {String? familyId}) async {
    final rows = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'settings');
    final app = rows.where((row) => row['id'] == 'app').firstOrNull;
    return app == null ? const AppSettings() : AppSettings.fromMap(app);
  }

  Future<void> saveAppSettings(String userId, AppSettings settings,
          {String? familyId}) =>
      SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: 'settings',
        documentId: 'app',
        data: {...settings.toMap(), 'userId': userId, 'updatedAt': _now()},
      );
}
