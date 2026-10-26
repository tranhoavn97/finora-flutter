import '../models/coerce.dart';
import 'supabase_bridge.dart';

class ActivityLogModel {
  final String id;
  final String action;
  final String? type;
  final String collectionName;
  final String? docId;
  final String? details;
  final String userId;
  final String? actorId;
  final String? actorName;
  final String? actorTag;
  final DateTime? createdAt;

  const ActivityLogModel({
    required this.id,
    required this.action,
    this.type,
    required this.collectionName,
    this.docId,
    this.details,
    required this.userId,
    this.actorId,
    this.actorName,
    this.actorTag,
    this.createdAt,
  });

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> d) {
    final millis = toLongValue(d['createdAt']);
    final date =
        millis > 0 ? DateTime.fromMillisecondsSinceEpoch(millis) : null;

    return ActivityLogModel(
      id: id,
      action: d['action']?.toString() ?? '',
      type: d['type']?.toString(),
      collectionName: d['collectionName']?.toString() ?? '',
      docId: d['docId']?.toString(),
      details: d['details']?.toString(),
      userId: d['userId']?.toString() ?? '',
      actorId: d['actorId']?.toString(),
      actorName: d['actorName']?.toString(),
      actorTag: d['actorTag']?.toString(),
      createdAt: date,
    );
  }
}

class ActivityLogRepository {
  Future<List<ActivityLogModel>> getActivityLogs(
    String userId, {
    String? familyId,
    int limitCount = 50,
  }) async {
    try {
      final rows = await SupabaseBridge.loadUserCollection(
          userId: userId, collection: 'activityLogs');
      final list = rows
          .map((row) => ActivityLogModel.fromMap(row['id'].toString(), row))
          .toList()
        ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
      return list.take(limitCount).toList();
    } catch (e) {
      // Fallback query if ordering without index fails
      try {
        return [];
      } catch (err) {
        return [];
      }
    }
  }

  Future<void> logActivity(
    String userId, {
    required String action,
    required String collectionName,
    String type = 'user',
    String? docId,
    String? details,
    String? actorName,
    String? actorTag,
    String? familyId,
  }) async {
    try {
      await SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: 'activityLogs',
        documentId: SupabaseBridge.newDocumentId(),
        replace: true,
        data: {
          'action': action,
          'type': type,
          'collectionName': collectionName,
          'docId': docId,
          'details': details,
          'userId': userId,
          'actorId': userId,
          'actorName': actorName ?? 'Người dùng',
          'actorTag': actorTag,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {}
  }
}
