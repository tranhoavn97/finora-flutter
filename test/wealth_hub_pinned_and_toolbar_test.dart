import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
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
    ];
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _TestMoreProvider extends MoreProvider {
  _TestMoreProvider() {
    isRefreshing = false;
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
  List<TransactionModel> get transactions => [
    TransactionModel(
      id: 't1',
      userId: 'test_user',
      walletId: 'w1',
      amount: 85000,
      type: 'expense',
      categoryId: 'c1',
      categoryName: 'Ăn uống',
      date: 1735689600000,
      note: 'Bún bò',
    ),
  ];

  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWealthHubHarness({int initialTab = 0}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletProvider>.value(value: _TestWalletProvider()),
        ChangeNotifierProvider<MoreProvider>.value(value: _TestMoreProvider()),
        ChangeNotifierProvider<TransactionProvider>.value(value: _TestTransactionProvider()),
        ChangeNotifierProvider<ThemeStudioController>.value(value: ThemeStudioController()),
        ChangeNotifierProvider<WidgetStyleController>.value(value: WidgetStyleController()),
        ChangeNotifierProvider<FamilyProvider>.value(value: FamilyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
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

  testWidgets('WealthHubScreen verifies transparent header, no DANH SACH GIAO DICH header, and merged 1-row toolbar', (tester) async {
    await tester.pumpWidget(buildWealthHubHarness(initialTab: 0));
    await tester.pumpAndSettle();

    // 1. Transparent Header exists
    final now = DateTime.now();
    expect(find.text('Tháng ${now.month}, ${now.year}'), findsOneWidget);

    // 2. "DANH SÁCH GIAO DỊCH" header text MUST BE ABSENT
    expect(find.textContaining('DANH SÁCH GIAO DỊCH'), findsNothing);

    // 3. Merged 1-row toolbar has filter chips (note: 'Tất cả' appears in member pill and in toolbar chip)
    expect(find.text('Tất cả'), findsNWidgets(2));
    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(find.text('Thu nhập'), findsOneWidget);
    expect(find.text('Chuyển khoản'), findsOneWidget);

    // 4. Action buttons: Search icon button exists; add button exists in header and toolbar
    expect(find.byIcon(Icons.search_rounded), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));

    // 5. Tap Search icon button -> Expands search bar with 'Đóng'
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Tìm kiếm ghi chú, danh mục, ví...'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);

    // Close search
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    expect(find.text('Tìm kiếm ghi chú, danh mục, ví...'), findsNothing);
    expect(find.text('Chi tiêu'), findsOneWidget);
  });

  testWidgets('WealthHubScreen Tab 3 Sổ nợ verifies pinned toolbar with Cho vay and Vay no', (tester) async {
    await tester.pumpWidget(buildWealthHubHarness(initialTab: 3));
    await tester.pumpAndSettle();

    // Tab 3 Sổ nợ pinned selector & content
    expect(find.text('Cho vay'), findsAtLeastNWidgets(1));
    expect(find.text('Vay nợ'), findsOneWidget);
    expect(find.text('Anh Tuấn'), findsOneWidget);
  });
}
