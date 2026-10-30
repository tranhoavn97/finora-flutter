import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:finora/data/services/ai_service.dart';
import 'package:finora/features/ai/assistant_response_body.dart';

void main() {
  test('GPT request authenticates and only accepts a real OpenAI response',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/openai/chat');
      expect(request.headers['Authorization'], 'Bearer test-id-token');
      expect(jsonDecode(request.body)['message'], 'Ghi ăn trưa 50k');
      return http.Response(
          jsonEncode({
            'source': 'openai',
            'text': '**Bản nháp**',
            'transactions': [
              {
                'type': 'expense',
                'amount': 50000,
                'note': 'Ăn trưa',
                'walletName': null,
                'categoryName': null,
                'date': null
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final reply = await AiService.getAssistantReply(
        prompt: 'Ghi ăn trưa 50k',
        client: client,
        tokenProvider: () async => 'test-id-token');
    expect(reply.transactions.single.amount, 50000);
    expect(reply.transactions.single.walletName, isNull);
    client.close();
  });
  test(
      'Missing key, unconfigured backend and malformed output never become a fake answer',
      () {
    for (final response in [
      http.Response('{"code":"OPENAI_NOT_CONFIGURED"}', 503),
      http.Response('<html>not deployed</html>', 404),
      http.Response('{"text":"sample reply","transactions":[]}', 200),
      http.Response(
          '{"source":"openai","text":"x","transactions":[{"type":"expense","amount":-50}]}',
          200),
    ]) {
      expect(() => AiService.decodeAssistantReply(response),
          throwsA(isA<AssistantException>()));
    }
  });
  testWidgets(
      'Response headings and emphasis render without raw markup at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AssistantResponseBody(
                        text:
                            '## Chi tiêu tháng này\nTổng chi **1.250.000 ₫**.\n\n- Ăn uống: **500.000 ₫**\n- Đây là một dòng dài để kiểm tra xuống dòng trên màn hình nhỏ.'))))));
    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
