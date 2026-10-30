import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/widgets/transaction_calculator_sheet.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/features/transaction/add_transaction_page.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';

class _MockTransactions extends TransactionProvider {
  _MockTransactions() {
    wallets = const [
      Wallet(
        id: 'w1',
        name: 'Tiền mặt',
        type: 'cash',
        balance: 505000,
      ),
      Wallet(
        id: 'w2',
        name: 'Chi tiêu Chồng',
        type: 'bank',
        balance: 76742,
        bankCode: 'tcb',
      ),
    ];
    categories = const [
      Category(id: 'food', name: 'Ăn uống', categoryGroup: 'expense', color: '#E11D48'),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TransactionCalculatorSheet Unit & Widget Tests', () {
    testWidgets('Calculates expression correctly and returns result on apply',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? appliedAmount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  appliedAmount = await TransactionCalculatorSheet.show(
                    context,
                    initialAmount: 0,
                  );
                },
                child: const Text('Open Calc'),
              ),
            ),
          ),
        ),
      );

      // Open calculator
      await tester.tap(find.text('Open Calc'));
      await tester.pumpAndSettle();

      expect(find.text('Máy tính giao dịch'), findsOneWidget);

      // Tap 5, 0, 000 -> 50000
      await tester.tap(find.widgetWithText(InkWell, '5'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '000'));
      await tester.pumpAndSettle();

      // Tap +
      await tester.tap(find.widgetWithText(InkWell, '+'));
      await tester.pumpAndSettle();

      // Tap 3, 5, 000 -> 35000
      await tester.tap(find.widgetWithText(InkWell, '3'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '5'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '000'));
      await tester.pumpAndSettle();

      // Tap =
      await tester.tap(find.widgetWithText(InkWell, '='));
      await tester.pumpAndSettle();

      // Verify display result 85.000
      expect(find.text('85.000'), findsWidgets);

      // Tap Apply
      await tester.tap(find.textContaining('Áp dụng kết quả'));
      await tester.pumpAndSettle();

      expect(appliedAmount, equals(85000));
    });
  });

  group('AddTransactionPage Calculator Integration & Bento Wallet Tests', () {
    testWidgets('Tapping calculator button opens calc and updates transaction amount',
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

      // Tap calculator icon button
      final calcButton = find.byIcon(Icons.calculate_rounded);
      expect(calcButton, findsOneWidget);
      await tester.tap(calcButton);
      await tester.pumpAndSettle();

      expect(find.text('Máy tính giao dịch'), findsOneWidget);

      // Tap 8, 5, 000, =
      await tester.tap(find.widgetWithText(InkWell, '8'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '5'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '000'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '='));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.textContaining('Áp dụng kết quả'));
      await tester.pumpAndSettle();

      // Verify amount is updated in AddTransactionPage
      expect(find.text('85.000'), findsWidgets);
    });

    testWidgets('Transfer tab renders Big Bento Cards for Vi nguon & Vi nhan matching Chi tieu',
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

      // Verify Ví nguồn and Ví nhận cards exist with wallet names and balances
      expect(find.text('Ví nguồn'), findsOneWidget);
      expect(find.text('Ví nhận'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
      expect(find.text('Chi tiêu Chồng'), findsOneWidget);
      expect(find.textContaining('505.000'), findsOneWidget);
      expect(find.textContaining('76.742'), findsOneWidget);
    });
  });
}
