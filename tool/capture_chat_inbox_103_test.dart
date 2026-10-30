import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/core/services/bank_sync_service.dart';
import 'package:finora/core/widgets/finora_notice.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/features/ai/ai_advisor_screen.dart';
import 'package:finora/features/notification/notification_screen.dart';
import 'package:finora/state/budget_provider.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import '../test/local_assistant_test.dart' show LocalTestLedger;

class _Ledger extends LocalTestLedger {
  @override
  List<TransactionModel> get transactions => [
        TransactionModel(
            id: 'qa1',
            type: 'expense',
            amount: 45000,
            note: 'Ăn trưa',
            categoryId: 'food',
            categoryName: 'Ăn uống',
            walletId: 'cash',
            walletName: 'Tiền mặt',
            date: DateTime.now().millisecondsSinceEpoch),
        TransactionModel(
            id: 'qa2',
            type: 'expense',
            amount: 30000,
            note: 'Cà phê',
            categoryId: 'food',
            categoryName: 'Ăn uống',
            walletId: 'cash',
            walletName: 'Tiền mặt',
            date: DateTime.now().millisecondsSinceEpoch),
        TransactionModel(
            id: 'qa3',
            type: 'income',
            amount: 5000000,
            note: 'Lương',
            walletId: 'cash',
            walletName: 'Tiền mặt',
            date: DateTime.now().millisecondsSinceEpoch),
      ];
}

class _Budgets extends BudgetProvider {
  _Budgets() {
    isRefreshing = false;
    final d = DateTime.now();
    budgetsWithSpent = [
      BudgetSpentData(
          Budget(
              id: 'qa',
              categoryId: 'food',
              categoryName: 'Ăn uống',
              monthKey: '${d.year}-${d.month.toString().padLeft(2, '0')}',
              limitAmount: 60000),
          75000,
          1.25)
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _Activity extends MoreProvider {
  _Activity() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(File(
                  'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b))))
        .load();
  });
  testWidgets(
      'QA actual chat, budget reply, bank inbox and top notice in both themes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> save(GlobalKey key, String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final picture = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File('artifacts/$name-103-20261030.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    for (final dark in [false, true]) {
      for (final kind in ['chat', 'budget', 'inbox']) {
        final ledger = _Ledger(), budgets = _Budgets(), more = _Activity();
        final key = GlobalKey();
        final queue = [
          jsonEncode({
            'id': 'qa-bank',
            'package': 'com.VCB',
            'title': 'VCB Digibank',
            'text': 'SD TK 0071000123456 -50,000 VND. ND: Com trua.',
            'timestamp': DateTime.now().millisecondsSinceEpoch
          })
        ];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('com.finora/bank_sync'), (call) async {
          if (call.method == 'getPendingNotifications') return queue;
          if (call.method == 'getSyncStatus') return {'connected': true};
          if (call.method == 'isPermissionGranted') return true;
          if (call.method == 'acknowledgeNotifications') {
            queue.clear();
            return true;
          }
          return false;
        });
        if (kind == 'inbox') await BankSyncService().initialize();
        await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>.value(value: ledger),
              ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
              ChangeNotifierProvider<MoreProvider>.value(value: more),
            ],
            child: RepaintBoundary(
                key: key,
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(
                        fontFamily: 'BeVietnamPro',
                        colorScheme: ColorScheme.fromSeed(
                            seedColor: const Color(0xFF00866A),
                            brightness:
                                dark ? Brightness.dark : Brightness.light)),
                    home: Column(children: [
                      Expanded(
                          child: kind == 'inbox'
                              ? const NotificationScreen(userId: 'qa-only')
                              : AiAdvisorScreen(
                                  key: ValueKey('$kind-$dark'),
                                  userId: 'qa-only')),
                      const Material(
                          child: SizedBox(
                              height: 22,
                              child: Center(
                                  child: Text('Dữ liệu kiểm thử giao diện',
                                      style: TextStyle(fontSize: 10))))),
                    ])))));
        await tester.pumpAndSettle();
        if (kind != 'inbox') {
          await tester.runAsync(() => precacheImage(
              const AssetImage('assets/mascot/expression-03-focused.png'),
              tester.element(find.byType(AiAdvisorScreen))));
          await tester.enterText(
              find.byType(TextField),
              kind == 'budget'
                  ? 'Ngân sách ăn uống có vượt không?'
                  : 'Cơ cấu thu chi tháng này');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView).first, const Offset(0, 700));
          await tester.pumpAndSettle();
        } else {
          FinoraNotice.of(tester.element(find.byType(NotificationScreen)))
              .showSnackBar(const SnackBar(
                  content: Text('Thông báo kiểm thử ở đầu màn hình')));
          await tester.pump();
        }
        await save(key, '$kind-${dark ? 'dark' : 'light'}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        if (kind == 'inbox') await BankSyncService().acknowledge('qa-bank');
        ledger.dispose();
        budgets.dispose();
        more.dispose();
      }
    }
  });
}
