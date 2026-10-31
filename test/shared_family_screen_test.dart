import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/data/services/family_sharing_service.dart';
import 'package:finora/features/family/shared_family_screen.dart';
import 'package:finora/state/theme_studio_controller.dart';

class _FamilyService extends FamilySharingService {
  final calls = <String>[];
  bool joined = false;
  bool revoked = false;
  bool unknownBalance = false;
  @override
  Future<Map<String, dynamic>> request(String action,
      [Map<String, dynamic> args = const {}]) async {
    calls.add(action);
    if (action == 'accept') {
      expect(args['invitationId'], 'inv');
      joined = true;
    }
    if (action == 'ledger') {
      if (revoked) throw StateError('FAMILY_NOT_JOINED');
      return {
        'transactions': [
          {
            'key': 'husband-t1',
            'ownerUid': 'husband',
            'id': 't1',
            'amount': 25000,
            'type': 'expense',
            'date': '2026-10-31',
            'note': 'Ăn sáng chung'
          }
        ],
        'nextAfter': null
      };
    }
    return {
      'family': joined
          ? {'id': 'family', 'name': 'Nhà mình', 'ownerUid': 'husband'}
          : null,
      'members': joined
          ? [
              {'uid': 'wife', 'email': 'wife@example.com', 'isOwner': false}
            ]
          : [],
      'invitations': joined
          ? []
          : [
              {
                'id': 'inv',
                'familyName': 'Nhà mình',
                'email': 'wife@example.com',
                'incoming': true,
                'expiresAt': '2026-11-07'
              }
            ],
      'myWallets': [],
      'sharedWallets': joined
          ? [
              {
                'key': 'husband-wallet',
                'ownerUid': 'husband',
                'name': 'Ví chung',
                'balance': unknownBalance ? null : 500000
              }
            ]
          : [],
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'accepts email invite without importing ledger and clears access on logout',
      (tester) async {
    final service = _FamilyService();
    final identities = StreamController<String?>();
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ThemeStudioController(),
        child: MaterialApp(
            home: SharedFamilyScreen(
                service: service, userIds: identities.stream))));
    identities.add('wife');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Lời mời vào Nhà mình'), findsOneWidget);
    expect(find.textContaining('FINORA-SYNC'), findsNothing);
    await tester.tap(find.text('Tham gia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(service.calls, ['state', 'accept', 'ledger']);
    expect(find.text('Lời mời vào Nhà mình'), findsNothing);
    identities.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Đăng nhập để quản lý gia đình.'), findsOneWidget);
    expect(find.textContaining('Nhà mình'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    unawaited(identities.close());
  });
  testWidgets('revocation error clears shared balances at next refresh',
      (tester) async {
    final service = _FamilyService()..joined = true;
    final identities = StreamController<String?>();
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ThemeStudioController(),
        child: MaterialApp(
            home: SharedFamilyScreen(
                service: service, userIds: identities.stream))));
    identities.add('wife');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Nhà mình · 1/10 người'), findsOneWidget);
    service.revoked = true;
    await tester.tap(find.byTooltip('Làm mới'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.textContaining('quyền đã bị thu hồi'), findsOneWidget);
    expect(find.text('Nhà mình · 1/10 người'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    unawaited(identities.close());
  });
  testWidgets('unknown balance is labeled rather than shown as zero',
      (tester) async {
    final service = _FamilyService()
      ..joined = true
      ..unknownBalance = true;
    final identities = StreamController<String?>();
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ThemeStudioController(),
        child: MaterialApp(
            home: SharedFamilyScreen(
                service: service, userIds: identities.stream))));
    identities.add('wife');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.scrollUntilVisible(
        find.textContaining('Chưa đối soát số dư'), 200);
    expect(find.textContaining('Chưa đối soát số dư'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(identities.close());
  });
}
