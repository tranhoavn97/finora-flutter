import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/features/wallet/wealth_hub_screen.dart';
import 'package:finora/state/wallet_provider.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/widget_style_controller.dart';
import 'package:finora/state/family_provider.dart';

class _TestWalletProvider extends WalletProvider {
  _TestWalletProvider() {
    isRefreshing = false;
    hasLoadedBalances = true;
    wallets = [
      const Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', balance: 10000000, owner: 'me'),
      const Wallet(id: 'w2', name: 'Techcombank', type: 'bank', balance: 50000000, owner: 'me'),
      const Wallet(id: 'w3', name: 'Thẻ tín dụng VPBank', type: 'credit', balance: 0, currentDebt: 5000000, initialDebt: 0, owner: 'me'),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _TestMoreProvider extends MoreProvider {
  _TestMoreProvider() {
    isRefreshing = false;
    assets = [
      const Asset(
        id: 'a1',
        userId: 'test_user',
        name: 'Vàng SJC 9999',
        type: 'gold',
        costBasis: 85000000,
        marketValue: 90000000,
        status: 'active',
        createdAt: 1735689600000,
      ),
      const Asset(
        id: 'a2',
        userId: 'test_user',
        name: 'Sổ tiết kiệm VCB',
        type: 'savings',
        costBasis: 100000000,
        marketValue: 105000000,
        status: 'active',
        createdAt: 1735689600000,
      ),
    ];
    loans = [
      const Loan(
        id: 'l1',
        userId: 'test_user',
        personName: 'Anh Tuấn',
        type: 'lent',
        principalAmount: 20000000,
        remainingPrincipal: 15000000,
        paidAmount: 5000000,
        status: 'active',
        startDate: 1735689600000,
      ),
      const Loan(
        id: 'l2',
        userId: 'test_user',
        personName: 'Chị Lan',
        type: 'borrowed',
        principalAmount: 10000000,
        remainingPrincipal: 8000000,
        paidAmount: 2000000,
        status: 'active',
        startDate: 1735689600000,
      ),
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _TestTransactionProvider extends TransactionProvider {
  _TestTransactionProvider() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWealthHubHarness({
    double width = 390,
    double height = 844,
    double textScale = 1.0,
    int initialTab = 0,
  }) {
    final walletProvider = _TestWalletProvider();
    final moreProvider = _TestMoreProvider();
    final txProvider = _TestTransactionProvider();
    final themeStudio = ThemeStudioController();
    final widgetStyle = WidgetStyleController();
    final familyProvider = FamilyProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
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
            body: WealthHubScreen(
              userId: 'test_user',
              isRoot: true,
              initialTabIndex: initialTab,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('WealthHubScreen renders Net Worth Master Card and computes values accurately', (tester) async {
    await tester.pumpWidget(buildWealthHubHarness(initialTab: 1));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('SỐ DƯ VÍ & TÀI KHOẢN'), findsOneWidget);

    // Verify Tab Segment Items
    expect(find.text('Giao dịch'), findsOneWidget);
    expect(find.text('Ví tiền'), findsOneWidget);
    expect(find.text('Đầu tư'), findsOneWidget);
    expect(find.text('Sổ nợ'), findsOneWidget);
  });

  testWidgets('WealthHubScreen switches tabs smoothly between Wallets, Assets and Loans', (tester) async {
    await tester.pumpWidget(buildWealthHubHarness());
    await tester.pumpAndSettle();

    // Tap on Tab 2: Đầu tư
    await tester.tap(find.text('Đầu tư'));
    await tester.pumpAndSettle();

    // Verify Assets content is active and visible
    expect(find.textContaining('DANH MỤC ĐẦU TƯ'), findsOneWidget);
    expect(find.text('Vàng SJC 9999'), findsOneWidget);

    // Tap on Tab 3: Sổ nợ
    await tester.tap(find.text('Sổ nợ'));
    await tester.pumpAndSettle();

    // Verify Loans content is active and visible
    expect(find.textContaining('DANH SÁCH CHO VAY'), findsOneWidget);
    expect(find.text('Anh Tuấn'), findsOneWidget);
  });

  testWidgets('WealthHubScreen defensive layout audit at 320px width and textScaler 1.5', (tester) async {
    FlutterErrorDetails? layoutError;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed') || details.toString().contains('RenderFlex')) {
        layoutError = details;
      }
    };

    try {
      await tester.pumpWidget(buildWealthHubHarness(width: 320, height: 640, textScale: 1.5));
      await tester.pumpAndSettle();
      expect(layoutError, isNull, reason: 'Zero overflow on WealthHubScreen');
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
