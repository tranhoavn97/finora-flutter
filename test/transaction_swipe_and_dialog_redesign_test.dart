import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:finora/core/widgets/finora_member_filter.dart';
import 'package:finora/core/widgets/finora_swipeable_transaction_card.dart';
import 'package:finora/core/widgets/glass_widgets.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/state/transaction_provider.dart';

void main() {
  group('User Reference Images & Interaction Redesign Verification', () {
    testWidgets('1. showConfirmDeleteDialog renders Luxury Red Squircle Badge & Dual Buttons', (tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await showConfirmDeleteDialog(
                    context: context,
                    title: 'Xóa giao dịch này?',
                    content:
                        'Số dư ví và báo cáo liên quan sẽ được tự động cập nhật lại ngay sau khi xóa.',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check title and content
      expect(find.text('Xóa giao dịch này?'), findsOneWidget);
      expect(
        find.text(
            'Số dư ví và báo cáo liên quan sẽ được tự động cập nhật lại ngay sau khi xóa.'),
        findsOneWidget,
      );

      // Check red squircle delete icon badge
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Check Cancel and Delete buttons
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);

      // Tap 'Hủy'
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(userChoice, isFalse);
    });

    testWidgets('2. FinoraUnifiedMemberPill renders Executive Avatar Badge and Label', (tester) async {
      String? selectedMember;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FinoraUnifiedMemberPill(
                currentMember: 'husband',
                onSelected: (val) => selectedMember = val,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      // Check label
      expect(find.text('Chồng'), findsOneWidget);

      // Check circular avatar face icon and dropdown chevron
      expect(find.byIcon(Icons.face_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap pill to open member sheet
      await tester.tap(find.text('Chồng'));
      await tester.pumpAndSettle();

      // Check bottom sheet options
      expect(find.text('Phân loại theo thành viên'), findsOneWidget);
      expect(find.text('Chỉ riêng Chồng'), findsOneWidget);
      expect(find.text('Chỉ riêng Vợ'), findsOneWidget);

      // Select 'wife'
      await tester.tap(find.text('Chỉ riêng Vợ'));
      await tester.pumpAndSettle();

      expect(selectedMember, 'wife');
    });

    testWidgets('3. FinoraSwipeableTransactionCard supports Swipe Right (Edit) & Long Press', (tester) async {
      bool editCalled = false;

      final tx = TransactionModel(
        id: 'tx-test-001',
        userId: 'user-001',
        amount: 50000,
        type: 'expense',
        date: DateTime.now().millisecondsSinceEpoch,
        note: 'Cà phê sáng',
        categoryName: 'Ăn uống',
        categoryIcon: 'coffee',
        walletName: 'Chi tiêu Chồng',
      );

      final txProvider = TransactionProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: FinoraSwipeableTransactionCard(
                  userId: 'user-001',
                  transaction: tx,
                  onEdit: () async {
                    editCalled = true;
                  },
                  child: Container(
                    height: 60,
                    width: 320,
                    color: Colors.amber,
                    child: const Text('Cà phê sáng 50k'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cà phê sáng 50k'), findsOneWidget);

      // 1. Perform long press to trigger quick action sheet
      await tester.longPress(find.text('Cà phê sáng 50k'));
      await tester.pumpAndSettle();

      // Check quick action bottom sheet
      expect(find.text('Chỉnh sửa giao dịch'), findsOneWidget);
      expect(find.text('Xóa giao dịch này'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);

      // Tap 'Đóng'
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa giao dịch'), findsNothing);

      // 2. Perform full swipe right (which triggers onEdit)
      await tester.drag(find.text('Cà phê sáng 50k'), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });
  });
}
