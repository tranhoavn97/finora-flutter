import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/theme/app_theme.dart';
import 'package:finora/core/design_system/app_typography.dart';
import 'package:finora/core/design_system/v8/finora_v8_buttons.dart';
import 'package:finora/core/design_system/v8/finora_v8_controls.dart';
import 'package:finora/core/widgets/finora_navigation.dart';
import 'package:finora/core/widgets/finora_search_bar.dart';
import 'package:finora/core/widgets/glass_widgets.dart';
import 'package:finora/core/widgets/premium_widgets.dart' show GradientButton;
import 'package:finora/state/theme_studio_controller.dart';

Widget host(ThemeStudioController studio, Widget child,
        {Brightness brightness = Brightness.light}) =>
    ChangeNotifierProvider.value(
      value: studio,
      child: MaterialApp(
        theme: buildFinoraTheme(brightness, fontFamily: 'BeVietnamPro'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFont = AppTypography.activeFontFamily;
  setUpAll(() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    AppTypography.activeFontFamily = 'BeVietnamPro';
  });
  tearDownAll(() => AppTypography.activeFontFamily = previousFont);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Glass actions preserve enabled and disabled callbacks',
      (tester) async {
    final studio = ThemeStudioController();
    var calls = 0;
    await tester.pumpWidget(host(
        studio,
        Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FinoraAddButton(onPressed: () => calls++),
            const FinoraCircleIconButton(
                icon: Icons.delete, tooltip: 'Disabled'),
            FinoraPillButton(label: 'Open', onTap: () => calls++),
            FinoraButton(onPressed: () => calls++, child: const Text('Save')),
          ],
        ))));
    await tester.tap(find.byType(FinoraAddButton));
    await tester.tap(find.byTooltip('Disabled'));
    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing material preserves search text and filter selection',
      (tester) async {
    final studio = ThemeStudioController();
    var selected = 0;
    var query = '';
    await tester.pumpWidget(host(
        studio,
        StatefulBuilder(
          builder: (context, setState) => Column(children: [
            FinoraSearchBar(onChanged: (value) => query = value),
            FinoraSegmentedTabs(
                labels: const ['All', 'Income', 'Expense'],
                selectedIndex: selected,
                onChanged: (value) => setState(() => selected = value)),
          ]),
        )));
    await tester.enterText(find.byType(TextField), '  cà phê  ');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await studio.setSystemWideLiquidGlass(false);
    await tester.pumpAndSettle();
    expect(query.toLowerCase(), 'cà phê');
    expect(selected, 2);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text.toLowerCase(),
        '  cà phê  ');
    await studio.setSystemWideLiquidGlass(true);
    await tester.pumpAndSettle();
    expect(studio.systemWideLiquidGlass, isTrue);
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Glass dialog scrolls on a small screen and closes',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final studio = ThemeStudioController();
    await tester.pumpWidget(host(
        studio,
        Builder(
            builder: (context) => Center(
                  child: FilledButton(
                      onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => GlassDialog(
                                title: 'Chi tiết giao dịch',
                                child: Column(
                                    children: List.generate(
                                        30,
                                        (index) => Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(
                                                'Giao dịch $index: 150.000 ₫'))))),
                          ),
                      child: const Text('Details')),
                ))));
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Mobile shared surfaces render in ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final studio = ThemeStudioController();
      final key = GlobalKey();
      final dark = brightness == Brightness.dark;
      await tester.pumpWidget(host(
          studio,
          RepaintBoundary(
              key: key,
              child: Stack(
                children: [
                  Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? const [
                                Color(0xFF102F49),
                                Color(0xFF10192E),
                                Color(0xFF312348)
                              ]
                            : const [
                                Color(0xFFB9E5F1),
                                Color(0xFFE9F0FA),
                                Color(0xFFD7C9EC)
                              ]),
                  ))),
                  GlassScaffold(
                    appBar:
                        GlassTopBar(title: 'FINORA', showBack: false, actions: [
                      FinoraAddButton(onPressed: () {}),
                    ]),
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 96, 18, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Bản xem thử · dữ liệu minh hoạ',
                                style: TextStyle(
                                    color: dark
                                        ? Colors.white70
                                        : Colors.black54)),
                            const SizedBox(height: 20),
                            FloatingGlassCard(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tổng tài sản'),
                                const SizedBox(height: 12),
                                const Text('128.450.000 ₫',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                Row(children: [
                                  const Expanded(
                                      child: Text('Thu 18.500.000 ₫')),
                                  FinoraSeeAllButton(onTap: () {}),
                                ]),
                              ],
                            )),
                            const SizedBox(height: 20),
                            FinoraSearchBar(onChanged: (_) {}),
                            const SizedBox(height: 14),
                            FinoraSegmentedTabs(labels: const [
                              'Tất cả',
                              'Thu nhập',
                              'Chi tiêu'
                            ], selectedIndex: 0, onChanged: (_) {}),
                            const SizedBox(height: 20),
                            FloatingGlassCard(
                                child: Column(children: [
                              const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.shopping_bag_outlined),
                                  title: Text('Mua sắm'),
                                  subtitle: Text('Hôm nay · Ví tiền mặt'),
                                  trailing: Text('−250.000 ₫')),
                              const SizedBox(height: 14),
                              GradientButton(
                                  onPressed: () {},
                                  child: const Text('Thêm giao dịch')),
                            ])),
                          ],
                        )),
                  ),
                  Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: FinoraNavigation(
                          index: 0, onTap: (_) {}, onAddTap: () {})),
                ],
              )),
          brightness: brightness));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (Platform.environment['FINORA_CAPTURE_GLASS'] == '1') {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('build/liquid_glass_preview/${brightness.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
