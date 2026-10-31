import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/family_models.dart';
import '../data/services/supabase_bridge.dart';

class FamilySyncReport {
  final int walletsAdded;
  final int transactionsAdded;
  final int categoriesAdded;
  final int assetsAdded;
  final int loansAdded;
  final int totalSkippedDuplicates;
  final String summary;

  const FamilySyncReport({
    this.walletsAdded = 0,
    this.transactionsAdded = 0,
    this.categoriesAdded = 0,
    this.assetsAdded = 0,
    this.loansAdded = 0,
    this.totalSkippedDuplicates = 0,
    required this.summary,
  });
}

class FamilyPermissionConfig {
  final bool allowMemberCreateTx;
  final bool allowMemberEditTx;
  final bool allowMemberDeleteTx;
  final bool allowMemberManageWallets;
  final bool autoTagSpouseTransactions;
  final bool zeroLossMergeProtection;
  final bool shareWallets;
  final bool shareTransactions;
  final bool shareBudgetsGoals;
  final bool shareAssetsLoans;

  const FamilyPermissionConfig({
    this.allowMemberCreateTx = true,
    this.allowMemberEditTx = true,
    this.allowMemberDeleteTx = false,
    this.allowMemberManageWallets = true,
    this.autoTagSpouseTransactions = true,
    this.zeroLossMergeProtection = true,
    this.shareWallets = true,
    this.shareTransactions = true,
    this.shareBudgetsGoals = true,
    this.shareAssetsLoans = true,
  });

  FamilyPermissionConfig copyWith({
    bool? allowMemberCreateTx,
    bool? allowMemberEditTx,
    bool? allowMemberDeleteTx,
    bool? allowMemberManageWallets,
    bool? autoTagSpouseTransactions,
    bool? zeroLossMergeProtection,
    bool? shareWallets,
    bool? shareTransactions,
    bool? shareBudgetsGoals,
    bool? shareAssetsLoans,
  }) {
    return FamilyPermissionConfig(
      allowMemberCreateTx: allowMemberCreateTx ?? this.allowMemberCreateTx,
      allowMemberEditTx: allowMemberEditTx ?? this.allowMemberEditTx,
      allowMemberDeleteTx: allowMemberDeleteTx ?? this.allowMemberDeleteTx,
      allowMemberManageWallets:
          allowMemberManageWallets ?? this.allowMemberManageWallets,
      autoTagSpouseTransactions:
          autoTagSpouseTransactions ?? this.autoTagSpouseTransactions,
      zeroLossMergeProtection:
          zeroLossMergeProtection ?? this.zeroLossMergeProtection,
      shareWallets: shareWallets ?? this.shareWallets,
      shareTransactions: shareTransactions ?? this.shareTransactions,
      shareBudgetsGoals: shareBudgetsGoals ?? this.shareBudgetsGoals,
      shareAssetsLoans: shareAssetsLoans ?? this.shareAssetsLoans,
    );
  }

  Map<String, dynamic> toMap() => {
        'allowMemberCreateTx': allowMemberCreateTx,
        'allowMemberEditTx': allowMemberEditTx,
        'allowMemberDeleteTx': allowMemberDeleteTx,
        'allowMemberManageWallets': allowMemberManageWallets,
        'autoTagSpouseTransactions': autoTagSpouseTransactions,
        'zeroLossMergeProtection': zeroLossMergeProtection,
        'shareWallets': shareWallets,
        'shareTransactions': shareTransactions,
        'shareBudgetsGoals': shareBudgetsGoals,
        'shareAssetsLoans': shareAssetsLoans,
      };

  factory FamilyPermissionConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FamilyPermissionConfig();
    return FamilyPermissionConfig(
      allowMemberCreateTx: map['allowMemberCreateTx'] != false,
      allowMemberEditTx: map['allowMemberEditTx'] != false,
      allowMemberDeleteTx: map['allowMemberDeleteTx'] == true,
      allowMemberManageWallets: map['allowMemberManageWallets'] != false,
      autoTagSpouseTransactions: map['autoTagSpouseTransactions'] != false,
      zeroLossMergeProtection: true,
      shareWallets: map['shareWallets'] != false,
      shareTransactions: map['shareTransactions'] != false,
      shareBudgetsGoals: map['shareBudgetsGoals'] != false,
      shareAssetsLoans: map['shareAssetsLoans'] != false,
    );
  }
}

class FamilyProvider extends ChangeNotifier {
  bool isLoading = true;
  String? error;

  FamilyModel? family;
  List<FamilyMemberModel> members = [];
  List<FamilyInvitationModel> invitations = [];
  FamilyPermissionConfig permissionConfig = const FamilyPermissionConfig();
  DataScope? scope;

  String? _familyId;
  String? _uid;
  int? lastSyncedAt;

  StreamSubscription? _familySub;
  StreamSubscription? _membersSub;

  /// Personal repositories stay in their existing scope. Email sharing reads
  /// explicit wallet grants separately through the server RPC; it never merges.
  String? get familyId => null;
  String? get activeFamilyGroupId => _familyId;
  String? get currentUid => _uid;
  bool get isOwner => scope?.isOwner ?? true;
  bool get isAdmin => scope?.isAdmin ?? true;
  bool get canWriteFinancials => scope?.canWriteFinancials ?? true;

  FamilyMemberModel? get currentMember {
    if (_uid == null || members.isEmpty) return null;
    for (final m in members) {
      if (m.uid == _uid) return m;
    }
    return members.first;
  }

  String get defaultMemberTag {
    final mTag = currentMember?.memberTag;
    if (mTag != null && mTag.isNotEmpty) return mTag;
    return isOwner ? 'Chồng' : 'Vợ';
  }

  String _prefsKey(String uid) => 'finora_family_state_v2_$uid';

  Future<void> init(User? user) async {
    _cancelSubs();
    _uid = user?.uid;
    isLoading = true;
    error = null;
    notifyListeners();

    if (user == null) {
      _familyId = null;
      family = null;
      members = [];
      invitations = [];
      scope = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawLocal = prefs.getString(_prefsKey(user.uid));
      Map<String, dynamic>? loadedMap;

      if (rawLocal != null && rawLocal.isNotEmpty) {
        try {
          loadedMap = Map<String, dynamic>.from(jsonDecode(rawLocal) as Map);
        } catch (_) {}
      }

      // Also check cloud mirror if local is empty
      if (loadedMap == null) {
        try {
          final cloudDocs = await SupabaseBridge.loadUserCollection(
            userId: user.uid,
            collection: 'family_workspace',
          );
          if (cloudDocs.isNotEmpty) {
            loadedMap = cloudDocs.first;
          }
        } catch (_) {}
      }

      if (loadedMap != null) {
        _applyLoadedState(user, loadedMap);
      } else {
        _createDefaultFamilyForUser(user);
        await _persistState();
      }
    } catch (_) {
      _createDefaultFamilyForUser(user);
    }

    isLoading = false;
    error = null;
    notifyListeners();
  }

  void _createDefaultFamilyForUser(User user) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final displayName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'Chủ hộ');
    final famId = 'fam_${user.uid.substring(0, min(8, user.uid.length))}';
    _familyId = famId;
    family = FamilyModel(
      id: famId,
      name: 'Gia đình $displayName',
      ownerId: user.uid,
      memberUids: [user.uid],
      memberCount: 1,
      createdAt: now,
      updatedAt: now,
    );
    members = [
      FamilyMemberModel(
        uid: user.uid,
        displayName: displayName,
        email: user.email ?? '',
        photoURL: user.photoURL,
        role: FamilyRole.owner,
        memberTag: 'Chồng',
        joinedAt: now,
      ),
    ];
    invitations = [];
    permissionConfig = const FamilyPermissionConfig();
    scope = DataScope(uid: user.uid, familyId: null, role: FamilyRole.owner);
  }

  void _applyLoadedState(User user, Map<String, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final famId = (map['familyId'] ?? 'fam_${user.uid.substring(0, min(8, user.uid.length))}').toString();
    _familyId = famId;

    final rawMembers = map['members'];
    final parsedMembers = <FamilyMemberModel>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          final mMap = Map<String, dynamic>.from(item);
          final mUid = (mMap['uid'] ?? '').toString();
          if (mUid.isNotEmpty) {
            parsedMembers.add(FamilyMemberModel.fromMap(mUid, mMap));
          }
        }
      }
    }

    if (!parsedMembers.any((m) => m.uid == user.uid)) {
      final displayName = (user.displayName ?? '').trim().isNotEmpty
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Chủ hộ');
      parsedMembers.insert(
        0,
        FamilyMemberModel(
          uid: user.uid,
          displayName: displayName,
          email: user.email ?? '',
          photoURL: user.photoURL,
          role: FamilyRole.owner,
          memberTag: 'Chồng',
          joinedAt: now,
        ),
      );
    }

    members = parsedMembers;

    final rawInvites = map['invitations'];
    final parsedInvites = <FamilyInvitationModel>[];
    if (rawInvites is List) {
      for (final item in rawInvites) {
        if (item is Map) {
          final iMap = Map<String, dynamic>.from(item);
          final id = (iMap['id'] ?? iMap['code'] ?? '').toString();
          if (id.isNotEmpty) {
            parsedInvites.add(FamilyInvitationModel.fromMap(id, iMap));
          }
        }
      }
    }
    invitations = parsedInvites;

    if (map['permissionConfig'] is Map) {
      permissionConfig = FamilyPermissionConfig.fromMap(
        Map<String, dynamic>.from(map['permissionConfig'] as Map),
      );
    }

    lastSyncedAt = map['lastSyncedAt'] is int ? map['lastSyncedAt'] as int : null;

    final myMember = members.firstWhere(
      (m) => m.uid == user.uid,
      orElse: () => members.first,
    );

    family = FamilyModel(
      id: famId,
      name: (map['familyName'] ?? 'Gia đình của bạn').toString(),
      ownerId: (map['ownerId'] ?? user.uid).toString(),
      memberUids: members.map((m) => m.uid).toList(),
      memberCount: members.length,
      createdAt: map['createdAt'] is int ? map['createdAt'] as int : now,
      updatedAt: now,
    );

    scope = DataScope(
      uid: user.uid,
      familyId: null,
      role: myMember.role,
    );
  }

  Future<void> _persistState() async {
    final uid = _uid;
    if (uid == null || family == null) return;
    final payload = <String, dynamic>{
      'familyId': family!.id,
      'familyName': family!.name,
      'ownerId': family!.ownerId,
      'createdAt': family!.createdAt,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'lastSyncedAt': lastSyncedAt,
      'permissionConfig': permissionConfig.toMap(),
      'members': members
          .map((m) => {
                'uid': m.uid,
                ...m.toMap(),
                'joinedAt': m.joinedAt,
              })
          .toList(),
      'invitations': invitations
          .map((i) => {
                'id': i.id,
                ...i.toMap(),
                'createdAt': i.createdAt,
              })
          .toList(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(uid), jsonEncode(payload));
    } catch (_) {}

    // Mirror asynchronously to Supabase so Web & Mobile stay in sync
    unawaited(
      SupabaseBridge.saveUserDocument(
        userId: uid,
        collection: 'family_workspace',
        documentId: 'current_family',
        data: payload,
      ).catchError((_) {}),
    );
  }

  Future<void> updateFamilyName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || family == null) return;
    family = FamilyModel(
      id: family!.id,
      name: trimmed,
      ownerId: family!.ownerId,
      memberUids: family!.memberUids,
      memberCount: members.length,
      createdAt: family!.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _persistState();
    notifyListeners();
  }

  Future<void> updatePermissionConfig(FamilyPermissionConfig newConfig) async {
    permissionConfig = newConfig;
    await _persistState();
    notifyListeners();
  }

  Future<FamilyInvitationModel?> createInvitation({
    FamilyRole role = FamilyRole.member,
    String? targetEmail,
    String? memberTag,
  }) async {
    error = 'Hãy tạo lời mời theo email tại mục Gia đình. Mã mời cục bộ đã ngừng hỗ trợ.';
    notifyListeners();
    return null;
  }

  /// Directly add a family member (e.g., Vợ / Chồng / Con) with specific role & tag
  Future<void> addOrUpdateManualMember({
    required String displayName,
    String? email,
    required FamilyRole role,
    required String memberTag,
  }) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final memberUid = email != null && email.trim().isNotEmpty
        ? 'mem_${email.trim().toLowerCase().hashCode.abs()}'
        : 'mem_$now';

    final existingIdx = members.indexWhere(
      (m) =>
          m.uid == memberUid ||
          (email != null &&
              email.trim().isNotEmpty &&
              m.email.toLowerCase() == email.trim().toLowerCase()),
    );

    final newMember = FamilyMemberModel(
      uid: memberUid,
      displayName: cleanName,
      email: email?.trim() ?? '',
      role: role,
      memberTag: memberTag,
      joinedAt: now,
    );

    if (existingIdx >= 0) {
      members[existingIdx] = newMember;
    } else {
      members = [...members, newMember];
    }

    if (family != null) {
      family = FamilyModel(
        id: family!.id,
        name: family!.name,
        ownerId: family!.ownerId,
        memberUids: members.map((m) => m.uid).toList(),
        memberCount: members.length,
        createdAt: family!.createdAt,
        updatedAt: now,
      );
    }
    await _persistState();
    notifyListeners();
  }

  Future<Map<String, dynamic>> acceptInvitation(String rawInput, User user) async {
    return {
      'success': false,
      'message': 'Mã mời và gói FINORA-SYNC cũ đã ngừng hỗ trợ. Hãy nhận lời mời theo email tại mục Gia đình; sổ riêng không bị gộp.',
    };
  }

  Future<void> changeRole(String memberUid, FamilyRole role) async {
    final idx = members.indexWhere((m) => m.uid == memberUid);
    if (idx < 0) return;
    final current = members[idx];
    members[idx] = FamilyMemberModel(
      uid: current.uid,
      displayName: current.displayName,
      email: current.email,
      photoURL: current.photoURL,
      role: role,
      memberTag: current.memberTag,
      joinedAt: current.joinedAt,
      status: current.status,
    );
    if (memberUid == _uid) {
      scope = DataScope(uid: _uid!, familyId: null, role: role);
    }
    await _persistState();
    notifyListeners();
  }

  Future<void> changeMemberTag(String memberUid, String tag) async {
    final idx = members.indexWhere((m) => m.uid == memberUid);
    if (idx < 0) return;
    final current = members[idx];
    members[idx] = FamilyMemberModel(
      uid: current.uid,
      displayName: current.displayName,
      email: current.email,
      photoURL: current.photoURL,
      role: current.role,
      memberTag: tag,
      joinedAt: current.joinedAt,
      status: current.status,
    );
    await _persistState();
    notifyListeners();
  }

  Future<void> removeMember(String memberUid) async {
    if (memberUid == _uid) return;
    members = members.where((m) => m.uid != memberUid).toList();
    if (family != null) {
      family = FamilyModel(
        id: family!.id,
        name: family!.name,
        ownerId: family!.ownerId,
        memberUids: members.map((m) => m.uid).toList(),
        memberCount: members.length,
        createdAt: family!.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    await _persistState();
    notifyListeners();
  }

  Future<void> leaveGroup(User user) async {
    _createDefaultFamilyForUser(user);
    await _persistState();
    notifyListeners();
  }

  /// Export a complete Zero-Data-Loss Portable Family Sync Package (`FINORA-SYNC:...`)
  /// Works identically on Web and Mobile so Husband & Wife can share via Zalo/Messenger/Clipboard
  /// and merge 100% of wallets, transactions, categories, assets & loans without losing any item.
  Future<String> exportFamilySharePackage(String userId) async {
    final wallets = await SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: 'wallets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final transactions = await SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: 'transactions',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final categories = await SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: 'categories',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final assets = await SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: 'assets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final loans = await SupabaseBridge.loadUserCollection(
      userId: userId,
      collection: 'loans',
    ).catchError((_) => <Map<String, dynamic>>[]);

    final senderTag = defaultMemberTag;
    final packageMap = <String, dynamic>{
      'version': 2,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'senderUid': userId,
      'senderName': currentMember?.displayName ?? 'Thành viên',
      'senderEmail': currentMember?.email ?? '',
      'senderTag': senderTag,
      'familyId': family?.id ?? 'fam_$userId',
      'familyName': family?.name ?? 'Gia đình Finora',
      'permissionConfig': permissionConfig.toMap(),
      'members': members
          .map((m) => {
                'uid': m.uid,
                ...m.toMap(),
                'joinedAt': m.joinedAt,
              })
          .toList(),
      'wallets': wallets.where((w) => w['deletedAt'] == null).toList(),
      'transactions':
          transactions.where((t) => t['deletedAt'] == null).toList(),
      'categories': categories.where((c) => c['deletedAt'] == null).toList(),
      'assets': assets.where((a) => a['deletedAt'] == null).toList(),
      'loans': loans.where((l) => l['deletedAt'] == null).toList(),
    };

    final jsonStr = jsonEncode(packageMap);
    final encoded = base64UrlEncode(utf8.encode(jsonStr));
    return 'FINORA-SYNC:$encoded';
  }

  /// Legacy package imports are disabled. Use server-verified wallet sharing.
  Future<FamilySyncReport> importAndMergeFamilyPackage({
    required String userId,
    required String rawPackage,
  }) async {
    throw StateError('Nhập gói đồng bộ cũ đã ngừng hỗ trợ để tránh gộp nhầm dữ liệu. Hãy dùng chia sẻ ví theo email.');
  }

  // Retained for reviewing historical imports; never invoked by email sharing.
  // ignore: unused_element
  Future<FamilySyncReport> _mergeFromAnotherLocalUser({
    required String sourceUid,
    required String targetUid,
  }) async {
    final wallets = await SupabaseBridge.loadUserCollection(
      userId: sourceUid,
      collection: 'wallets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final txs = await SupabaseBridge.loadUserCollection(
      userId: sourceUid,
      collection: 'transactions',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final cats = await SupabaseBridge.loadUserCollection(
      userId: sourceUid,
      collection: 'categories',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final assets = await SupabaseBridge.loadUserCollection(
      userId: sourceUid,
      collection: 'assets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final loans = await SupabaseBridge.loadUserCollection(
      userId: sourceUid,
      collection: 'loans',
    ).catchError((_) => <Map<String, dynamic>>[]);

    return _mergeCollectionsZeroLoss(
      targetUid: targetUid,
      incomingWallets: wallets,
      incomingTransactions: txs,
      incomingCategories: cats,
      incomingAssets: assets,
      incomingLoans: loans,
      defaultOwnerTag: 'Chồng',
    );
  }

  Future<FamilySyncReport> _mergeCollectionsZeroLoss({
    required String targetUid,
    required List<Map<String, dynamic>> incomingWallets,
    required List<Map<String, dynamic>> incomingTransactions,
    required List<Map<String, dynamic>> incomingCategories,
    required List<Map<String, dynamic>> incomingAssets,
    required List<Map<String, dynamic>> incomingLoans,
    required String defaultOwnerTag,
  }) async {
    final existingWallets = await SupabaseBridge.loadUserCollection(
      userId: targetUid,
      collection: 'wallets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final existingTxs = await SupabaseBridge.loadUserCollection(
      userId: targetUid,
      collection: 'transactions',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final existingCats = await SupabaseBridge.loadUserCollection(
      userId: targetUid,
      collection: 'categories',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final existingAssets = await SupabaseBridge.loadUserCollection(
      userId: targetUid,
      collection: 'assets',
    ).catchError((_) => <Map<String, dynamic>>[]);
    final existingLoans = await SupabaseBridge.loadUserCollection(
      userId: targetUid,
      collection: 'loans',
    ).catchError((_) => <Map<String, dynamic>>[]);

    int walletsAdded = 0;
    int txsAdded = 0;
    int catsAdded = 0;
    int assetsAdded = 0;
    int loansAdded = 0;
    int skipped = 0;

    // Map from incoming walletId -> resolved target walletId
    final walletIdMap = <String, String>{};
    final existingWalletById = {
      for (final w in existingWallets) (w['id'] ?? '').toString(): w
    };

    String walletKey(Map<String, dynamic> w) {
      final name = (w['name'] ?? '').toString().trim().toLowerCase();
      final owner = (w['owner'] ?? defaultOwnerTag).toString().trim().toLowerCase();
      return '$name|$owner';
    }

    final existingWalletBySignature = {
      for (final w in existingWallets) walletKey(w): (w['id'] ?? '').toString()
    };

    // 1. Merge Wallets non-destructively
    for (final w in incomingWallets) {
      if (w['deletedAt'] != null) continue;
      final incomingId = (w['id'] ?? SupabaseBridge.newDocumentId()).toString();
      final sig = walletKey(w);

      if (existingWalletById.containsKey(incomingId)) {
        walletIdMap[incomingId] = incomingId;
        skipped++;
        continue;
      }
      if (existingWalletBySignature.containsKey(sig)) {
        walletIdMap[incomingId] = existingWalletBySignature[sig]!;
        skipped++;
        continue;
      }

      final cloned = Map<String, dynamic>.from(w);
      cloned['id'] = incomingId;
      cloned['userId'] = targetUid;
      if ((cloned['owner'] ?? '').toString().trim().isEmpty) {
        cloned['owner'] = defaultOwnerTag == 'Vợ' ? 'wife' : 'husband';
      }
      if ((cloned['ownerName'] ?? '').toString().trim().isEmpty) {
        cloned['ownerName'] = defaultOwnerTag;
      }
      await SupabaseBridge.saveUserDocument(
        userId: targetUid,
        collection: 'wallets',
        documentId: incomingId,
        data: cloned,
      );
      walletIdMap[incomingId] = incomingId;
      existingWalletById[incomingId] = cloned;
      existingWalletBySignature[sig] = incomingId;
      walletsAdded++;
    }

    // 2. Merge Categories non-destructively
    final existingCatIds = {
      for (final c in existingCats) (c['id'] ?? '').toString()
    };
    final existingCatNames = {
      for (final c in existingCats)
        (c['name'] ?? '').toString().trim().toLowerCase()
    };
    for (final c in incomingCategories) {
      if (c['deletedAt'] != null) continue;
      final cId = (c['id'] ?? SupabaseBridge.newDocumentId()).toString();
      final cName = (c['name'] ?? '').toString().trim().toLowerCase();
      if (existingCatIds.contains(cId) ||
          (cName.isNotEmpty && existingCatNames.contains(cName))) {
        skipped++;
        continue;
      }
      final cloned = Map<String, dynamic>.from(c)
        ..['id'] = cId
        ..['userId'] = targetUid;
      await SupabaseBridge.saveUserDocument(
        userId: targetUid,
        collection: 'categories',
        documentId: cId,
        data: cloned,
      );
      existingCatIds.add(cId);
      if (cName.isNotEmpty) existingCatNames.add(cName);
      catsAdded++;
    }

    // 3. Merge Transactions non-destructively with fingerprint deduplication
    String txFingerprint(Map<String, dynamic> t) {
      final amt = (t['amount'] ?? 0).toString();
      final dt = (t['date'] ?? 0).toString();
      final tp = (t['type'] ?? '').toString().trim().toLowerCase();
      final note = (t['note'] ?? '').toString().trim().toLowerCase();
      final bCode = (t['bankTransactionCode'] ?? '').toString().trim().toLowerCase();
      return '$amt|$dt|$tp|$note|$bCode';
    }

    final existingTxIds = {
      for (final t in existingTxs) (t['id'] ?? '').toString()
    };
    final existingTxFingerprints = {
      for (final t in existingTxs) txFingerprint(t)
    };

    for (final t in incomingTransactions) {
      if (t['deletedAt'] != null) continue;
      final tId = (t['id'] ?? SupabaseBridge.newDocumentId()).toString();
      final fp = txFingerprint(t);

      if (existingTxIds.contains(tId) || existingTxFingerprints.contains(fp)) {
        skipped++;
        continue;
      }

      final cloned = Map<String, dynamic>.from(t);
      cloned['id'] = tId;
      cloned['userId'] = targetUid;
      final origWalletId = (cloned['walletId'] ?? '').toString();
      if (origWalletId.isNotEmpty && walletIdMap.containsKey(origWalletId)) {
        cloned['walletId'] = walletIdMap[origWalletId];
      }
      if ((cloned['owner'] ?? '').toString().trim().isEmpty &&
          (cloned['creatorTag'] ?? '').toString().trim().isEmpty) {
        cloned['owner'] = defaultOwnerTag;
        cloned['creatorTag'] = defaultOwnerTag;
      }

      await SupabaseBridge.saveUserDocument(
        userId: targetUid,
        collection: 'transactions',
        documentId: tId,
        data: cloned,
      );
      existingTxIds.add(tId);
      existingTxFingerprints.add(fp);
      txsAdded++;
    }

    // 4. Merge Assets non-destructively
    final existingAssetIds = {
      for (final a in existingAssets) (a['id'] ?? '').toString()
    };
    for (final a in incomingAssets) {
      if (a['deletedAt'] != null) continue;
      final aId = (a['id'] ?? SupabaseBridge.newDocumentId()).toString();
      if (existingAssetIds.contains(aId)) {
        skipped++;
        continue;
      }
      final cloned = Map<String, dynamic>.from(a)
        ..['id'] = aId
        ..['userId'] = targetUid;
      await SupabaseBridge.saveUserDocument(
        userId: targetUid,
        collection: 'assets',
        documentId: aId,
        data: cloned,
      );
      existingAssetIds.add(aId);
      assetsAdded++;
    }

    // 5. Merge Loans non-destructively
    final existingLoanIds = {
      for (final l in existingLoans) (l['id'] ?? '').toString()
    };
    for (final l in incomingLoans) {
      if (l['deletedAt'] != null) continue;
      final lId = (l['id'] ?? SupabaseBridge.newDocumentId()).toString();
      if (existingLoanIds.contains(lId)) {
        skipped++;
        continue;
      }
      final cloned = Map<String, dynamic>.from(l)
        ..['id'] = lId
        ..['userId'] = targetUid;
      await SupabaseBridge.saveUserDocument(
        userId: targetUid,
        collection: 'loans',
        documentId: lId,
        data: cloned,
      );
      existingLoanIds.add(lId);
      loansAdded++;
    }

    final totalAdded =
        walletsAdded + txsAdded + catsAdded + assetsAdded + loansAdded;
    final summary = totalAdded > 0
        ? 'Đồng bộ 100% an toàn: +$txsAdded giao dịch, +$walletsAdded ví, +$catsAdded danh mục (bỏ qua $skipped mục trùng, 0 mất dữ liệu).'
        : 'Sổ gia đình đã đồng bộ 100% mới nhất (không có giao dịch trùng lặp, 0 mất dữ liệu).';

    return FamilySyncReport(
      walletsAdded: walletsAdded,
      transactionsAdded: txsAdded,
      categoriesAdded: catsAdded,
      assetsAdded: assetsAdded,
      loansAdded: loansAdded,
      totalSkippedDuplicates: skipped,
      summary: summary,
    );
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
