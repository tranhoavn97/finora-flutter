import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/features/ai/assistant_response_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('BeVietnamPro')..addFont(rootBundle.load('assets/fonts/BeVietnamPro.ttf'))..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'))).load();
  });
  testWidgets(
      'Capture response component in light and dark themes for visual QA',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: 'BeVietnamPro',
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00866A),
                brightness: dark ? Brightness.dark : Brightness.light),
          ),
          home: RepaintBoundary(
              key: key,
              child: Scaffold(
                appBar: AppBar(title: const Text('Trợ lí Finora · GPT')),
                body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Text('✦'),
                              SizedBox(width: 8),
                              Text('Finora · GPT')
                            ]),
                            const Divider(height: 26),
                            const AssistantResponseBody(
                                text:
                                    '## Chi tiêu tháng này\nTổng chi **1.250.000 ₫** trong dữ liệu bạn đã ghi.\n\n- Ăn uống: **500.000 ₫**\n- Đi lại: **250.000 ₫**\n- Các khoản khác: **500.000 ₫**\n\n## Bước tiếp theo\nBạn có thể kiểm tra danh mục ăn uống để tìm những khoản dễ điều chỉnh.'),
                            const SizedBox(height: 12),
                            Text('Dữ liệu kiểm thử giao diện',
                                style: const TextStyle(fontSize: 11)),
                          ]),
                    ))),
              ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
                'artifacts/assistant-response-${dark ? 'dark' : 'light'}-20261030.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
