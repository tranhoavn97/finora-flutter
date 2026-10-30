import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finora/core/design_system/v8/finora_v8_controls.dart';
import 'package:finora/core/widgets/finora_navigation.dart';
import 'package:finora/core/widgets/glass_widgets.dart';
import 'package:finora/features/settings/settings_screen.dart';
import 'package:finora/state/theme_controller.dart';
import 'package:finora/state/theme_studio_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dock & Segmented Tabs Redesign Tests', () {
    testWidgets(
        'FinoraSegmentedTabs uses text capsules and slides active indicator',
        (tester) async {
      int selectedIdx = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FinoraSegmentedTabs(
                  labels: const [
                    'Chi tiêu',
                    'Thu nhập',
                    'Chuyển khoản',
                    'Trả thẻ',
                    'Đầu tư'
                  ],
                  icons: const [
                    Icons.arrow_upward_rounded,
                    Icons.arrow_downward_rounded,
                    Icons.swap_horiz_rounded,
                    Icons.credit_card_rounded,
                    Icons.trending_up_rounded,
                  ],
                  selectedIndex: selectedIdx,
                  colors: const [
                    Color(0xFFE11D48),
                    Color(0xFF10B981),
                    Color(0xFF0284C7),
                    Color(0xFFD97706),
                    Color(0xFF7C3AED),
                  ],
                  onChanged: (idx) => setState(() => selectedIdx = idx),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);
      expect(find.text('Trả thẻ'), findsOneWidget);
      expect(find.text('Đầu tư'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);

      // Tap 'Thu nhập'
      await tester.tap(find.text('Thu nhập'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);
    });

    testWidgets(
        'FinoraScrollableSegmentedTabs renders 7 asset options in scrollable track',
        (tester) async {
      int selectedIdx = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FinoraScrollableSegmentedTabs(
                  labels: const [
                    'Vàng',
                    'BĐS',
                    'Cổ phiếu',
                    'Crypto',
                    'Sổ tiết kiệm',
                    'Hụi/Phường',
                    'Khác'
                  ],
                  icons: const ['🪙', '🏡', '📈', '⚡', '🏦', '🤝', '💎'],
                  selectedIndex: selectedIdx,
                  colors: const [
                    Color(0xFFD97706),
                    Color(0xFF059669),
                    Color(0xFF2563EB),
                    Color(0xFF7C3AED),
                    Color(0xFF0D9488),
                    Color(0xFFEA580C),
                    Color(0xFF0F6E56),
                  ],
                  onChanged: (idx) => setState(() => selectedIdx = idx),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Vàng'), findsOneWidget);
      expect(find.text('BĐS'), findsOneWidget);
      expect(find.text('🪙'), findsNothing);

      // Tap 'BĐS'
      await tester.tap(find.text('BĐS'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);
    });

    testWidgets(
        'FinoraNavigation renders Image 4 dock with active capsule and floating CTA',
        (tester) async {
      int activeIndex = 0;
      bool addPressed = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeStudioController>(
              create: (_) => ThemeStudioController(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: StatefulBuilder(
                builder: (context, setState) {
                  return FinoraNavigation(
                    index: activeIndex,
                    onTap: (idx) => setState(() => activeIndex = idx),
                    onAddTap: () => addPressed = true,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Active tab (Trang chủ) shows label text
      expect(find.text('Trang chủ'), findsOneWidget);

      // Inactive tabs show icons, labels collapsed
      expect(find.text('Tài sản'), findsNothing);
      expect(find.text('Kế hoạch'), findsNothing);
      expect(find.text('Cá nhân'), findsNothing);

      // Tooltips exist for accessibility
      expect(find.byTooltip('Trang chủ'), findsOneWidget);
      expect(find.byTooltip('Tài sản'), findsOneWidget);
      expect(find.byTooltip('Kế hoạch'), findsOneWidget);
      expect(find.byTooltip('Cá nhân'), findsOneWidget);

      // Floating CTA Button (+) exists
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(addPressed, isTrue);

      // Tap tab 1 (Tài sản) via tooltip
      await tester.tap(find.byTooltip('Tài sản'));
      await tester.pumpAndSettle();
      expect(activeIndex, 1);
      expect(find.text('Tài sản'), findsOneWidget);
      expect(find.text('Trang chủ'), findsNothing);
    });

    testWidgets(
        'SettingsScreen presents simple preferences with advanced customization',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>(
              create: (_) => ThemeController(),
            ),
            ChangeNotifierProvider<ThemeStudioController>(
              create: (_) => ThemeStudioController(),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(userId: 'test_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('Sáng trong & Xanh tươi'), findsOneWidget);
      expect(find.text('Giảm chuyển động'), findsOneWidget);
      expect(find.text('NỀN PHA MÀU GRADIENT BLUR'), findsNothing);
      expect(find.text('Theo thiết bị'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
      await tester.ensureVisible(find.text('Tùy chỉnh nâng cao'));
      await tester.tap(find.text('Tùy chỉnh nâng cao'));
      await tester.pumpAndSettle();
      expect(find.text('Dùng giao diện cá nhân hóa'), findsOneWidget);
      expect(find.text('Chế độ hiển thị & Giao diện'), findsOneWidget);
    });
  });
}
