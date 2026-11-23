import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_cloud_sync.dart';
import 'package:finora/core/services/bank_sync_service.dart';

class _InMemoryBankCloudAdapter extends BankNotificationCloudAdapter {
  final Map<String, Map<String, dynamic>> docs = {};
  final _controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitCurrent() {
    _controller.add(
      docs.values.map((m) => Map<String, dynamic>.from(m)).toList(),
    );
  }

  void putRemote(String id, Map<String, dynamic> data) {
    docs[id] = {'id': id, ...data};
    emitCurrent();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) =>
      _controller.stream;

  @override
  Future<List<Map<String, dynamic>>> loadNotifications(String userId) async {
    return docs.values.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  @override
  Future<void> saveNotification(
    String userId,
    String documentId,
    Map<String, dynamic> data, {
    bool replace = false,
  }) async {
    if (replace || !docs.containsKey(documentId)) {
      docs[documentId] = {'id': documentId, ...data};
    } else {
      docs[documentId] = {...docs[documentId]!, ...data, 'id': documentId};
    }
    emitCurrent();
  }

  @override
  Future<void> deleteNotification(String userId, String documentId) async {
    docs.remove(documentId);
    emitCurrent();
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.finora/bank_sync');

  group('Cross-Platform Bank Notification Cloud Sync', () {
    late _InMemoryBankCloudAdapter adapter;
    late List<String> nativeQueue;
    late List<String> ackedNativeIds;

    setUp(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      adapter = _InMemoryBankCloudAdapter();
      nativeQueue = [];
      ackedNativeIds = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'getPendingNotifications':
            return List<String>.of(nativeQueue);
          case 'getSyncStatus':
            return {'connected': true, 'lastReceivedAt': 1793300000000};
          case 'acknowledgeNotifications':
            final ids = ((call.arguments as Map)['ids'] as List)
                .map((e) => e.toString())
                .toList();
            ackedNativeIds.addAll(ids);
            nativeQueue.removeWhere((raw) {
              final m = jsonDecode(raw) as Map<String, dynamic>;
              return ids.contains(m['id']);
            });
            return true;
          default:
            return false;
        }
      });

      final service = BankSyncService();
      await service.resetCloudStateForTest();
      service.setCloudAdapterForTest(adapter);
    });

    tearDown(() async {
      await BankSyncService().resetCloudStateForTest();
      await adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test(
        'Phone bank notification syncs to cloud with balanceAfter and marks imported from android',
        () async {
      final service = BankSyncService();
      await service.bindUser('user-sync-1');

      nativeQueue.add(
        jsonEncode({
          'id': 'ncb_phone_01',
          'package': 'com.ncb.bank',
          'title': 'NCB iziMobile',
          'text':
              'So du TK 1000234567 -150,000 VND. SD kha dung: 12,450,000 VND. ND: An trua FT261001.',
          'timestamp': 1793300000000,
        }),
      );

      await service.checkPendingNotifications();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Pushed to Supabase cloud for Web to see immediately
      expect(adapter.docs.containsKey('ncb_phone_01'), isTrue);
      final pushed = adapter.docs['ncb_phone_01']!;
      expect(pushed['status'], 'pending');
      expect(pushed['sourcePlatform'], 'android');
      expect(pushed['amount'], 150000.0);
      expect(pushed['balanceAfter'], 12450000.0);

      // Now user imports it on Phone
      await service.markImported(
        'ncb_phone_01',
        transactionId: 'bank_ncb_phone_01',
        walletId: 'w-ncb',
        walletName: 'NCB Chính',
        amount: 150000,
        type: 'expense',
        categoryName: 'Ăn uống',
        syncedBalance: true,
        syncedBalanceValue: 12450000,
      );

      // Cloud doc is marked imported from android so Web shows "Đã nhập trên điện thoại"
      final updated = adapter.docs['ncb_phone_01']!;
      expect(updated['status'], 'imported');
      expect(updated['importedFrom'], 'android');
      expect(updated['importedWalletName'], 'NCB Chính');
      expect(updated['syncedBalance'], isTrue);
      expect(updated['syncedBalanceValue'], 12450000.0);

      // Local queue & native Android queue are cleared
      expect(service.pending, isEmpty);
      expect(ackedNativeIds, contains('ncb_phone_01'));
      expect(service.importedHistory, hasLength(1));
      expect(service.isAlreadyImported('ncb_phone_01'), isTrue);
    });

    test(
        'When Web imports a notification, Phone auto-acknowledges it and never re-queues it as pending',
        () async {
      final service = BankSyncService();
      await service.bindUser('user-sync-2');

      final rawEvent = jsonEncode({
        'id': 'vcb_phone_02',
        'package': 'com.VCB',
        'title': 'VCB Digibank',
        'text':
            'SD TK 0071000123456 -250,000 VND. SD: 9,750,000 VND. ND: Mua sam.',
        'timestamp': 1793300010000,
      });
      nativeQueue.add(rawEvent);

      await service.checkPendingNotifications();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(service.pending, hasLength(1));

      // Simulate Web importing the transaction in Supabase
      adapter.putRemote('vcb_phone_02', {
        ...adapter.docs['vcb_phone_02']!,
        'status': 'imported',
        'importedFrom': 'web',
        'importedAt': 1793300050000,
        'importedWalletName': 'Vietcombank',
        'importedAmount': 250000,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Phone must automatically remove from pending & ack native queue
      expect(service.pending, isEmpty);
      expect(ackedNativeIds, contains('vcb_phone_02'));
      expect(service.importedHistory.first.importedFrom, 'web');

      // Even if native somehow replays the same JSON later, Phone must NOT overwrite cloud back to pending
      nativeQueue.add(rawEvent);
      await service.checkPendingNotifications();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(service.pending, isEmpty);
      expect(adapter.docs['vcb_phone_02']!['status'], 'imported');
    });

    test(
        'Web-created pending balance notification syncs down to Phone inbox and manual Phone entry pushes to cloud',
        () async {
      final service = BankSyncService();
      await service.bindUser('user-sync-3');

      // Web pastes/enters a bank balance notification and saves it to pending queue
      adapter.putRemote('web_1793300099999_abc123', {
        'userId': 'user-sync-3',
        'status': 'pending',
        'sourcePlatform': 'web',
        'bankCode': 'mbbank',
        'bankName': 'MB Bank',
        'accountNumber': '1000666',
        'type': 'income',
        'amount': 5000000,
        'balanceAfter': 25000000,
        'note': 'Nhan luong thang 11',
        'rawText': '+5,000,000 VND SD: 25,000,000 VND',
        'transactionCode': 'FT2699999',
        'timestamp': 1793300099999,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.pending, hasLength(1));
      final syncedFromWeb = service.pending.first;
      expect(syncedFromWeb.rawId, 'web_1793300099999_abc123');
      expect(syncedFromWeb.amount, 5000000);
      expect(syncedFromWeb.balanceAfter, 25000000);
      expect(service.isFromWeb(syncedFromWeb.rawId), isTrue);

      // Phone user manually enters a balance fluctuation
      final manual = service.injectManualNotification(
        title: 'Techcombank',
        text: 'Techcombank -80.000đ',
        manualAmount: 80000,
        manualType: 'expense',
        manualBalanceAfter: 4920000,
        bankCode: 'techcombank',
        bankName: 'Techcombank',
        manualNote: 'Ca phe sang',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.docs.containsKey(manual.rawId), isTrue);
      expect(adapter.docs[manual.rawId]!['balanceAfter'], 4920000.0);
      expect(adapter.docs[manual.rawId]!['status'], 'pending');
    });
  });
}
