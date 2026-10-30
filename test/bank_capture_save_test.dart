import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/widgets/bank_transaction_prompt_sheet.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/state/transaction_provider.dart';

class BankLedger extends TransactionProvider {
  final writes = <TransactionModel>[];
  Completer<void>? gate;
  BankLedger({bool empty = false}) {
    if (!empty) {
      wallets = const [
        Wallet(
            id: 'actual-wallet',
            name: 'Ví thực',
            owner: 'wife',
            ownerName: 'Vợ')
      ];
      categories = const [
        Category(
            id: 'actual-category', name: 'Chi khác', categoryGroup: 'expense')
      ];
    }
  }
  @override
  Future<void> createTransaction(String userId, TransactionModel tx) async {
    writes.add(tx);
    if (gate != null) await gate!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tx = ParsedBankTransaction(
      rawId: 'bank-persistent-event',
      packageName: 'com.bank',
      bankCode: 'bank',
      bankName: 'Ngân hàng',
      amount: 50000,
      type: 'expense',
      note: 'Chi tiêu',
      suggestedCategoryName: 'Khác',
      suggestedCategoryIcon: 'wallet',
      timestamp: DateTime(2026, 10, 30));
  Future<void> mount(WidgetTester tester, BankLedger ledger) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<TransactionProvider>.value(
        value: ledger,
        child: MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => BankTransactionPromptSheet.show(
                            context,
                            transaction: tx,
                            userId: 'test'),
                        child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Empty account never writes a fake default wallet and does not crash',
      (tester) async {
    final ledger = BankLedger(empty: true);
    await mount(tester, ledger);
    await tester.tap(find.text('Xác nhận ghi vào sổ'));
    await tester.pump();
    expect(ledger.writes, isEmpty);
    expect(
        find.text('Chọn ví và danh mục thật trước khi lưu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Only acknowledges after successful save and retries ack without writing again',
      (tester) async {
    var acks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.finora/bank_sync'),
            (call) async {
      if (call.method == 'acknowledgeNotifications') {
        acks++;
        return acks > 1;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.finora/bank_sync'), null));
    final ledger = BankLedger()..gate = Completer<void>();
    await mount(tester, ledger);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ví thực').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chi khác').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận ghi vào sổ'));
    await tester.pump();
    expect(acks, 0);
    expect(ledger.writes.single.owner, 'wife');
    expect(ledger.writes.single.id, startsWith('bank_'));
    ledger.gate!.complete();
    await tester.pumpAndSettle();
    expect(acks, 1);
    expect(find.text('Hoàn tất'), findsOneWidget);
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();
    expect(acks, 2);
    expect(ledger.writes, hasLength(1));
    expect(find.byType(BankTransactionPromptSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
