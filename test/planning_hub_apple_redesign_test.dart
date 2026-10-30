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
import 'package:finora/state/wallet_provider.dart';

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
      amount: 150000,
      note: 'Nhà hàng cuối tuần',
      categoryName: 'Ăn uống',
      type: 'expense',
      date: DateTime.now().millisecondsSinceEpoch,
    ),
    TransactionModel(
      id: 'tx2',
      amount: 25000000,
      note: 'Lương tháng',
      categoryName: 'Tiền lương',
      type: 'income',
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

class _TestWalletProvider extends WalletProvider {
  _TestWalletProvider() {
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

  Widget buildPlanningHarness({
    double width = 390,
    double height = 844,
    double textScale = 1.0,
    int initialTab = 0,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetProvider>.value(
            value: _TestBudgetProvider()),
        ChangeNotifierProvider<MoreProvider>.value(value: _TestMoreProvider()),
        ChangeNotifierProvider<TransactionProvider>.value(
            value: _TestTransactionProvider()),
        ChangeNotifierProvider<WalletProvider>.value(
            value: _TestWalletProvider()),
        ChangeNotifierProvider<ThemeStudioController>.value(
            value: ThemeStudioController()),
        ChangeNotifierProvider<WidgetStyleController>.value(
            value: WidgetStyleController()),
        ChangeNotifierProvider<FamilyProvider>.value(value: FamilyProvider()),
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

  testWidgets('PlanningHubScreen conforms to Apple HIG design and typography',
      (tester) async {
    await tester.pumpWidget(buildPlanningHarness());
    await tester.pumpAndSettle();

    // 1. App Bar: Clean segmented tabs promoted to header, NO title text, NO subtitle, NO PRO badge
    expect(find.text('Ngân sách'), findsWidgets);
    expect(find.text('Mục tiêu'), findsWidgets);
    expect(find.text('Báo cáo'), findsWidgets);
    expect(find.text('Kế hoạch & Báo cáo'), findsNothing);
    expect(
        find.text('Ngân sách · Mục tiêu · Phân tích dòng tiền'), findsNothing);
    expect(find.text('PRO'), findsNothing);

    // 2. Master Card (Tab 0 - Budget)
    expect(find.textContaining('NGÂN SÁCH THÁNG'), findsOneWidget);
    expect(find.text('Hạn mức còn lại'), findsOneWidget);
    expect(find.text('Chủ động từng khoản chi.'), findsOneWidget);

    // 3. Category budget card (Tab 0)
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsWidgets);

    // 4. Switch to Goal tab
    await tester.tap(find.text('Mục tiêu'));
    await tester.pumpAndSettle();

    expect(find.text('Ước mơ có một lộ trình.'), findsOneWidget);
    expect(find.text('TÍCH LŨY CHO ĐIỀU QUAN TRỌNG'), findsOneWidget);
    expect(find.textContaining('mục tiêu đang thực hiện'), findsOneWidget);
    expect(find.text('Quỹ khẩn cấp 6 tháng'), findsOneWidget);
    expect(find.text('Góp tiền'), findsOneWidget);

    // 5. Switch to Report tab
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('DÒNG TIỀN THÁNG'), findsNothing);
    expect(find.text('Hiểu nhịp tiền của bạn.'), findsNothing);
    expect(find.text('Tháng này'), findsOneWidget);
    await tester.tap(find.text('Tháng này'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Năm nay'));
    await tester.pumpAndSettle();
    expect(find.text('Năm nay'), findsOneWidget);
    expect(find.textContaining('DÒNG TIỀN THÁNG'), findsNothing);
    expect(find.text('Cơ cấu danh mục chi tiêu'), findsOneWidget);

    await tester.ensureVisible(find.text('Tỷ trọng chi tiêu Vợ & Chồng'));
    expect(find.text('Tỷ trọng chi tiêu Vợ & Chồng'), findsOneWidget);
    await tester
        .ensureVisible(find.text('Biến động Thu - Chi 6 tháng gần nhất'));
    expect(find.text('Biến động Thu - Chi 6 tháng gần nhất'), findsOneWidget);
  });

  testWidgets(
      'Apple Redesign layout robustness at 320px width and textScaler 1.5',
      (tester) async {
    await tester.pumpWidget(buildPlanningHarness(
      width: 320,
      height: 700,
      textScale: 1.5,
      initialTab: 0,
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to tab 1 at 320px
    await tester.tap(find.text('Mục tiêu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to tab 2 at 320px
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
