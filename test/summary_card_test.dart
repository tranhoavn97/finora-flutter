import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/widgets/finora_summary_card.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [288.0, 390.0]) {
      testWidgets('summary fits $width dark=$dark with large balances',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
                body: SizedBox(
                    width: width,
                    child: const FinoraSummaryCard(
                        title: 'NGÂN SÁCH THÁNG 10/2026',
                        amount: 1234567890123,
                        icon: Icons.wallet,
                        accent: Colors.blue,
                        progress: 1.25,
                        subtitle: '125% đã dùng',
                        metrics: [
                          ('Đã chi tiêu', 1543209862653),
                          ('Còn lại', -308641972530)
                        ])))));
        expect(tester.takeException(), isNull);
        expect(
            tester
                .widget<LinearProgressIndicator>(
                    find.byType(LinearProgressIndicator))
                .value,
            1);
      });
    }
  }
  testWidgets('privacy masks every money value', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: FinoraSummaryCard(
                title: 'SỐ DƯ',
                amount: 999999,
                icon: Icons.wallet,
                accent: Colors.blue,
                masked: true,
                metrics: [('Khả dụng', 123456), ('Nợ', 456789)]))));
    expect(find.text('•••••• ₫'), findsNWidgets(3));
    expect(find.textContaining('123'), findsNothing);
  });
}
