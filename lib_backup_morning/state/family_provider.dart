import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../data/models/family_models.dart';
import '../data/services/family_repository.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyRepository _repo = FamilyRepository();

  bool isLoading = true;
  String? error;

  FamilyModel? family;
  List<FamilyMemberModel> members = [];
  DataScope? scope;

  String? _familyId;
  String? _uid;

  StreamSubscription? _familySub;
  StreamSubscription? _membersSub;

  String? get familyId => _familyId;
  String? get currentUid => _uid;
  bool get isOwner => scope?.isOwner ?? true;
  bool get canWriteFinancials => scope?.canWriteFinancials ?? true;

  FamilyMemberModel? get currentMember {
    if (_uid == null || members.isEmpty) return null;
    for (final m in members) {
      if (m.uid == _uid) return m;
    }
    return null;
  }

  String get defaultMemberTag {
    final mTag = currentMember?.memberTag;
    if (mTag != null && mTag.isNotEmpty) return mTag;
    return isOwner ? 'Chồng' : 'Vợ';
  }

  Future<void> init(User user) async {
    _cancelSubs();
    if (_uid != user.uid) {
      _familyId = null;
      family = null;
      members = [];
      scope = null;
    }
    _uid = user.uid;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fId = await _repo.ensureFamilyAndMigrate(user);
      _familyId = fId;

      _cancelSubs();

      _familySub = _repo.watchFamily(fId).listen((f) {
        family = f;
        _updateScope();
        notifyListeners();
      }, onError: (e) {
        error = e.toString();
        notifyListeners();
      });

      _membersSub = _repo.watchMembers(fId).listen((m) {
        members = m;
        _updateScope();
        notifyListeners();
      }, onError: (e) {
        error = e.toString();
        notifyListeners();
      });

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void _updateScope() {
    if (_uid == null) return;
    FamilyRole role = FamilyRole.member;
    if (family != null && family!.ownerId == _uid) {
      role = FamilyRole.owner;
    } else {
      final myMember = members.where((m) => m.uid == _uid).firstOrNull;
      if (myMember != null) {
        role = myMember.role;
      }
    }

    scope = DataScope(
      uid: _uid!,
      familyId: _familyId,
      role: role,
    );
  }

  Future<FamilyInvitationModel?> createInvitation({
    FamilyRole role = FamilyRole.member,
    String? targetEmail,
  }) async {
    if (family == null || _familyId == null || _uid == null) return null;
    try {
      final invite = await _repo.createInvitation(
        _familyId!,
        family!.name,
        _uid!,
        members.where((m) => m.uid == _uid).firstOrNull?.displayName ??
            'Chủ nhóm',
        role: role,
        targetEmail: targetEmail,
      );
      return invite;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String code, User user) async {
    final res = await _repo.acceptInvitation(code, user);
    if (res['success'] == true) {
      await init(user);
    }
    return res;
  }

  Future<void> changeRole(String memberUid, FamilyRole role) async {
    if (_familyId == null) return;
    await _repo.updateMemberRole(_familyId!, memberUid, role);
  }

  Future<void> changeMemberTag(String memberUid, String tag) async {
    if (_familyId == null || (!isOwner && memberUid != _uid)) {
      throw StateError('Bạn không có quyền sửa thành viên này.');
    }
    await _repo.updateMemberTag(_familyId!, memberUid, tag);
  }

  Future<void> removeMember(String memberUid) async {
    if (_familyId == null) return;
    await _repo.removeMember(_familyId!, memberUid);
  }

  Future<void> leaveGroup(User user) async {
    if (_familyId == null) return;
    await _repo.leaveFamily(_familyId!, user.uid, isOwner);
    await init(user);
  }

  void _cancelSubs() {
    _familySub?.cancel();
    _familySub = null;
    _membersSub?.cancel();
    _membersSub = null;
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }
}
