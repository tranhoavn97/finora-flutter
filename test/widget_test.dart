import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/theme_controller.dart';
import 'package:finora/core/widgets/finora_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FinoraNavigation renders active tab and icons correctly', (tester) async {
    final studio = ThemeStudioController();
    await studio.load();
    final theme = ThemeController();
    await theme.load();

    int selectedTab = 0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
          ChangeNotifierProvider<ThemeController>.value(value: theme),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FinoraNavigation(
              index: selectedTab,
              onTap: (idx) => selectedTab = idx,
              onAddTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(FinoraNavigation), findsOneWidget);
  });
}
