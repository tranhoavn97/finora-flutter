import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/widgets/bank_transaction_prompt_sheet.dart';
import 'package:finora/core/widgets/subject_filter_pill.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/assistant_ledger_answers.dart';
import 'package:finora/data/services/finora_nlp_engine.dart';
import 'package:finora/domain/finance/finance_summary.dart';
import 'package:finora/features/wallet/add_wallet_page.dart';

void main() {
  test(
      'Masked bank accounts preserve prefix and suffix, never pick another wallet',
      () {
    expect(
        BankNotificationParser.isWalletAccountMatched('101686666', '10xxx666'),
        isTrue);
    expect(
        BankNotificationParser.isWalletAccountMatched('991686666', '10xxx666'),
        isFalse);
    expect(
        BankNotificationParser.isWalletAccountMatched(
            '99101686666', '101686666'),
        isFalse);
    const wallets = [
      Wallet(
          id: 'h',
          name: 'Chồng MB',
          type: 'bank',
          bankCode: 'mbbank',
          accountNumber: '101686666',
          balance: 29623742),
      Wallet(
          id: 'w', name: 'Vợ MB', type: 'bank', bankCode: 'mbbank', balance: 1),
    ];
    final unknown = BankNotificationParser.parse(
        rawId: 'unknown',
        packageName: 'com.mbmobile',
        title: 'MB Bank',
        text: 'TK 00xxx509|GD: +1VND 22/11/26 01:04|SD: 1VND|ND: Tra lai');
    expect(unknown, isNotNull);
    expect(
        BankTransactionPromptSheet.selectBestWallet(wallets, unknown!), isNull);
    expect(BankTransactionPromptSheet.selectBestWallet([wallets[1]], unknown),
        isNull);
    final known = BankNotificationParser.parse(
        rawId: 'known',
        packageName: 'com.mbmobile',
        title: 'MB Bank',
        text:
            'TK 10xxx666|GD: -24,000VND 23/11/26 16:57|SD: 29,623,742VND|ND: Rau');
    expect(known, isNotNull);
    expect(
        BankTransactionPromptSheet.selectBestWallet(wallets, known!)?.id, 'h');
  });

  group('Savings balance notifications never become wife expenses', () {
    test('Static savings balance notices are never parsed as expenses', () {
      const staticNotices = [
        'Số dư tài khoản tiết kiệm 50.000.000 VND',
        'Số dư tài khoản tiết kiệm - 50,000,000 VND',
        'Số dư tài khoản tiết kiệm 108542480958: 50,000,000 VND',
        'Số dư tài khoản tiết kiệm 108542480958 - 50,000,000 VND',
        'Số dư sổ tiết kiệm 99887766 là 100,000,000 VND',
        'Vietcombank: Số dư TK tiết kiệm 0071000123456 hiện tại 50,000,000 VND',
        'Tài khoản tiết kiệm 108542480958 hiện có 50,000,000 VND',
      ];

      for (final text in staticNotices) {
        expect(
          BankNotificationParser.parse(
            rawId: 'sav_static',
            packageName: 'com.VCB',
            title: 'Vietcombank',
            text: text,
          ),
          isNull,
          reason: 'Static savings balance must not parse as tx: $text',
        );

        final fallback = BankNotificationParser.fromUnrecognized(
          rawId: 'sav_static',
          packageName: 'com.VCB',
          title: 'Vietcombank',
          text: text,
        );
        expect(
          fallback.amount,
          0,
          reason: 'Fallback must keep amount=0 for balance-only notice: $text',
        );
        expect(
          fallback.balanceAfter,
          greaterThanOrEqualTo(50000000),
          reason: 'Ending balance should still be extracted: $text',
        );
      }
    });

    test(
        'Extracts account number from Tài khoản tiết kiệm without mistaking balance',
        () {
      expect(
        BankNotificationParser.extractAccountNumber(
          'Tài khoản tiết kiệm 108542480958: 50,000,000 VND',
        ),
        '108542480958',
      );
      expect(
        BankNotificationParser.extractAccountNumber(
          'Số dư tài khoản tiết kiệm 50.000.000 VND',
        ),
        isNull,
      );
    });

    test('Real savings deposit parses delta and ending balance cleanly', () {
      final parsed = BankNotificationParser.parse(
        rawId: 'sav_tx_1',
        packageName: 'com.ncb.bank',
        title: 'NCB iziMobile',
        text:
            'TK tiết kiệm 108542480958 +5,000,000 VND. Số dư TK tiết kiệm: 55,000,000 VND. ND: Gui tiet kiem',
      );
      expect(parsed, isNotNull);
      expect(parsed!.type, 'income');
      expect(parsed.amount, 5000000);
      expect(parsed.balanceAfter, 55000000);
      expect(parsed.accountNumber, '108542480958');
    });

    test(
        'Wallet selection prefers husband savings wallet over wife bank wallet',
        () {
      final wallets = [
        const Wallet(
          id: 'w_wife_vcb',
          name: 'Vietcombank Vợ',
          type: 'bank',
          bankCode: 'vcb',
          bankName: 'Vietcombank',
          owner: 'wife',
          ownerName: 'Vợ',
          balance: 12000000,
        ),
        const Wallet(
          id: 'w_husband_sav',
          name: 'Tiết kiệm Vietcombank Chồng',
          type: 'saving',
          bankCode: 'vcb',
          bankName: 'Vietcombank',
          accountNumber: '0071000123456',
          owner: 'husband',
          ownerName: 'Chồng',
          balance: 50000000,
        ),
      ];

      final tx = BankNotificationParser.fromUnrecognized(
        rawId: 'sav_1',
        packageName: 'com.VCB',
        title: 'Vietcombank',
        text: 'Số dư tài khoản tiết kiệm của chồng hiện tại 50,000,000 VND',
      );

      final selected = BankTransactionPromptSheet.selectBestWallet(wallets, tx);
      expect(selected?.id, 'w_husband_sav');
    });

    test('Word-boundary member detection never maps "vốn", "với", "vô" to wife',
        () {
      expect(BankNotificationParser.detectMemberHint('Quỹ vốn đầu tư'), isNull);
      expect(BankNotificationParser.detectMemberHint('Tiết kiệm với ngân hàng'),
          isNull);
      expect(
          BankNotificationParser.detectMemberHint('Nạp vô tài khoản'), isNull);
      expect(BankNotificationParser.detectMemberHint('Quỹ tiết kiệm chồng'),
          'husband');
      expect(BankNotificationParser.detectMemberHint('Ví của vợ'), 'wife');

      const jointCapitalWallet = Wallet(
        id: 'w_von',
        name: 'Quỹ vốn dự phòng',
        owner: 'joint',
        ownerName: 'Chung',
      );
      final resolved =
          BankTransactionPromptSheet.resolveOwnerForWallet(jointCapitalWallet);
      expect(resolved.owner, 'joint');
      expect(resolved.ownerName, 'Chung');
    });
  });

  group('Wallet editor, NLP, and member attribution regressions', () {
    test(
        'AddWalletPage owner normalization never flips non-husband wallets to Vợ',
        () {
      expect(AddWalletPage.normalizeWalletOwner('husband', 'Vợ'), 'husband');
      expect(AddWalletPage.ownerLabelFor('husband'), 'Chồng');
      expect(AddWalletPage.normalizeWalletOwner('family', ''), 'joint');
      expect(AddWalletPage.ownerLabelFor('family'), 'Chung');
      expect(AddWalletPage.normalizeWalletOwner('shared', 'Chung'), 'joint');
      expect(AddWalletPage.ownerLabelFor('joint'), 'Chung');
      expect(AddWalletPage.normalizeWalletOwner('Chồng', ''), 'husband');
      expect(AddWalletPage.ownerLabelFor('Chồng'), 'Chồng');
      expect(AddWalletPage.normalizeWalletOwner('wife', 'Vợ'), 'wife');
      expect(AddWalletPage.ownerLabelFor('wife'), 'Vợ');
    });

    test(
        'FinoraNlpEngine detects savings as saving and avoids "vo" substring false positives',
        () {
      expect(
        FinoraNlpEngine.detectTransactionType('Gửi tiết kiệm 5tr vào quỹ vốn'),
        'saving',
      );
      final parsed = FinoraNlpEngine.extractTransactions(
        message: 'Gửi tiết kiệm 5tr với vốn dự phòng',
        categories: const [],
        wallets: const [],
      );
      expect(parsed, hasLength(1));
      expect(parsed.first.type, 'saving');
      expect(parsed.first.owner, isNull);
    });

    test(
        'FinanceScope and AssistantLedgerAnswers exclude savings from expense and respect wallet owner',
        () {
      final now = DateTime(2026, 11, 20);
      const husbandWallet = Wallet(
        id: 'w_h_sav',
        name: 'Tiết kiệm Chồng',
        type: 'saving',
        owner: 'husband',
        ownerName: 'Chồng',
        balance: 50000000,
      );
      const wifeWallet = Wallet(
        id: 'w_w_bank',
        name: 'VCB Vợ',
        type: 'bank',
        owner: 'wife',
        ownerName: 'Vợ',
        balance: 10000000,
      );
      final txs = [
        TransactionModel(
          id: 'tx_sav',
          type: 'saving',
          amount: 50000000,
          walletId: husbandWallet.id,
          walletName: husbandWallet.name,
          date: now.millisecondsSinceEpoch,
        ),
        TransactionModel(
          id: 'tx_exp_h',
          type: 'expense',
          amount: 200000,
          walletId: husbandWallet.id,
          walletName: husbandWallet.name,
          creatorTag: 'Quỹ vốn',
          date: now.millisecondsSinceEpoch,
        ),
        TransactionModel(
          id: 'tx_exp_w',
          type: 'expense',
          amount: 100000,
          walletId: wifeWallet.id,
          walletName: wifeWallet.name,
          date: now.millisecondsSinceEpoch,
        ),
      ];

      final summary = FinanceSummary.from(txs);
      expect(summary.expense, 300000);

      final ans = AssistantLedgerAnswers.answer(
        prompt: 'Vợ và chồng ai chi nhiều hơn tháng này?',
        previous: '',
        transactions: txs,
        wallets: [husbandWallet, wifeWallet],
        categories: const [],
        budgets: const [],
        budgetsReady: true,
        now: now,
      );
      expect(ans.text, contains('200.000'));
      expect(ans.text, contains('100.000'));
      expect(ans.text, isNot(contains('50.000.000')));
    });

    test(
        'OwnerFilter.matchAsset prioritizes explicit wallet owner over stale ownerName',
        () {
      const corruptedWallet = Wallet(
        id: 'w_corrupt',
        name: 'Sổ tiết kiệm',
        type: 'saving',
        owner: 'husband',
        ownerName: 'Vợ',
      );
      const asset = Asset(
        id: 'a1',
        name: 'Sổ tiết kiệm kỳ hạn 12 tháng',
        sourceWalletId: 'w_corrupt',
      );
      expect(
        OwnerFilter.husband
            .matchAsset(asset, walletMap: {'w_corrupt': corruptedWallet}),
        isTrue,
      );
      expect(
        OwnerFilter.wife
            .matchAsset(asset, walletMap: {'w_corrupt': corruptedWallet}),
        isFalse,
      );
    });

    test('Balance sync safety guards prevent cross-spouse wallet overwrite',
        () {
      expect(
        BankNotificationParser.isWalletAccountMatched('108542480958', '480958'),
        isTrue,
      );
      expect(
        BankNotificationParser.isWalletAccountMatched(null, '480958'),
        isFalse,
      );
      expect(
        BankNotificationParser.isWalletAccountMatched('108542480958', '999999'),
        isFalse,
      );

      // Without STK match, auto-sync MUST stay OFF even if balanceAfter is present
      expect(
        BankNotificationParser.shouldAutoEnableBalanceSync(
          walletAccountNumber: null,
          notifAccountNumber: '480958',
          balanceAfter: 50000000,
          currentWalletBalance: 10000000,
          txType: 'expense',
          txAmount: 200000,
        ),
        isFalse,
      );

      // With matching STK AND large jump (e.g. +40M), auto-sync MUST stay OFF
      expect(
        BankNotificationParser.shouldAutoEnableBalanceSync(
          walletAccountNumber: '108542480958',
          notifAccountNumber: '480958',
          balanceAfter: 50000000,
          currentWalletBalance: 10000000,
          txType: 'expense',
          txAmount: 200000,
        ),
        isFalse,
      );

      // With matching STK AND small/exact adjustment, auto-sync IS enabled
      expect(
        BankNotificationParser.shouldAutoEnableBalanceSync(
          walletAccountNumber: '108542480958',
          notifAccountNumber: '480958',
          balanceAfter: 9800000,
          currentWalletBalance: 10000000,
          txType: 'expense',
          txAmount: 200000,
        ),
        isTrue,
      );
    });

    test(
        'Transfer destination wallet selection avoids arbitrary first-wallet fallback when ambiguous',
        () {
      const wallets = [
        Wallet(
          id: 'src_tcb_h',
          name: 'TCB Chồng',
          type: 'bank',
          bankCode: 'tcb',
          owner: 'husband',
          ownerName: 'Chồng',
        ),
        Wallet(
          id: 'dst_mb_w',
          name: 'MB Vợ',
          type: 'bank',
          bankCode: 'mbbank',
          owner: 'wife',
          ownerName: 'Vợ',
        ),
        Wallet(
          id: 'dst_mb_h_sav',
          name: 'Tiết kiệm MB Chồng',
          type: 'saving',
          bankCode: 'mbbank',
          owner: 'husband',
          ownerName: 'Chồng',
        ),
      ];

      final ambiguousTx = BankNotificationParser.fromUnrecognized(
        rawId: 'tr_amb',
        packageName: 'com.tcb',
        title: 'Techcombank',
        text: 'Chuyển khoản 5,000,000 VND',
      );
      expect(
        BankTransactionPromptSheet.selectBestTransferDestination(
          wallets,
          ambiguousTx,
          sourceWalletId: 'src_tcb_h',
        ),
        isNull,
      );

      final twoWalletsOnly = wallets.sublist(0, 2);
      expect(
        BankTransactionPromptSheet.selectBestTransferDestination(
          twoWalletsOnly,
          ambiguousTx,
          sourceWalletId: 'src_tcb_h',
        )?.id,
        'dst_mb_w',
      );
    });
  });
}
