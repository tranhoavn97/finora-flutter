import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finora/core/widgets/bank_icon.dart';
import 'package:finora/core/widgets/cupertino_month_year_picker.dart';
import 'package:finora/core/widgets/finora_member_filter.dart';
import 'package:finora/core/widgets/finora_navigation.dart';
import 'package:finora/core/widgets/finora_notice.dart';
import 'package:finora/core/widgets/finora_notification_bell.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/dashboard/extended_hero_cards.dart';
import 'package:finora/features/transaction/add_transaction_page.dart';
import 'package:finora/state/theme_controller.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';

class _MockTransactionsProvider extends TransactionProvider {
  _MockTransactionsProvider() {
    wallets = const [
      Wallet(
        id: 'w_vcb',
        name: 'Vietcombank',
        type: 'bank',
        balance: 25000000,
        bankCode: 'vcb',
      ),
      Wallet(
        id: 'w_tcb',
        name: 'Techcombank',
        type: 'bank',
        balance: 18500000,
        bankCode: 'tcb',
      ),
    ];
    categories = const [
      Category(
        id: 'cat_food',
        name: 'Ăn uống',
        categoryGroup: 'expense',
        color: '#E11D48',
      ),
      Category(
        id: 'merch_custom',
        name: 'Cửa hàng riêng',
        categoryGroup: 'merchant',
        icon: 'store',
        color: '#0284C7',
      ),
    ];
  }

  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('1. FinoraNotice positions cleanly below header and < 100 dy when padding.top == 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  FinoraNotice.of(context).showSnackBar(
                    const SnackBar(content: Text('Thông báo kiểm thử')),
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final toastFinder = find.text('Thông báo kiểm thử');
    expect(toastFinder, findsOneWidget);
    final dy = tester.getTopLeft(toastFinder).dy;
    expect(dy, greaterThanOrEqualTo(68.0));
    expect(dy, lessThan(100.0));
  });

  testWidgets('2. FinoraNavigation bottom dock omits Tooltip wrappers on all dock tabs',
      (WidgetTester tester) async {
    final studio = ThemeStudioController();
    await studio.load();
    final theme = ThemeController();
    await theme.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
          ChangeNotifierProvider<ThemeController>.value(value: theme),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FinoraNavigation(
              index: 0,
              onTap: (_) {},
              onAddTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FinoraNavigation), findsOneWidget);
    expect(find.descendant(of: find.byType(FinoraNavigation), matching: find.byType(Tooltip)),
        findsNothing);
  });

  testWidgets('3. FinoraNotificationBell updates tint dynamically with studio.resolvedPrimary',
      (WidgetTester tester) async {
    final studio = ThemeStudioController();
    await studio.load();

    Widget wrapWithStudio() {
      return ChangeNotifierProvider<ThemeStudioController>.value(
        value: studio,
        child: const MaterialApp(
          home: Scaffold(
            body: FinoraNotificationBell(userId: 'bell-test'),
          ),
        ),
      );
    }

    await studio.setCustomPrimaryAccentColor(const Color(0xFF0284C7));
    await tester.pumpWidget(wrapWithStudio());
    await tester.pump();
    final blueIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(FinoraNotificationBell),
        matching: find.byType(Icon),
      ).first,
    );
    final blueColor = blueIcon.color;

    await studio.setCustomPrimaryAccentColor(const Color(0xFFE11D48));
    await tester.pump();
    final crimsonIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(FinoraNotificationBell),
        matching: find.byType(Icon),
      ).first,
    );
    final crimsonColor = crimsonIcon.color;

    expect(blueColor, isNotNull);
    expect(crimsonColor, isNotNull);
    expect(blueColor, isNot(equals(crimsonColor)));
  });

  testWidgets('4. Outside showFinoraMemberFilterSheet omits Đổi tên and camera edit controls',
      (WidgetTester tester) async {
    final studio = ThemeStudioController();
    await studio.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeStudioController>.value(
        value: studio,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showFinoraMemberFilterSheet(
                    context,
                    currentTag: null,
                    onSelected: (_) {},
                    isDark: false,
                  );
                },
                child: const Text('Open Member Filter'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Member Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Đổi tên'), findsNothing);
    expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_rounded), findsNothing);
  });

  test('5. Category.resolveMerchants omits preset popular brands unless preserveId/Name matches', () {
    final customOnly = Category.resolveMerchants([
      const Category(id: 'm1', name: 'Quán Cà Phê Nhà', categoryGroup: 'merchant'),
    ]);
    expect(customOnly.map((e) => e.id).toList(), ['m1']);
    expect(customOnly.any((e) => e.id == 'shopee'), isFalse);

    final preservedById = Category.resolveMerchants(
      customOnly,
      preserveId: 'shopee',
    );
    expect(preservedById.any((e) => e.id == 'shopee'), isTrue);
    expect(preservedById.any((e) => e.id == 'lazada'), isFalse);

    final preservedByName = Category.resolveMerchants(
      customOnly,
      preserveName: 'TikTok Shop',
    );
    expect(preservedByName.any((e) => e.name == 'TikTok Shop'), isTrue);
  });

  testWidgets('6. 4 new AppHeroCardStyle values at indices 8..11 persist and render cleanly',
      (WidgetTester tester) async {
    expect(AppHeroCardStyle.auroraVaultCard.index, 8);
    expect(AppHeroCardStyle.obsidianTitanium.index, 9);
    expect(AppHeroCardStyle.porcelainMinimal.index, 10);
    expect(AppHeroCardStyle.cyberMeshHorizon.index, 11);

    final studio = ThemeStudioController();
    await studio.load();

    for (final style in const [
      AppHeroCardStyle.auroraVaultCard,
      AppHeroCardStyle.obsidianTitanium,
      AppHeroCardStyle.porcelainMinimal,
      AppHeroCardStyle.cyberMeshHorizon,
    ]) {
      expect(isExtendedHeroCardStyle(style), isTrue);
      await studio.setHeroCardStyle(style);
      expect(studio.heroCardStyle, style);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeStudioController>.value(
          value: studio,
          child: MaterialApp(
            home: Scaffold(
              body: ExtendedNetWorthHeroCard(
                style: style,
                totalBalance: 12500000,
                income: 20000000,
                expense: 7500000,
                netFlow: 12500000,
                isDark: false,
                studio: studio,
                filterActions: const Text('Tất cả'),
                onTogglePrivacy: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ExtendedNetWorthHeroCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('7. CupertinoMonthYearPickerSheet renders month/year grid and returns selected DateTime',
      (WidgetTester tester) async {
    final studio = ThemeStudioController();
    await studio.load();
    DateTime? picked;

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeStudioController>.value(
        value: studio,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  picked = await CupertinoMonthYearPickerSheet.show(
                    context,
                    initialDate: DateTime(2026, 11, 1),
                  );
                },
                child: const Text('Open Month Picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Month Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Tháng 5'), findsOneWidget);
    await tester.tap(find.text('Tháng 5'));
    await tester.pump();

    await tester.tap(find.textContaining('Áp dụng'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.year, 2026);
    expect(picked!.month, 5);
  });

  testWidgets('8. CategoryIconBadge renders photo icon with at most one circular outer border',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIconBadge(
            icon: 'bank-vcb',
            categoryName: 'Vietcombank',
            size: 48,
          ),
        ),
      ),
    );
    await tester.pump();

    final containersWithBorder = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(CategoryIconBadge),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final dec = widget.decoration! as BoxDecoration;
            return dec.shape == BoxShape.circle && dec.border != null;
          }
          return false;
        }),
      ),
    );
    expect(containersWithBorder.length, lessThanOrEqualTo(1));
  });

  testWidgets('9. AddTransactionPage transfer initializes distinct wallets and swap button swaps them',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final txProv = _MockTransactionsProvider();
    final studio = ThemeStudioController();
    await studio.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: const MaterialApp(
          home: AddTransactionPage(
            userId: 'user-swap-test',
            initialType: 'transfer',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vietcombank'), findsOneWidget);
    expect(find.text('Techcombank'), findsOneWidget);

    final swapFinder = find.byIcon(Icons.swap_horiz_rounded);
    expect(swapFinder, findsOneWidget);

    final initialVcbX = tester.getCenter(find.text('Vietcombank')).dx;
    final initialTcbX = tester.getCenter(find.text('Techcombank')).dx;
    expect(initialVcbX, lessThan(initialTcbX));

    await tester.tap(swapFinder);
    await tester.pumpAndSettle();

    final swappedVcbX = tester.getCenter(find.text('Vietcombank')).dx;
    final swappedTcbX = tester.getCenter(find.text('Techcombank')).dx;
    expect(swappedTcbX, lessThan(swappedVcbX));
  });
}
