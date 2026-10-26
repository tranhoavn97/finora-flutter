import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/widgets/finora_navigation.dart';
import 'package:finora/core/widgets/premium_widgets.dart';
import 'package:finora/features/budget/budget_screen.dart';
import 'package:finora/features/goal/goal_screen.dart';
import 'package:finora/features/report/report_screen.dart';
import 'package:finora/state/budget_provider.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/widget_style_controller.dart';

class _MockBudgetProvider extends BudgetProvider {
  _MockBudgetProvider() {
    isRefreshing = false;
    budgetsWithSpent = [];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockMoreProvider extends MoreProvider {
  _MockMoreProvider() {
    isRefreshing = false;
    goals = [];
    loans = [];
    assets = [];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockTransactionProvider extends TransactionProvider {
  _MockTransactionProvider() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockWalletProvider extends WalletProvider {
  _MockWalletProvider() {
    isRefreshing = false;
    wallets = [];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FinoraNavigation renders 4 tabs with updated icons and without crashing', (tester) async {
    int currentTab = 2; // Kế hoạch tab
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeStudioController>(
            create: (_) => ThemeStudioController(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FinoraNavigation(
              index: currentTab,
              onTap: (i) => currentTab = i,
              onAddTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Image 4 design: Active tab displays label text, all tabs provide Tooltip & Semantics
    expect(find.text('Kế hoạch'), findsOneWidget);
    expect(find.byTooltip('Trang chủ'), findsOneWidget);
    expect(find.byTooltip('Tài sản'), findsOneWidget);
    expect(find.byTooltip('Kế hoạch'), findsOneWidget);
    expect(find.byTooltip('Cá nhân'), findsOneWidget);
  });

  testWidgets('BudgetScreen hides old hero card when isTab is true', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BudgetProvider>(create: (_) => _MockBudgetProvider()),
          ChangeNotifierProvider<MoreProvider>(create: (_) => _MockMoreProvider()),
          ChangeNotifierProvider<TransactionProvider>(create: (_) => _MockTransactionProvider()),
          ChangeNotifierProvider<ThemeStudioController>(create: (_) => ThemeStudioController()),
          ChangeNotifierProvider<WidgetStyleController>(create: (_) => WidgetStyleController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BudgetScreen(userId: 'test_user', isTab: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The old hero card has 'Hạn mức chi tiêu kế hoạch trong kỳ' which should be hidden
    expect(find.text('Hạn mức chi tiêu kế hoạch trong kỳ'), findsNothing);
  });

  testWidgets('GoalScreen hides old overview card when isTab is true', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MoreProvider>(create: (_) => _MockMoreProvider()),
          ChangeNotifierProvider<ThemeStudioController>(create: (_) => ThemeStudioController()),
          ChangeNotifierProvider<WidgetStyleController>(create: (_) => WidgetStyleController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GoalScreen(userId: 'test_user', isTab: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The old overview card has 'TỔNG TÍCH LŨY MỤC TIÊU' which should be hidden inside GoalScreen
    expect(find.text('TỔNG TÍCH LŨY MỤC TIÊU'), findsNothing);
  });

  testWidgets('ReportScreen hides old NetWorth card when isTab is true', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>(create: (_) => _MockTransactionProvider()),
          ChangeNotifierProvider<WalletProvider>(create: (_) => _MockWalletProvider()),
          ChangeNotifierProvider<MoreProvider>(create: (_) => _MockMoreProvider()),
          ChangeNotifierProvider<ThemeStudioController>(create: (_) => ThemeStudioController()),
          ChangeNotifierProvider<WidgetStyleController>(create: (_) => WidgetStyleController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ReportScreen(userId: 'test_user', isTab: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The old net worth card in ReportScreen has 'TỔNG TÀI SẢN RÒNG' which should be hidden
    expect(find.text('TỔNG TÀI SẢN RÒNG'), findsNothing);
  });

  test('FirstLetterUpperCaseFormatter capitalizes first letter while preserving cursor and IME composing', () {
    const formatter = FirstLetterUpperCaseFormatter();
    final res = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(
        text: 'ăn trưa bún bò',
        selection: TextSelection.collapsed(offset: 14),
      ),
    );
    expect(res.text, 'Ăn trưa bún bò');
    expect(res.selection.baseOffset, 14);
  });

  test('DotSeparatorTextInputFormatter formats numbers and preserves mid-string cursor on insert and backspace', () {
    const formatter = DotSeparatorTextInputFormatter();

    // 1. Standard typing: 1500000 -> 1.500.000
    final step1 = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(
        text: '1500000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    expect(step1.text, '1.500.000');
    expect(step1.selection.baseOffset, 9);

    // 2. Mid-string insert: insert '2' after '1.' in '1.500.000' -> '12.500.000' with cursor right after '2'
    final step2 = formatter.formatEditUpdate(
      step1,
      const TextEditingValue(
        text: '1.2500.000',
        selection: TextSelection.collapsed(offset: 3), // 2 digits ('1', '2') before cursor
      ),
    );
    expect(step2.text, '12.500.000');
    expect(step2.selection.baseOffset, 2); // right after '12'

    // 3. Backspace on dot: deleting '.' at index 2 in '12.500.000' deletes the '2' before the dot -> '1.500.000'
    final step3 = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '12.500.000',
        selection: TextSelection.collapsed(offset: 3),
      ),
      const TextEditingValue(
        text: '12500.000',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(step3.text, '1.500.000');
    expect(step3.selection.baseOffset, 1); // right after '1'
  });
}
