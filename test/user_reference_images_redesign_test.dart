import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:finora/core/widgets/date_filter_modal.dart';
import 'package:finora/core/utils/date_filter.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/transaction/transaction_detail_sheet.dart';
import 'package:finora/state/family_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Reference Images Redesign Tests', () {
    testWidgets('DateFilterModal matches Image 4 options and layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      DateFilterModalResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDateFilterModal(
                    context,
                    currentOption: DateFilterOption.thisMonth,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Image 4 header and options
      expect(find.text('Chọn mốc thời gian'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Hôm qua'), findsOneWidget);
      expect(find.text('Tuần này'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.text('Năm nay'), findsOneWidget);
      expect(find.text('Chọn ngày cụ thể...'), findsOneWidget);

      // Tap 'Hôm nay'
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.option, DateFilterOption.today);
    });

    testWidgets('TransactionDetailSheet matches Image 2 components', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));

      final testTx = TransactionModel(
        id: 'tx_test_1',
        amount: 50000,
        type: 'expense',
        categoryName: 'Cắt tóc / Gội đầu',
        categoryIcon: 'water_drop',
        date: DateTime(2026, 10, 26, 20, 39).millisecondsSinceEpoch,
        walletId: 'w1',
        walletName: 'Chi tiêu Vợ',
        note: 'Cắt tóc / Gội đầu',
        owner: 'wife',
      );

      final testWallet = Wallet(
        id: 'w1',
        name: 'Chi tiêu Vợ',
        type: 'bank',
        balance: 10000000,
        owner: 'wife',
      );

      final txProv = TransactionProvider();
      final walletProv = WalletProvider();
      walletProv.wallets = [testWallet];
      final famProv = FamilyProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
            ChangeNotifierProvider<WalletProvider>.value(value: walletProv),
            ChangeNotifierProvider<FamilyProvider>.value(value: famProv),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showTransactionDetailSheet(
                      context,
                      userId: 'u1',
                      transaction: testTx,
                    );
                  },
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open detail sheet
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      // Verify Image 2 Hero gradient elements
      expect(find.text('TIỀN RA (CHI TIÊU)'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('50.000'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('20:39'), findsOneWidget);
      expect(find.textContaining('26/10/2026'), findsOneWidget);

      // Verify Image 2 Inset card 4 rows
      expect(find.text('Nội dung'), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Tài khoản / Ví'), findsOneWidget);
      expect(find.text('Người ghi chép'), findsOneWidget);

      // Verify Image 2 ♀ Vợ badge
      expect(find.text('♀'), findsOneWidget);
      expect(find.text('Vợ'), findsOneWidget);

      // Verify Image 2 Action buttons: Xóa and Chỉnh sửa
      expect(find.text('Xóa'), findsOneWidget);
      expect(find.text('Chỉnh sửa'), findsOneWidget);
    });

    testWidgets('TransactionDetailSheet displays Mo nguon button for linked transactions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));

      final testTx = TransactionModel(
        id: 'tx_linked_1',
        amount: 2000000,
        type: 'expense',
        categoryName: 'Trả nợ',
        date: DateTime(2026, 10, 26, 20, 39).millisecondsSinceEpoch,
        walletId: 'w1',
        loanId: 'loan_123',
        note: 'Trả khoản vay ngân hàng',
      );

      final txProv = TransactionProvider();
      final walletProv = WalletProvider();
      final famProv = FamilyProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(value: txProv),
            ChangeNotifierProvider<WalletProvider>.value(value: walletProv),
            ChangeNotifierProvider<FamilyProvider>.value(value: famProv),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showTransactionDetailSheet(
                      context,
                      userId: 'u1',
                      transaction: testTx,
                    );
                  },
                  child: const Text('Open Linked Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Linked Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Mở nguồn'), findsOneWidget);
      expect(find.textContaining('Giao dịch liên kết theo dõi Khoản vay / Sổ nợ.'), findsOneWidget);
    });
  });
}
