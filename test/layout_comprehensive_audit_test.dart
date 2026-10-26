import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/utils/date_filter.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/dashboard/dashboard_screen.dart';
import 'package:finora/features/wallet/wealth_hub_screen.dart';
import 'package:finora/features/transaction/add_transaction_page.dart';
import 'package:finora/features/wallet/add_wallet_page.dart';
import 'package:finora/features/wallet/wallet_screen.dart';
import 'package:finora/features/budget/budget_screen.dart';
import 'package:finora/state/dashboard_provider.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/budget_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/widget_style_controller.dart';
import 'package:finora/state/family_provider.dart';

class _MockTransactionProvider extends TransactionProvider {
  _MockTransactionProvider() {
    isRefreshing = false;
    selectedDateFilter = DateFilterOption.allTime;
    wallets = [
      const Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', balance: 5000000, owner: 'me'),
      const Wallet(id: 'w2', name: 'Techcombank', type: 'bank', balance: 25000000, owner: 'me'),
    ];
    categories = [
      const Category(id: 'c1', name: 'Ăn uống', icon: '🍜', categoryGroup: 'expense'),
      const Category(id: 'c2', name: 'Lương', icon: '💰', categoryGroup: 'income'),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockWalletProvider extends WalletProvider {
  _MockWalletProvider() {
    isRefreshing = false;
    hasLoadedBalances = true;
    wallets = [
      const Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', balance: 5000000, owner: 'me'),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockFamilyProvider extends FamilyProvider {}

class _MockMoreProvider extends MoreProvider {
  _MockMoreProvider() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockBudgetProvider extends BudgetProvider {
  _MockBudgetProvider() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _MockDashboardProvider extends DashboardProvider {
  _MockDashboardProvider() {
    isLoading = false;
    data = DashboardData(
      wallets: const [
        Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', balance: 5000000, owner: 'me'),
        Wallet(id: 'w2', name: 'Techcombank', type: 'bank', balance: 25000000, owner: 'me'),
      ],
      totalWalletBalance: 30000000,
      periodIncome: 15000000,
      periodExpense: 5000000,
      periodNet: 10000000,
      recentTransactions: [
        TransactionModel(
          id: 'tx_1',
          amount: 85000,
          note: 'Ăn trưa bún bò Huế',
          categoryName: 'Ăn uống',
          date: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
    );
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TransactionScreen & DateFilterModal layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = _MockTransactionProvider();
    final walletProvider = _MockWalletProvider();
    final moreProvider = _MockMoreProvider();
    provider.transactions.add(TransactionModel(
      id: 'tx_1',
      amount: 150000,
      note: 'Ăn trưa',
      categoryName: 'Ăn uống',
      date: DateTime.now().millisecondsSinceEpoch,
    ));

    final studio = ThemeStudioController();
    await studio.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: provider),
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<MoreProvider>.value(value: moreProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: WealthHubScreen(userId: 'test_user'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'Initial render caused an error');

    // Tap on the date dropdown pill on the spending card to open _openDateFilterModal
    final calendarIcon = find.byIcon(Icons.calendar_today_rounded);
    if (calendarIcon.evaluate().isNotEmpty) {
      await tester.tap(calendarIcon.first);
      await tester.pumpAndSettle();
    }

    // Check if opening the modal caused any overflow
    expect(caughtError, isNull, reason: 'Opening DateFilterModalSheet caused a layout error: ${caughtError?.exception}');
  });

  testWidgets('AddTransactionPage layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final txProvider = _MockTransactionProvider();
    final familyProvider = _MockFamilyProvider();
    final studio = ThemeStudioController();
    await studio.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
          ChangeNotifierProvider<FamilyProvider>.value(value: familyProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: AddTransactionPage(userId: 'test_user'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'AddTransactionPage threw an exception');
  });

  testWidgets('AddWalletPage layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final walletProvider = _MockWalletProvider();
    final studio = ThemeStudioController();
    await studio.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: AddWalletPage(userId: 'test_user'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'AddWalletPage threw an exception');
  });

  testWidgets('DashboardScreen layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dashProvider = _MockDashboardProvider();
    final moreProvider = _MockMoreProvider();
    final budgetProvider = _MockBudgetProvider();
    final txProvider = _MockTransactionProvider();
    final studio = ThemeStudioController();
    await studio.load();
    final widgetStyle = WidgetStyleController();
    await widgetStyle.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
          ChangeNotifierProvider<MoreProvider>.value(value: moreProvider),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
          ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
          ChangeNotifierProvider<WidgetStyleController>.value(value: widgetStyle),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: DashboardScreen(
              userId: 'test_user',
              userName: 'Nguyen Van A',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'DashboardScreen threw an exception: ${caughtError?.exception}');
  });

  testWidgets('WalletScreen layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final walletProvider = _MockWalletProvider();
    final studio = ThemeStudioController();
    await studio.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: WalletScreen(userId: 'test_user'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'WalletScreen threw an exception: ${caughtError?.exception}');
  });

  testWidgets('BudgetScreen layout check at 320px width with textScaler 1.5',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final budgetProvider = _MockBudgetProvider();
    final moreProvider = _MockMoreProvider();
    final txProvider = _MockTransactionProvider();
    final studio = ThemeStudioController();
    await studio.load();

    FlutterErrorDetails? caughtError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtError = details;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
          ChangeNotifierProvider<MoreProvider>.value(value: moreProvider),
          ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: BudgetScreen(userId: 'test_user'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(caughtError, isNull, reason: 'BudgetScreen threw an exception: ${caughtError?.exception}');
  });
}
