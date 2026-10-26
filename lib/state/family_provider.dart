import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../data/models/family_models.dart';

class FamilyProvider extends ChangeNotifier {
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

  Future<void> init(User? user) async {
    _cancelSubs();
    _uid = user?.uid ?? 'guest_hoa_tran';
    // Financial data is personal-scope Supabase data. Do not auto-create a
    // Firestore family or migrate/merge a second copy on every login.
    _familyId = null;
    family = null;
    members = [];
    scope = DataScope(uid: _uid!, familyId: null, role: FamilyRole.owner);
    isLoading = false;
    error = null;
    notifyListeners();
  }

  Future<FamilyInvitationModel?> createInvitation({
    FamilyRole role = FamilyRole.member,
    String? targetEmail,
  }) async {
    error = 'Tính năng gia đình đang tạm tắt trong chế độ Supabase cá nhân.';
    notifyListeners();
    return null;
  }

  Future<Map<String, dynamic>> acceptInvitation(String code, User user) async {
    return {'success': false, 'message': 'Tính năng gia đình đang tạm tắt trong chế độ Supabase cá nhân.'};
  }

  Future<void> changeRole(String memberUid, FamilyRole role) async {
    return;
  }

  Future<void> changeMemberTag(String memberUid, String tag) async {
    return;
  }

  Future<void> removeMember(String memberUid) async {
    return;
  }

  Future<void> leaveGroup(User user) async {
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
