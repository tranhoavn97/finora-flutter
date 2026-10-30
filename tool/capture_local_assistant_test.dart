import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/features/ai/ai_advisor_screen.dart';
import 'package:finora/state/transaction_provider.dart';
import '../test/local_assistant_test.dart' show LocalTestLedger;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(File(
                  'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes))))
        .load();
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
  });
  testWidgets('Capture real local assistant screen with labelled QA data',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      final ledger = LocalTestLedger();
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<TransactionProvider>.value(
          value: ledger,
          child: MaterialApp(
              theme: ThemeData(
                  fontFamily: 'BeVietnamPro',
                  brightness: dark ? Brightness.dark : Brightness.light),
              home: RepaintBoundary(
                  key: key,
                  child: Column(children: [
                    const Expanded(child: AiAdvisorScreen(userId: 'qa-only')),
                    Material(
                        child: SizedBox(
                            height: 24,
                            child: Center(
                                child: Text('Dữ liệu kiểm thử giao diện',
                                    style: TextStyle(fontSize: 10))))),
                  ])))));
      await tester.pumpAndSettle();
      await tester.runAsync(() => precacheImage(
          const AssetImage('assets/mascot/expression-03-focused.png'),
          key.currentContext!));
      await tester.enterText(find.byType(TextField), 'Số dư từng ví');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
                'artifacts/local-assistant-${dark ? 'dark' : 'light'}-20261030.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      ledger.dispose();
    }
  });
}
