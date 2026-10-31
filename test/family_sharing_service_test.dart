import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:finora/data/services/family_sharing_service.dart';
import 'package:finora/state/family_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _User extends Fake implements User {}

void main() {
  test('legacy local codes and package imports cannot merge data', () async {
    final provider = FamilyProvider();
    expect(
        (await provider.acceptInvitation('ABCDEF', _User()))['success'], false);
    expect(
        await provider.createInvitation(targetEmail: 'wife@example.com'), null);
    await expectLater(
        provider.importAndMergeFamilyPackage(
            userId: 'wife', rawPackage: 'FINORA-SYNC:old'),
        throwsStateError);
    expect(provider.members, isEmpty);
    provider.dispose();
  });
  test('uses server RPC and session without financial writes', () async {
    var calls = 0;
    final service = FamilySharingService(
        token: () async => 'session-token',
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/rest/v1/rpc/finora_family');
          expect(request.headers['Authorization'], 'Bearer session-token');
          expect(jsonDecode(request.body), {
            'p_action': 'accept',
            'p_args': {'invitationId': 'server-invite'}
          });
          return http.Response(
              jsonEncode({
                'family': {'id': 'family'},
                'members': [],
                'invitations': [],
                'myWallets': [],
                'sharedWallets': []
              }),
              200);
        }));
    expect(
        (await service.request(
            'accept', {'invitationId': 'server-invite'}))['family']['id'],
        'family');
    expect(calls, 1);
    service.close();
  });
  test('expired invitation never falls back to local success', () async {
    final service = FamilySharingService(
        token: () async => 'token',
        client: MockClient((_) async =>
            http.Response('{"message":"FAMILY_INVITE_EXPIRED"}', 400)));
    await expectLater(
        service.request('accept', {'invitationId': 'bad'}), throwsStateError);
    expect(FamilySharingService.errorText(StateError('FAMILY_INVITE_EXPIRED')),
        contains('hết hạn'));
    service.close();
  });
  test('explains missing migration and rejects malformed success', () async {
    expect(FamilySharingService.errorText(StateError('PGRST202')),
        contains('Máy chủ chưa'));
    final service = FamilySharingService(
        token: () async => 'token',
        client: MockClient((_) async => http.Response('null', 200)));
    await expectLater(service.request('state'), throwsStateError);
    service.close();
  });
  test('no session stops before network request', () async {
    var calls = 0;
    final service = FamilySharingService(
        token: () async =>
            throw StateError('FAMILY_EMAIL_VERIFICATION_REQUIRED'),
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }));
    await expectLater(service.request('create'), throwsStateError);
    expect(calls, 0);
    service.close();
  });
}
