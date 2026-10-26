import '../models/coerce.dart';
import 'supabase_bridge.dart';

class TrashItemModel {
  final String id;
  final String collectionName;
  final String label;
  final DateTime? deletedAt;
  final int purgeAfter;
  final Map<String, dynamic> rawData;

  const TrashItemModel({
    required this.id,
    required this.collectionName,
    required this.label,
    this.deletedAt,
    this.purgeAfter = 0,
    required this.rawData,
  });

  int get daysRemaining {
    if (purgeAfter <= 0) return 30;
    final msDiff = purgeAfter - DateTime.now().millisecondsSinceEpoch;
    if (msDiff <= 0) return 0;
    return (msDiff / (1000 * 60 * 60 * 24)).ceil();
  }

  String get collectionLabel {
    switch (collectionName) {
      case 'transactions':
        return 'Giao dịch';
      case 'wallets':
        return 'Ví tiền';
      case 'assets':
        return 'Tài sản đầu tư';
      case 'loans':
        return 'Khoản vay / Nợ';
      case 'goals':
        return 'Mục tiêu tiết kiệm';
      case 'budgets':
        return 'Ngân sách';
      case 'categories':
        return 'Danh mục';
      default:
        return collectionName;
    }
  }
}

class TrashRepository {
  static const List<String> trashCollections = [
    'transactions',
    'wallets',
    'assets',
    'loans',
    'goals',
    'budgets',
    'categories',
  ];

  Future<List<TrashItemModel>> getTrashItems(
    String userId, {
    String? familyId,
  }) async {
    final List<TrashItemModel> items = [];

    for (final colName in trashCollections) {
      try {
        final rows = await SupabaseBridge.loadUserCollection(
            userId: userId, collection: colName, includeDeleted: true);
        for (final data in rows) {
          if (data['_isDeleted'] == true || data['deletedAt'] != null) {
            final millis = toLongValue(data['deletedAt']);
            final delDate =
                millis > 0 ? DateTime.fromMillisecondsSinceEpoch(millis) : null;

            final label = (data['note'] ??
                    data['name'] ??
                    data['categoryName'] ??
                    data['title'] ??
                    data['id'])
                .toString();

            items.add(TrashItemModel(
              id: data['id'].toString(),
              collectionName: colName,
              label: label,
              deletedAt: delDate,
              purgeAfter: data['purgeAfter'] is num
                  ? (data['purgeAfter'] as num).toInt()
                  : 0,
              rawData: data,
            ));
          }
        }
      } catch (e) {
        // Skip inaccessible collections gracefully
      }
    }

    items.sort((a, b) {
      final tA = a.deletedAt?.millisecondsSinceEpoch ?? 0;
      final tB = b.deletedAt?.millisecondsSinceEpoch ?? 0;
      return tB.compareTo(tA);
    });

    return items;
  }

  Future<void> restoreItem(
    String userId,
    TrashItemModel item, {
    String? familyId,
  }) async {
    final restored = {...item.rawData}
      ..remove('id')
      ..remove('_isDeleted')
      ..remove('deletedAt')
      ..remove('deletedBy')
      ..remove('purgeAfter');
    await SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: item.collectionName,
      documentId: item.id,
      replace: true,
      data: {
        ...restored,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedBy': userId,
      },
    );
  }

  Future<void> permanentlyDeleteItem(
    String userId,
    TrashItemModel item, {
    String? familyId,
  }) async {
    await SupabaseBridge.deleteUserDocument(
      userId: userId,
      collection: item.collectionName,
      documentId: item.id,
    );
  }

  Future<void> purgeExpiredItems(
    String userId, {
    String? familyId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final items = await getTrashItems(userId, familyId: familyId);
    for (final item in items) {
      if (item.purgeAfter > 0 && item.purgeAfter <= nowMs) {
        await permanentlyDeleteItem(userId, item, familyId: familyId);
      }
    }
  }
}
