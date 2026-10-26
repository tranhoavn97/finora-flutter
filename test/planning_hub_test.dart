import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/features/planning/planning_hub_screen.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/state/budget_provider.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/widget_style_controller.dart';
import 'package:finora/state/family_provider.dart';

class _TestBudgetProvider extends BudgetProvider {
  _TestBudgetProvider() {
    isRefreshing = false;
    budgetsWithSpent = [
      const BudgetSpentData(
        Budget(
          id: 'b1',
          categoryId: 'cat1',
          categoryName: 'Ăn uống',
          limitAmount: 5000000,
        ),
        3200000,
        0.64,
      ),
      const BudgetSpentData(
        Budget(
          id: 'b2',
          categoryId: 'cat2',
          categoryName: 'Mua sắm',
          limitAmount: 3000000,
        ),
        1500000,
        0.50,
      ),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _TestMoreProvider extends MoreProvider {
  _TestMoreProvider() {
    isRefreshing = false;
    goals = [
      const Goal(
        id: 'g1',
        userId: 'test_user',
        name: 'Quỹ khẩn cấp 6 tháng',
        targetAmount: 60000000,
        savedAmount: 45000000,
        targetDate: 1767225600000,
      ),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _TestTransactionProvider extends TransactionProvider {
  final List<TransactionModel> _mockTxs = [
    TransactionModel(
      id: 'tx1',
      amount: 50000,
      note: 'Cà phê sáng',
      categoryName: 'Ăn uống',
      date: DateTime.now().millisecondsSinceEpoch,
    ),
  ];
  _TestTransactionProvider() {
    isRefreshing = false;
  }
  @override
  List<TransactionModel> get transactions => _mockTxs;
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildPlanningHubHarness({
    double width = 390,
    double height = 844,
    double textScale = 1.0,
    int initialTab = 0,
  }) {
    final budgetProvider = _TestBudgetProvider();
    final moreProvider = _TestMoreProvider();
    final txProvider = _TestTransactionProvider();
    final themeStudio = ThemeStudioController();
    final widgetStyle = WidgetStyleController();
    final familyProvider = FamilyProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
        ChangeNotifierProvider<MoreProvider>.value(value: moreProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
        ChangeNotifierProvider<ThemeStudioController>.value(value: themeStudio),
        ChangeNotifierProvider<WidgetStyleController>.value(value: widgetStyle),
        ChangeNotifierProvider<FamilyProvider>.value(value: familyProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: PlanningHubScreen(
              userId: 'test_user',
              isRoot: true,
              initialTabIndex: initialTab,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('PlanningHubScreen renders Executive Card and 3 Pill Tabs', (tester) async {
    await tester.pumpWidget(buildPlanningHubHarness());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Kế hoạch & Báo cáo'), findsOneWidget);
    expect(find.textContaining('NGÂN SÁCH THÁNG'), findsOneWidget);

    // Verify 3 Pill Tabs
    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('Mục tiêu'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('PlanningHubScreen tab switching works smoothly and transforms master card', (tester) async {
    await tester.pumpWidget(buildPlanningHubHarness());
    await tester.pumpAndSettle();

    // Initially on Tab 0: Ngân sách
    expect(find.textContaining('NGÂN SÁCH THÁNG'), findsOneWidget);

    // Tap 'Mục tiêu' tab
    await tester.tap(find.text('Mục tiêu'));
    await tester.pumpAndSettle();
    expect(find.text('TỔNG TÍCH LŨY MỤC TIÊU'), findsOneWidget);

    // Tap 'Báo cáo' tab
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DÒNG TIỀN THÁNG'), findsOneWidget);
  });

  testWidgets('PlanningHubScreen layout check at 320px width with textScaler 1.5', (tester) async {
    await tester.pumpWidget(buildPlanningHubHarness(
      width: 320,
      height: 700,
      textScale: 1.5,
    ));
    await tester.pumpAndSettle();

    // Verify no overflow occurred
    expect(tester.takeException(), isNull);
  });
}
