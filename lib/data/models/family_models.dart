import 'coerce.dart';

enum FamilyRole {
  owner,
  admin,
  member,
  limited;

  static FamilyRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return FamilyRole.owner;
      case 'admin':
      case 'co_owner':
      case 'spouse':
        return FamilyRole.admin;
      case 'limited':
      case 'viewer':
        return FamilyRole.limited;
      case 'member':
      default:
        return FamilyRole.member;
    }
  }

  String toDbString() {
    switch (this) {
      case FamilyRole.owner:
        return 'owner';
      case FamilyRole.admin:
        return 'admin';
      case FamilyRole.limited:
        return 'limited';
      case FamilyRole.member:
        return 'member';
    }
  }

  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Chủ hộ';
      case FamilyRole.admin:
        return 'Đồng quản lý';
      case FamilyRole.limited:
        return 'Giới hạn';
      case FamilyRole.member:
        return 'Thành viên';
    }
  }

  String get permissionSummary {
    switch (this) {
      case FamilyRole.owner:
        return 'Toàn quyền quản trị, phân quyền, mời & đồng bộ sổ chung';
      case FamilyRole.admin:
        return 'Xem, thêm/sửa giao dịch, quản lý ví & đồng bộ dữ liệu Vợ/Chồng';
      case FamilyRole.member:
        return 'Xem báo cáo chung, ghi thu chi & đồng bộ giao dịch mới';
      case FamilyRole.limited:
        return 'Chỉ xem báo cáo được chia sẻ & ghi nháp giao dịch';
    }
  }
}

class FamilyModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberUids;
  final int memberCount;
  final int? createdAt;
  final int? updatedAt;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberUids,
    required this.memberCount,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyModel.fromMap(String id, Map<String, dynamic> map) {
    final rawUids = map['memberUids'];
    final List<String> uids = [];
    if (rawUids is List) {
      for (final u in rawUids) {
        if (u != null) uids.add(u.toString());
      }
    }
    return FamilyModel(
      id: id,
      name: toStringValue(map['name']).isNotEmpty
          ? toStringValue(map['name'])
          : 'Gia đình',
      ownerId: toStringValue(map['ownerId']),
      memberUids: uids,
      memberCount: toLongValue(map['memberCount']) > 0
          ? toLongValue(map['memberCount'])
          : (uids.isNotEmpty ? uids.length : 1),
      createdAt: toLongOrNull(map['createdAt']),
      updatedAt: toLongOrNull(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'memberUids': memberUids,
        'memberCount': memberCount,
      };
}

class FamilyMemberModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final FamilyRole role;
  final String? memberTag;
  final int? joinedAt;
  final String status;

  const FamilyMemberModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.role,
    this.memberTag,
    this.joinedAt,
    this.status = 'active',
  });

  factory FamilyMemberModel.fromMap(String uid, Map<String, dynamic> map) {
    return FamilyMemberModel(
      uid: uid,
      displayName: toStringValue(map['displayName']).isNotEmpty
          ? toStringValue(map['displayName'])
          : 'Thành viên',
      email: toStringValue(map['email']),
      photoURL: toStringOrNull(map['photoURL']),
      role: FamilyRole.fromString(toStringOrNull(map['role'])),
      memberTag: toStringOrNull(map['memberTag']),
      joinedAt: toLongOrNull(map['joinedAt']),
      status: toStringValue(map['status']).isNotEmpty
          ? toStringValue(map['status'])
          : 'active',
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'role': role.toDbString(),
        'memberTag': memberTag,
        'status': status,
      };
}

class FamilyInvitationModel {
  final String id;
  final String familyId;
  final String? familyName;
  final String code;
  final String? email;
  final FamilyRole role;
  final String? memberTag;
  final String createdBy;
  final String? createdByName;
  final int? createdAt;
  final int expiresAt;
  final String status;

  const FamilyInvitationModel({
    required this.id,
    required this.familyId,
    this.familyName,
    required this.code,
    this.email,
    required this.role,
    this.memberTag,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
  });

  factory FamilyInvitationModel.fromMap(String id, Map<String, dynamic> map) {
    return FamilyInvitationModel(
      id: id,
      familyId: toStringValue(map['familyId']),
      familyName: toStringOrNull(map['familyName']),
      code: toStringValue(map['code']),
      email: toStringOrNull(map['email']),
      role: FamilyRole.fromString(toStringOrNull(map['role'])),
      memberTag: toStringOrNull(map['memberTag']),
      createdBy: toStringValue(map['createdBy']),
      createdByName: toStringOrNull(map['createdByName']),
      createdAt: toLongOrNull(map['createdAt']),
      expiresAt: toLongValue(map['expiresAt']),
      status: toStringValue(map['status']).isNotEmpty
          ? toStringValue(map['status'])
          : 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'familyName': familyName,
        'code': code,
        'email': email,
        'role': role.toDbString(),
        'memberTag': memberTag,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'expiresAt': expiresAt,
        'status': status,
      };
}

class DataScope {
  final String uid;
  final String? familyId;
  final FamilyRole role;

  const DataScope({
    required this.uid,
    this.familyId,
    this.role = FamilyRole.owner,
  });

  bool get isOwner => role == FamilyRole.owner;
  bool get isAdmin => role == FamilyRole.owner || role == FamilyRole.admin;
  bool get canWriteFinancials =>
      role == FamilyRole.owner ||
      role == FamilyRole.admin ||
      role == FamilyRole.member;
  bool get canManageMembers =>
      role == FamilyRole.owner || role == FamilyRole.admin;
  bool get canDelete =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  /// Effective scope ID: uses familyId if present, otherwise userId.
  String get scopeId => (familyId != null && familyId!.isNotEmpty) ? familyId! : uid;
  bool get isFamily => familyId != null && familyId!.isNotEmpty;
}
