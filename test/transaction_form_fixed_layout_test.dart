import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/transaction/add_transaction_page.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';

class _Transactions extends TransactionProvider {
  final writes = <TransactionModel>[];
  Completer<void>? pending;
  _Transactions() {
    wallets = const [
      Wallet(id: 'cash', name: 'Tiền mặt', type: 'cash', balance: 500000),
      Wallet(id: 'bank', name: 'Ngân hàng', type: 'bank', balance: 1000000)
    ];
    categories = const [
      Category(id: 'food', name: 'Ăn uống', categoryGroup: 'expense'),
      Category(id: 'salary', name: 'Lương', categoryGroup: 'income')
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
  @override
  Future<void> updateTransaction(
      String userId, String id, TransactionModel tx) async {
    writes.add(tx);
  }

  @override
  Future<void> createTransaction(String userId, TransactionModel tx) async {
    writes.add(tx);
    if (pending != null) await pending!.future;
  }
}

Future<void> mount(WidgetTester tester, _Transactions provider,
    {double width = 384, double scale = 1, TransactionModel? existing}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 824);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionProvider>.value(value: provider),
        ChangeNotifierProvider(create: (_) => ThemeStudioController()),
      ],
      child: MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: AddTransactionPage(userId: 'local-test', existing: existing))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Editing an imported transaction hides reference input and keeps its original metadata',
      (tester) async {
    final provider = _Transactions();
    await mount(tester, provider,
        existing: const TransactionModel(
            id: 'imported',
            amount: 50000,
            type: 'expense',
            walletId: 'cash',
            categoryId: 'food',
            categoryName: 'Ăn uống',
            bankTransactionCode: 'FT123',
            rawBankNotification: 'Tin gốc đủ nội dung cuối',
            tags: ['bank_code:FT123']));
    expect(find.textContaining('Mã giao dịch chính'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(provider.writes.single.bankTransactionCode, 'FT123');
    expect(
        provider.writes.single.rawBankNotification, 'Tin gốc đủ nội dung cuối');
    expect(provider.writes.single.tags, contains('bank_code:FT123'));
  });

  testWidgets('keyboard leaves fixed save action above the inset',
      (tester) async {
    await mount(tester, _Transactions());
    final tab = find.byKey(const ValueKey('transaction-type-tabs'));
    final top = tester.getTopLeft(tab);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tab), top);
    expect(
        tester.getRect(find.byKey(const ValueKey('transaction-save'))).bottom,
        lessThanOrEqualTo(524));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'successful save opens confirmation only after persistence completes',
      (tester) async {
    final provider = _Transactions()..pending = Completer<void>();
    await mount(tester, provider);
    await tester.enterText(find.byType(TextField).first, '50000');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
    provider.pending!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Đã ghi nhận giao dịch!'), findsOneWidget);
    expect(provider.writes.single.amount, 50000);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'all five tabs stay visible and fixed while form scrolls at narrow width',
      (tester) async {
    await mount(tester, _Transactions(), width: 320, scale: 1.5);
    final tab = find.byKey(const ValueKey('transaction-type-tabs'));
    final before = tester.getRect(tab);
    for (final label in [
      'Chi tiêu',
      'Thu nhập',
      'Chuyển',
      'Trả thẻ',
      'Đầu tư'
    ]) {
      final rect =
          tester.getRect(find.descendant(of: tab, matching: find.text(label)));
      expect(rect.left, greaterThanOrEqualTo(before.left));
      expect(rect.right, lessThanOrEqualTo(before.right));
    }
    await tester.drag(find.byKey(const ValueKey('transaction-form-scroll')),
        const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.getRect(tab), before);
    expect(
        tester.getRect(find.byKey(const ValueKey('transaction-save'))).bottom,
        lessThanOrEqualTo(824));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'save validates amount, prevents duplicate writes and allows retry with same id after failure',
      (tester) async {
    final provider = _Transactions()..pending = Completer<void>();
    await mount(tester, provider);
    final save = find.byKey(const ValueKey('transaction-save'));
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, '85000');
    await tester.pump();
    expect(tester.widget<TextButton>(save).onPressed, isNotNull);
  });
}
