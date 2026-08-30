import 'package:finora/core/widgets/custom_date_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom date picker renders real selected date and calendar days',
      (tester) async {
    final date = DateTime(2026, 8, 30);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomDatePickerSheet(initialDate: date, onDateSelected: (_) {}),
      ),
    ));

    expect(find.text('30'), findsWidgets);
    expect(find.text('Chủ Nhật, 30/8/2026'), findsOneWidget);
    expect(find.text('Tháng 8, 2026'), findsOneWidget);
    expect(find.text(', //'), findsNothing);
  });
}
