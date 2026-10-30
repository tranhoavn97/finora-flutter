import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/transaction/add_transaction_page.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';

class _MockTransactions extends TransactionProvider {
  _MockTransactions() {
    wallets = const [
      Wallet(
        id: 'w1',
        name: 'Tiết kiệm Chồng',
        type: 'bank',
        balance: 37780000,
        bankCode: 'vcb',
      ),
      Wallet(
        id: 'w2',
        name: 'Thẻ tín dụng VIB',
        type: 'credit_card',
        balance: -5000000,
        bankCode: 'vib',
        creditLimit: 20000000,
        currentDebt: 5000000,
      ),
    ];
    categories = const [
      Category(id: 'food', name: 'Ăn uống', categoryGroup: 'expense', color: '#E11D48'),
      Category(id: 'salary', name: 'Lương', categoryGroup: 'income', color: '#059669'),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AddTransactionPage renders 2 wallet dropdowns on 1 row for transfer',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final txProv = _MockTransactions();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
          ChangeNotifierProvider<ThemeStudioController>(
            create: (_) => ThemeStudioController(),
          ),
        ],
        child: const MaterialApp(
          home: AddTransactionPage(
            userId: 'user-test',
            initialType: 'transfer',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 2 dropdowns exist on 1 row
    expect(find.text('Ví nguồn'), findsOneWidget);
    expect(find.text('Ví nhận'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsWidgets);
  });

  testWidgets('AddTransactionPage renders merchant selector with icons and text for expense',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final txProv = _MockTransactions();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
          ChangeNotifierProvider<ThemeStudioController>(
            create: (_) => ThemeStudioController(),
          ),
        ],
        child: const MaterialApp(
          home: AddTransactionPage(
            userId: 'user-test',
            initialType: 'expense',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify merchant selector has both icon and text
    expect(find.textContaining('Nơi mua'), findsOneWidget);
    expect(find.text('Không chọn'), findsOneWidget);
    expect(find.text('Green SM'), findsOneWidget);

    // Scroll horizontal merchant list to reveal Be
    await tester.drag(find.byType(ListView).last, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(find.text('Be'), findsOneWidget);
  });

  testWidgets('AddTransactionPage renders 2 wallet dropdowns for credit card payment',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final txProv = _MockTransactions();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
          ChangeNotifierProvider<ThemeStudioController>(
            create: (_) => ThemeStudioController(),
          ),
        ],
        child: const MaterialApp(
          home: AddTransactionPage(
            userId: 'user-test',
            initialType: 'credit_card_payment',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 2 dropdowns: Ví nguồn & Thẻ nhận
    expect(find.text('Ví nguồn'), findsOneWidget);
    expect(find.text('Thẻ nhận'), findsOneWidget);
  });
}
