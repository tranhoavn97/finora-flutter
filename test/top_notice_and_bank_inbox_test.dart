import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/core/services/bank_sync_service.dart';
import 'package:finora/core/widgets/finora_notice.dart';
import 'package:finora/core/widgets/finora_notification_bell.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'local_assistant_test.dart' show LocalTestLedger;

class _LoadingActivity extends MoreProvider {
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'notice stays at top with keyboard, replaces duplicates and keeps undo',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var undos = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => Column(children: [
                      TextButton(
                          onPressed: () => FinoraNotice.of(context)
                              .showSnackBar(SnackBar(
                                  content: const Text('Đã lưu kiểm thử'),
                                  action: SnackBarAction(
                                      label: 'Hoàn tác',
                                      onPressed: () => undos++))),
                          child: const Text('Show')),
                      TextButton(
                          onPressed: () {
                            FinoraNotice.of(context).showSnackBar(
                                const SnackBar(content: Text('Old')));
                            FinoraNotice.of(context).showSnackBar(
                                const SnackBar(content: Text('New')));
                          },
                          child: const Text('Replace')),
                      const TextField(),
                    ])))));
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('finora-top-notice'))).dy,
        lessThan(100));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('finora-top-notice'))).dy,
        lessThan(100));
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pump();
    expect(undos, 1);
    await tester.tap(find.text('Replace'));
    await tester.pump();
    expect(find.text('Old'), findsNothing);
    expect(find.text('New'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng thông báo'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'bell opens durable bank inbox while remote notifications are loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final queue = [
      jsonEncode({
        'id': 'inbox-real-test',
        'package': 'com.VCB',
        'title': 'VCB Digibank',
        'text': 'SD TK 0071000123456 -50,000 VND. ND: Com trua.',
        'timestamp': DateTime(2026, 10, 30, 10).millisecondsSinceEpoch
      })
    ];
    var launch = true, opens = 0;
    const channel = MethodChannel('com.finora/bank_sync');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getPendingNotifications':
          return queue;
        case 'getSyncStatus':
          return {'connected': true};
        case 'isPermissionGranted':
          return true;
        case 'consumeBankInboxRequest':
          final value = launch;
          launch = false;
          return value;
        case 'acknowledgeNotifications':
          queue.clear();
          return true;
      }
      return null;
    });
    final bank = BankSyncService();
    final sub = bank.onInboxRequested.listen((_) => opens++);
    await tester.runAsync(bank.initialize);
    await tester.pump();
    expect(opens, 1);
    await tester.runAsync(bank.initialize);
    await tester.pump();
    expect(opens, 1);
    final more = _LoadingActivity(), ledger = LocalTestLedger();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<MoreProvider>.value(value: more),
          ChangeNotifierProvider<TransactionProvider>.value(value: ledger)
        ],
        child: const MaterialApp(
            home:
                Scaffold(body: FinoraNotificationBell(userId: 'inbox-user')))));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Giao dịch chờ (1)'), findsOneWidget);
    expect(find.text('Kiểm tra & ghi vào sổ'), findsOneWidget);
    expect(more.isRefreshing, isTrue);
    // Opening the inbox must not consume the native event or write the ledger.
    expect(bank.pending, hasLength(1));
    expect(ledger.writes, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() => bank.acknowledge('inbox-real-test'));
    expect(bank.pending, isEmpty);
    await tester.runAsync(sub.cancel);
    await tester.runAsync(() async {
      more.dispose();
      ledger.dispose();
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
