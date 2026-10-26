import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/features/wallet/web_wallet_card.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/services/ai_budget_snapshot.dart';

void main() {
  test(
      'AI budget snapshot removes archived and other months and duplicate categories',
      () {
    final rows = AiBudgetSnapshot.build([
      {'id': 'old', 'categoryId': 'food', 'monthKey': '2026-09'},
      {
        'id': 'current',
        'categoryId': 'food',
        'monthKey': '2026-10',
        'limitAmount': 5000000
      },
      {'id': 'duplicate', 'categoryId': 'food', 'monthKey': '2026-10'},
      {
        'id': 'archived',
        'categoryId': 'rent',
        'monthKey': '2026-10',
        'isArchived': true
      },
    ], [
      TransactionModel(
          id: 'tx',
          type: 'expense',
          categoryId: 'food',
          amount: 85000,
          date: DateTime(2026, 10, 10).millisecondsSinceEpoch)
    ], DateTime(2026, 10, 10));
    expect(rows.length, 1);
    expect(rows.first['spent'], 85000);
    expect(rows.first['remainingAmount'], 4915000);
  });
  for (final width in [288.0, 328.0, 390.0]) {
    testWidgets(
        'web card fits mobile width $width and payment needs explicit tap',
        (tester) async {
      var payments = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                      width: width,
                      child: WebWalletCard(
                          wallet: const Wallet(
                              id: 'c',
                              name: 'SLIVER',
                              type: 'credit_card',
                              bankCode: 'tcb',
                              currentDebt: 2529292,
                              creditLimit: 20000000,
                              accountNumber: '1565'),
                          onHistory: () {},
                          onEdit: () {},
                          onDelete: () {},
                          onPay: () {
                            payments++;
                          }))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(payments, 0);
      expect(find.text('Trả nợ thẻ'), findsOneWidget);
      await tester.tap(find.text('Trả nợ thẻ'));
      expect(payments, 1);
    });
  }
  testWidgets('render Android wallet cards for visual review', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 700));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:RepaintBoundary(key:const ValueKey('wallet-preview'),child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
      WebWalletCard(wallet:const Wallet(id:'bank',name:'Tiết Kiệm Chồng',type:'bank',bankCode:'mbbank',balance:45047640,accountNumber:'6666'),onHistory:(){},onEdit:(){},onDelete:(){}),
      WebWalletCard(wallet:const Wallet(id:'credit',name:'SLIVER',type:'credit_card',bankCode:'tcb',currentDebt:2529292,creditLimit:20000000,accountNumber:'1565'),onHistory:(){},onEdit:(){},onDelete:(){},onPay:(){}),
    ]))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    await expectLater(find.byKey(const ValueKey('wallet-preview')),matchesGoldenFile('goldens/web_wallet_cards.png'));
  });

}
