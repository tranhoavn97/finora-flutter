import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_core/firebase_core.dart';
import '../models/family_models.dart';
import '../models/coerce.dart';

const List<String> _collectionsToMigrate = [
  'wallets',
  'categories',
  'transactions',
  'budgets',
  'budgetSnapshots',
  'budgetHistory',
  'assets',
  'assetTypes',
  'goals',
  'loans',
  'notifications',
  'settings'
];

class FamilyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339',
  );

  Stream<FamilyModel?> watchFamily(String familyId) {
    return _db.collection('families').doc(familyId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return FamilyModel.fromMap(snap.id, data);
    });
  }

  Stream<List<FamilyMemberModel>> watchMembers(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FamilyMemberModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<FamilyModel?> getFamily(String familyId) async {
    final snap = await _db.collection('families').doc(familyId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return FamilyModel.fromMap(snap.id, data);
  }

  Future<List<FamilyMemberModel>> getMembers(String familyId) async {
    final snap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
    return snap.docs
        .map((d) => FamilyMemberModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String?> getUserActiveFamilyId(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (snap.exists && snap.data() != null) {
        return snap.data()!['activeFamilyId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Tự động đảm bảo người dùng có nhóm gia đình, sao chép dữ liệu cũ nếu chưa migrate
  Future<String> ensureFamilyAndMigrate(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? {};

    // 1. Nếu đã có activeFamilyId
    final activeId = userData['activeFamilyId']?.toString();
    if (activeId != null && activeId.isNotEmpty) {
      final existing = await getFamily(activeId);
      if (existing != null) return existing.id;
    }

    // Khôi phục con trỏ hồ sơ nếu người dùng đã nằm trong memberUids của một
    // family. Trường hợp này xảy ra với thành viên được thêm từ bản web cũ.
    final joinedFamilies = await _db
        .collection('families')
        .where('memberUids', arrayContains: user.uid)
        .limit(1)
        .get();
    if (joinedFamilies.docs.isNotEmpty) {
      final familyId = joinedFamilies.docs.first.id;
      await userRef.set({'activeFamilyId': familyId}, SetOptions(merge: true));
      return familyId;
    }

    // 2. Nếu đã từng migrate
    final migStatus = userData['migrationStatus'];
    if (migStatus is Map && migStatus['migrated'] == true) {
      final mId = migStatus['familyId']?.toString();
      if (mId != null) {
        final existing = await getFamily(mId);
        if (existing != null) {
          await userRef.set({'activeFamilyId': mId}, SetOptions(merge: true));
          return existing.id;
        }
      }
    }

    // 3. Tạo family mới
    final familyRef = _db.collection('families').doc();
    final familyId = familyRef.id;
    final name = (user.displayName != null && user.displayName!.isNotEmpty)
        ? 'Gia đình của ${user.displayName}'
        : 'Gia đình của tôi';

    final ts = FieldValue.serverTimestamp();
    await familyRef.set({
      'name': name,
      'ownerId': user.uid,
      'memberUids': [user.uid],
      'memberCount': 1,
      'memberLimit': 3,
      'createdAt': ts,
      'updatedAt': ts,
    });

    await familyRef.collection('members').doc(user.uid).set({
      'displayName': user.displayName?.isNotEmpty == true
          ? user.displayName
          : (user.email?.split('@').first ?? 'Chủ nhóm'),
      'email': user.email ?? '',
      'photoURL': user.photoURL ?? '',
      'role': 'owner',
      'joinedAt': ts,
      'status': 'active',
    });

    // 4. Sao chép dữ liệu từ users/{uid} sang families/{familyId}
    var totalCopied = 0;
    for (final col in _collectionsToMigrate) {
      try {
        final oldCol = _db.collection('users').doc(user.uid).collection(col);
        final snap = await oldCol.get();
        if (snap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final d in snap.docs) {
            final targetDoc = familyRef.collection(col).doc(d.id);
            final docData = Map<String, dynamic>.from(d.data());
            docData['familyId'] = familyId;
            docData['createdBy'] = docData['createdBy'] ?? user.uid;
            docData['updatedBy'] = user.uid;
            docData['updatedAt'] = ts;
            batch.set(targetDoc, docData, SetOptions(merge: true));
            totalCopied++;
          }
          await batch.commit();
        }
      } catch (_) {}
    }

    // 5. Đánh dấu user
    await userRef.set({
      'activeFamilyId': familyId,
      'migrationStatus': {
        'migrated': true,
        'familyId': familyId,
        'migratedAt': DateTime.now().millisecondsSinceEpoch,
        'totalRecords': totalCopied,
      }
    }, SetOptions(merge: true));

    return familyId;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Tạo lời mời tham gia nhóm (mã 6 ký tự, hết hạn 7 ngày)
  Future<FamilyInvitationModel> createInvitation(
    String familyId,
    String familyName,
    String uid,
    String displayName, {
    FamilyRole role = FamilyRole.member,
    String? targetEmail,
  }) async {
    if (targetEmail == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(targetEmail.trim())) {
      throw Exception('Vui lòng nhập email hợp lệ của người nhận.');
    }
    final code = _generateInviteCode();
    final inviteRef = _db
        .collection('families')
        .doc(familyId)
        .collection('invitations')
        .doc();
    final expiresAt =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    final ts = FieldValue.serverTimestamp();

    final data = {
      'familyId': familyId,
      'familyName': familyName,
      'code': code,
      'email': targetEmail.trim().toLowerCase(),
      'role': role.toDbString(),
      'createdBy': uid,
      'createdByName': displayName,
      'createdAt': ts,
      'expiresAt': expiresAt,
      'status': 'pending',
    };

    final batch = _db.batch();
    batch.set(inviteRef, data);
    batch.set(_db.collection('invitations').doc(code), {
      ...data,
      'inviteId': inviteRef.id,
    });
    await batch.commit();

    return FamilyInvitationModel(
      id: inviteRef.id,
      familyId: familyId,
      familyName: familyName,
      code: code,
      email: targetEmail,
      role: role,
      createdBy: uid,
      createdByName: displayName,
      expiresAt: expiresAt,
      status: 'pending',
    );
  }

  /// Chấp nhận lời mời tham gia nhóm (Firestore Transaction kiểm soát max 3 thành viên)
  Future<Map<String, dynamic>> acceptInvitation(
      String rawCode, User user) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) {
      return {'success': false, 'message': 'Mã lời mời không hợp lệ.'};
    }

    try {
      final familyId = await _db.runTransaction<String>((tx) async {
        final lookupRef = _db.collection('invitations').doc(code);
        final lookupSnap = await tx.get(lookupRef);

        if (!lookupSnap.exists) {
          throw Exception('Mã lời mời không tồn tại hoặc đã bị hủy.');
        }

        final inviteData = lookupSnap.data()!;
        if (inviteData['status'] != 'pending') {
          throw Exception(
              'Mã lời mời này đã được sử dụng hoặc không còn hiệu lực.');
        }

        final expiresAt = toLongValue(inviteData['expiresAt']);
        if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
          throw Exception(
              'Mã lời mời đã hết hạn (chỉ có hiệu lực trong 7 ngày).');
        }

        final targetEmail = toStringValue(inviteData['email']);
        if (targetEmail.isNotEmpty) {
          if (targetEmail.toLowerCase() != user.email?.toLowerCase()) {
            throw Exception(
                'Lời mời này được gửi riêng cho email $targetEmail.');
          }
        }

        final fId = toStringValue(inviteData['familyId']);
        final familyRef = _db.collection('families').doc(fId);
        final familySnap = await tx.get(familyRef);

        if (!familySnap.exists) {
          throw Exception('Nhóm gia đình không còn tồn tại.');
        }

        final familyData = familySnap.data()!;
        final rawUids = familyData['memberUids'];
        final List<String> currentUids = [];
        if (rawUids is List) {
          for (final u in rawUids) {
            if (u != null) currentUids.add(u.toString());
          }
        }

        if (currentUids.contains(user.uid)) {
          throw Exception('Bạn đã là thành viên của gia đình này rồi.');
        }

        final memberCount = toLongValue(familyData['memberCount']);
        if (currentUids.length >= 3 || memberCount >= 3) {
          throw Exception('Nhóm gia đình này đã đạt tối đa 3 thành viên.');
        }

        final ts = FieldValue.serverTimestamp();

        // 1. Update family
        tx.update(familyRef, {
          'memberUids': FieldValue.arrayUnion([user.uid]),
          'memberCount': currentUids.length + 1,
          'lastJoinCode': code,
          'lastJoinedUid': user.uid,
          'updatedAt': ts,
        });

        // 2. Set member
        final memberRef = familyRef.collection('members').doc(user.uid);
        tx.set(memberRef, {
          'displayName': user.displayName?.isNotEmpty == true
              ? user.displayName
              : (user.email?.split('@').first ?? 'Thành viên'),
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'role': inviteData['role'] ?? 'member',
          'joinedAt': ts,
          'status': 'active',
        });

        // 3. Mark code accepted
        tx.update(lookupRef, {
          'status': 'accepted',
          'acceptedBy': user.uid,
          'acceptedAt': ts,
        });

        final inviteId = toStringValue(inviteData['inviteId']);
        if (inviteId.isNotEmpty) {
          final familyInviteRef =
              familyRef.collection('invitations').doc(inviteId);
          tx.update(familyInviteRef, {
            'status': 'accepted',
            'acceptedBy': user.uid,
            'acceptedAt': ts,
          });
        }

        // 4. Update user activeFamilyId
        final userDocRef = _db.collection('users').doc(user.uid);
        tx.set(userDocRef, {'activeFamilyId': fId}, SetOptions(merge: true));

        return fId;
      });

      return {
        'success': true,
        'message': 'Gia nhập nhóm gia đình thành công!',
        'familyId': familyId,
      };
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return {'success': false, 'message': msg};
    }
  }

  Future<void> updateMemberRole(
      String familyId, String memberUid, FamilyRole role) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberUid)
        .update({'role': role.toDbString()});
  }

  Future<void> updateMemberTag(String familyId, String uid, String tag) async {
    if (!const ['Chồng', 'Vợ', 'Con', 'Thành viên'].contains(tag)) {
      throw ArgumentError('Nhãn thành viên không hợp lệ');
    }
    await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(uid)
        .update({'memberTag': tag});
  }

  Future<void> removeMember(String familyId, String memberUid) async {
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(memberUid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(familyRef);
      if (!snap.exists) return;
      final rawUids = snap.data()?['memberUids'];
      final List<String> uids = [];
      if (rawUids is List) {
        for (final u in rawUids) {
          if (u != null) uids.add(u.toString());
        }
      }
      uids.remove(memberUid);
      tx.update(familyRef, {
        'memberUids': uids,
        'memberCount': max(1, uids.length),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(memberRef);
      tx.update(
          _db.collection('users').doc(memberUid), {'activeFamilyId': null});
    });
  }

  Future<void> leaveFamily(String familyId, String uid, bool isOwner) async {
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(familyRef);
      if (!snap.exists) return;
      final rawUids = snap.data()?['memberUids'];
      final List<String> uids = [];
      if (rawUids is List) {
        for (final u in rawUids) {
          if (u != null) uids.add(u.toString());
        }
      }

      if (isOwner && uids.length > 1) {
        throw Exception('Chủ nhóm cần chuyển quyền sở hữu trước khi rời nhóm.');
      }

      uids.remove(uid);
      if (uids.isEmpty) {
        tx.delete(familyRef);
      } else {
        tx.update(familyRef, {
          'memberUids': uids,
          'memberCount': uids.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.delete(familyRef.collection('members').doc(uid));
      tx.update(_db.collection('users').doc(uid), {'activeFamilyId': null});
    });
  }
}
