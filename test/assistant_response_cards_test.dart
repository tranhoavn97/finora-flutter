import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/features/ai/assistant_response_body.dart';

void main() {
  testWidgets(
      'web-style metrics and budget progress fit narrow widths and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const Scaffold(
                  body: SingleChildScrollView(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AssistantResponseBody(
                              text:
                                  '## Ngân sách thực tế\n• **Tổng chi:** 12.345.678 ₫\n\n• **Ăn uống:** Đã chi 750.000 ₫ / 600.000 ₫ (125%)\nVượt **150.000 ₫**.\n\n> Theo sổ đã tải.')))))));
      await tester.pump();
      expect(find.byKey(const ValueKey('metric-Tổng chi')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
          tester
              .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator))
              .value,
          1);
      expect(find.text('Đã vượt hạn mức'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
