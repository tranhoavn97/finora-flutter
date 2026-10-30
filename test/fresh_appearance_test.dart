import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/design_system/app_theme.dart';
import 'package:finora/core/widgets/finora/financial_components.dart';
import 'package:finora/features/dashboard/fresh_dashboard.dart';
import 'package:finora/state/dashboard_provider.dart';
import 'package:finora/state/theme_controller.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/data/models/wallet.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'Fresh appearance is disabled by default for v27 Apple Minimalist and personalization remains available',
      () async {
    final studio = ThemeStudioController();
    await studio.load();
    expect(studio.freshAppearance, isFalse);
    expect(studio.currentPaletteMeta.primary, const Color(0xFF0F6E56));
    await studio.setFreshAppearance(true);
    expect(studio.freshAppearance, isTrue);
    expect(studio.currentPaletteMeta.primary, const Color(0xFF0066CC));
    await studio.setPalette(AppColorPalette.amethystRoyal);
    expect(studio.freshAppearance, isFalse);
    final custom = studio.currentPaletteMeta;
    await studio.setFreshAppearance(true);
    final reloaded = ThemeStudioController();
    await reloaded.load();
    expect(reloaded.freshAppearance, isTrue);
    await reloaded.setFreshAppearance(false);
    expect(reloaded.currentPaletteMeta.primary, custom.primary);
  });

  test('New installs start bright while an existing dark preference survives',
      () async {
    final theme = ThemeController();
    await theme.load();
    expect(theme.mode, 'light');
    await theme.setMode('dark');
    final reloaded = ThemeController();
    await reloaded.load();
    expect(reloaded.mode, 'dark');
  });

  Widget harness(DashboardProvider provider, {bool hidden = false}) =>
      MaterialApp(
        theme: buildAppleTheme(Brightness.light),
        home: FreshDashboard(
            userId: 'test',
            userName: 'Tên thành viên rất dài để kiểm tra bố cục',
            provider: provider,
            scope: const Text('Tháng này · Cả gia đình'),
            hidden: hidden,
            onToggleMask: () {},
            onNotifications: () {},
            onTransactions: () {},
            onWallets: () {},
            onPlanning: () {},
            onAssistant: () {},
            onQuickLog: () {},
            onRefresh: () async {}),
      );

  testWidgets('Loading is distinguished from an actual zero balance',
      (tester) async {
    final provider = DashboardProvider();
    await tester.pumpWidget(harness(provider));
    expect(find.text('Đang tải tài khoản…'), findsOneWidget);
    expect(find.byType(MoneyText), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets('Long money and privacy remain usable at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = DashboardProvider()
      ..isLoading = false
      ..data = const DashboardData(
          totalWalletBalance: 987654321987,
          periodIncome: 987654321,
          periodExpense: 123456789,
          wallets: [
            Wallet(
                id: 'w', name: 'Tài khoản', type: 'cash', balance: 987654321987)
          ]);
    await tester.pumpWidget(harness(provider));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(harness(provider, hidden: true));
    final amounts = tester.widgetList<MoneyText>(find.byType(MoneyText));
    expect(amounts, isNotEmpty);
    expect(amounts.every((amount) => amount.hidden), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
