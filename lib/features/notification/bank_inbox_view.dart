import 'dart:async';
import '../../core/widgets/adaptive_glass_surface.dart';
import '../../core/widgets/finora_notice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/bank_notification_cloud_sync.dart';
import '../../core/services/bank_notification_parser.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';

class BankInboxView extends StatefulWidget {
  final String userId;
  final double? topPadding;
  const BankInboxView({super.key, required this.userId, this.topPadding});

  @override
  State<BankInboxView> createState() => _BankInboxViewState();
}

class _BankInboxViewState extends State<BankInboxView>
    with WidgetsBindingObserver {
  final _bank = BankSyncService();
  bool? _granted;
  bool _postNotifGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bank.bindUser(widget.userId));
    _refresh();
  }

  @override
  void didUpdateWidget(covariant BankInboxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      unawaited(_bank.bindUser(widget.userId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final granted = await _bank.isPermissionGranted();
    final postGranted = await _bank.isPostNotificationsGranted();
    await _bank.reconnect();
    if (mounted) {
      setState(() {
        _granted = granted;
        _postNotifGranted = !_bank.supported || postGranted;
      });
    }
  }

  Future<void> _review(ParsedBankTransaction tx) async {
    await BankTransactionPromptSheet.show(
      context,
      transaction: tx,
      userId: widget.userId,
    );
  }

  Wallet? _matchWalletForQuickSave(
    List<Wallet> wallets,
    ParsedBankTransaction tx,
  ) {
    if (wallets.isEmpty) return null;
    if (wallets.length == 1) return wallets.first;

    // 1. Khớp đuôi số tài khoản nếu có
    final notifAcct = tx.accountNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (notifAcct.length >= 3) {
      final acctMatches = wallets.where((w) {
        final wAcct = (w.accountNumber ?? '').replaceAll(RegExp(r'\D'), '');
        return wAcct.isNotEmpty &&
            (wAcct.endsWith(notifAcct) || notifAcct.endsWith(wAcct));
      }).toList();
      if (acctMatches.length == 1) return acctMatches.first;
    }

    // 2. Khớp theo mã thương hiệu chuẩn BankIconRegistry
    final txBrand =
        BankIconRegistry.resolve(tx.bankCode, bankName: tx.bankName);
    if (txBrand.code != 'cash') {
      final brandMatches = wallets.where((w) {
        final wBrand = BankIconRegistry.resolve(
          w.bankCode,
          bankName: w.bankName ?? w.name,
        );
        return wBrand.code == txBrand.code;
      }).toList();
      if (brandMatches.length == 1) return brandMatches.first;
    }

    // 3. Khớp theo tên ngân hàng trực tiếp
    final bankNorm = tx.bankName.trim().toLowerCase();
    final codeNorm = tx.bankCode.trim().toLowerCase();
    final nameMatches = wallets.where((w) {
      final wn = w.name.trim().toLowerCase();
      return (bankNorm.isNotEmpty &&
              (wn.contains(bankNorm) || bankNorm.contains(wn))) ||
          (codeNorm.isNotEmpty && wn.contains(codeNorm));
    }).toList();
    if (nameMatches.length == 1) return nameMatches.first;
    return null;
  }

  Future<void> _quickSave(ParsedBankTransaction tx) async {
    if (_bank.isAlreadyImported(tx.rawId)) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giao dịch này đã được nhập trước đó.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
      return;
    }
    final txProv = Provider.of<TransactionProvider?>(context, listen: false);
    if (txProv == null || tx.isTransfer) {
      await _review(tx);
      return;
    }
    final wallets = txProv.wallets;
    if (wallets.isEmpty) {
      await _review(tx);
      return;
    }
    final matchedWallet = _matchWalletForQuickSave(wallets, tx);
    if (matchedWallet == null) {
      await _review(tx);
      return;
    }
    final isIncome = tx.type == 'income';
    final categories = txProv.categories
        .where((c) =>
            !c.isArchived &&
            c.categoryGroup == (isIncome ? 'income' : 'expense'))
        .toList();
    final matchedCat = categories.isNotEmpty ? categories.first : null;
    final cleanCode = tx.transactionCode.trim();
    final newTx = TransactionModel(
      id: 'bank_${tx.rawId.isNotEmpty ? tx.rawId : DateTime.now().microsecondsSinceEpoch}',
      userId: widget.userId,
      amount: tx.amount.round(),
      type: isIncome ? 'income' : 'expense',
      categoryId: matchedCat?.id ?? (isIncome ? 'cat_salary' : 'cat_food'),
      categoryName: matchedCat?.name ?? (isIncome ? 'Thu nhập' : 'Ăn uống'),
      categoryIcon: matchedCat?.icon ?? (isIncome ? '💰' : '🍜'),
      categoryColor: matchedCat?.color ?? (isIncome ? '#10B981' : '#F43F5E'),
      categoryGroup: isIncome ? 'income' : 'expense',
      walletId: matchedWallet.id,
      walletName: matchedWallet.name,
      date: tx.timestamp.millisecondsSinceEpoch,
      note: tx.note.trim().isNotEmpty ? tx.note.trim() : tx.bankName,
      bankTransactionCode: cleanCode.isNotEmpty ? cleanCode : null,
      rawBankNotification: tx.rawNotificationText.isNotEmpty
          ? tx.rawNotificationText
          : tx.note,
      owner: matchedWallet.owner,
      ownerName: matchedWallet.ownerName,
    );
    try {
      await txProv.createTransaction(widget.userId, newTx);
      await _bank.markImported(
        tx.rawId,
        transactionId: newTx.id,
        walletId: matchedWallet.id,
        walletName: matchedWallet.name,
        amount: newTx.amount,
        type: newTx.type,
        categoryName: newTx.categoryName,
        fallbackTx: tx,
      );
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ghi nhanh giao dịch vào sổ & đồng bộ lên Web.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        await _review(tx);
      }
    }
  }

  Future<void> _openManualBalanceEntrySheet() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProv = Provider.of<WalletProvider?>(context, listen: false);
    final txProv = Provider.of<TransactionProvider?>(context, listen: false);
    final wallets = (walletProv?.wallets.isNotEmpty == true)
        ? walletProv!.wallets
        : (txProv?.wallets ?? const <Wallet>[]);

    final pasteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var mode = 'paste'; // 'paste' | 'manual'
    var txType = 'expense';
    String? selectedWalletId = wallets.isNotEmpty ? wallets.first.id : null;
    String? errorMsg;

    final result = await showModalBottomSheet<({ParsedBankTransaction tx, bool openReview})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final selectedWallet = wallets
                .where((w) => w.id == selectedWalletId)
                .firstOrNull;
            final previewParsed = mode == 'paste' && pasteCtrl.text.trim().isNotEmpty
                ? BankNotificationParser.parse(
                    rawId: 'preview',
                    packageName: 'manual.bank',
                    title: selectedWallet?.bankName ?? selectedWallet?.name ?? '',
                    text: pasteCtrl.text.trim(),
                  )
                : null;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 18,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nhập / Dán biến động số dư',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Tự động đồng bộ giữa điện thoại và bản Web',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() {
                                    mode = 'paste';
                                    errorMsg = null;
                                  }),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: mode == 'paste'
                                          ? const Color(0xFF059669)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Dán SMS / Thông báo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: mode == 'paste'
                                            ? Colors.white
                                            : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() {
                                    mode = 'manual';
                                    errorMsg = null;
                                  }),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: mode == 'manual'
                                          ? const Color(0xFF059669)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Nhập biến động số dư',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: mode == 'manual'
                                            ? Colors.white
                                            : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (mode == 'paste') ...[
                          TextField(
                            controller: pasteCtrl,
                            maxLines: 4,
                            onChanged: (_) => setSheetState(() => errorMsg = null),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Dán nội dung biến động số dư (VD: NCB TK 1000xxx -150,000 VND. SD khả dụng: 12,450,000 VND. ND: Ăn trưa)...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          if (previewParsed != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.30),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nhận diện: ${previewParsed.bankName} · ${previewParsed.isIncome ? '+' : '-'}${formatVND(previewParsed.amount.round())}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  if (previewParsed.balanceAfter != null)
                                    Text(
                                      'Số dư cuối: ${formatVND(previewParsed.balanceAfter!.round())}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFF047857),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          if (wallets.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              initialValue: selectedWalletId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Ví / Tài khoản ngân hàng',
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: wallets
                                  .map((w) => DropdownMenuItem(
                                        value: w.id,
                                        child: Text(
                                          '${w.name} (${formatVND(w.balance)})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setSheetState(() => selectedWalletId = v),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              for (final opt in const [
                                ('expense', 'Chi tiêu', Color(0xFFE11D48)),
                                ('income', 'Thu nhập', Color(0xFF059669)),
                                ('transfer', 'Chuyển khoản', Color(0xFF0284C7)),
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setSheetState(() => txType = opt.$1),
                                      child: Container(
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: txType == opt.$1
                                              ? opt.$3
                                              : (isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF1F5F9)),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          opt.$2,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: txType == opt.$1
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [
                              DotSeparatorTextInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Số tiền biến động (đ)',
                              hintText: 'Ví dụ: 150.000',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: balanceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [
                              DotSeparatorTextInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Số dư cuối sau giao dịch (đ)',
                              hintText: 'Ví dụ: 12.450.000 (tùy chọn)',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nội dung / Ghi chú',
                              hintText: 'Ví dụ: Ăn trưa, lương tháng...',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                        if (errorMsg != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMsg!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final built = _submitManualEntry(
                                    mode: mode,
                                    pasteText: pasteCtrl.text,
                                    amountText: amountCtrl.text,
                                    balanceText: balanceCtrl.text,
                                    noteText: noteCtrl.text,
                                    txType: txType,
                                    wallet: selectedWallet,
                                    onError: (msg) =>
                                        setSheetState(() => errorMsg = msg),
                                  );
                                  if (built != null) {
                                    Navigator.pop(
                                        ctx, (tx: built, openReview: false));
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Lưu hàng chờ',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final built = _submitManualEntry(
                                    mode: mode,
                                    pasteText: pasteCtrl.text,
                                    amountText: amountCtrl.text,
                                    balanceText: balanceCtrl.text,
                                    noteText: noteCtrl.text,
                                    txType: txType,
                                    wallet: selectedWallet,
                                    onError: (msg) =>
                                        setSheetState(() => errorMsg = msg),
                                  );
                                  if (built != null) {
                                    Navigator.pop(
                                        ctx, (tx: built, openReview: true));
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Ghi sổ ngay',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    pasteCtrl.dispose();
    amountCtrl.dispose();
    balanceCtrl.dispose();
    noteCtrl.dispose();

    if (result != null && mounted) {
      if (result.openReview) {
        await _review(result.tx);
      } else {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào hộp chờ & đồng bộ lên bản Web.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  ParsedBankTransaction? _submitManualEntry({
    required String mode,
    required String pasteText,
    required String amountText,
    required String balanceText,
    required String noteText,
    required String txType,
    required Wallet? wallet,
    required void Function(String) onError,
  }) {
    if (mode == 'paste') {
      final trimmed = pasteText.trim();
      if (trimmed.isEmpty) {
        onError('Vui lòng dán nội dung thông báo số dư ngân hàng.');
        return null;
      }
      final folded = BankNotificationParser.foldVietnamese(trimmed);
      if (folded.contains('otp') ||
          folded.contains('ma xac thuc') ||
          folded.contains('verification code')) {
        onError('Không lưu tin nhắn chứa mã OTP để bảo vệ tài khoản của bạn.');
        return null;
      }
      return _bank.injectManualNotification(
        title: wallet?.bankName ?? wallet?.name ?? '',
        text: trimmed,
      );
    }

    final amount =
        int.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final balDigits = balanceText.replaceAll(RegExp(r'[^0-9]'), '');
    final balanceAfter = balDigits.isNotEmpty ? double.tryParse(balDigits) : null;
    if (amount <= 0) {
      onError('Vui lòng nhập số tiền giao dịch lớn hơn 0.');
      return null;
    }
    final bankName = (wallet?.bankName?.isNotEmpty == true)
        ? wallet!.bankName!
        : (wallet?.name ?? 'Ngân hàng');
    final bankCode = (wallet?.bankCode?.isNotEmpty == true)
        ? wallet!.bankCode!
        : 'bank';
    final note = noteText.trim().isNotEmpty
        ? noteText.trim()
        : (txType == 'income'
            ? 'Thu tiền $bankName'
            : (txType == 'transfer'
                ? 'Chuyển khoản $bankName'
                : 'Chi tiêu $bankName'));
    final rawText =
        '$bankName ${txType == 'income' ? '+' : '-'}${formatVND(amount)}${balanceAfter != null ? ' • Số dư cuối: ${formatVND(balanceAfter.round())}' : ''} • $note';
    return _bank.injectManualNotification(
      title: bankName,
      text: rawText,
      manualAmount: amount.toDouble(),
      manualType: txType,
      manualBalanceAfter: balanceAfter,
      bankCode: bankCode,
      bankName: bankName,
      accountNumber: wallet?.accountNumber,
      manualNote: note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bank,
      builder: (context, _) {
        final pending = _bank.pending;
        final unrecognized = _bank.unrecognized;
        final importedHistory = _bank.importedHistory;
        final totalCount = pending.length + unrecognized.length;

        return RefreshIndicator(
          color: const Color(0xFF059669),
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, widget.topPadding ?? 14, 16, 36),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              if (!kIsWeb &&
                  _bank.supported &&
                  (!_postNotifGranted || _granted == false))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: isDark ? 0.50 : 0.40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: isDark ? 0.10 : 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: isDark ? 0.22 : 0.14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  !_postNotifGranted
                                      ? 'Chưa bật thông báo trên máy'
                                      : 'Chưa bật quyền đọc số dư ngân hàng',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  !_postNotifGranted
                                      ? 'Bật quyền hiển thị để thấy banner thanh trạng thái & số đếm ngoài icon FINORA.'
                                      : 'Cấp quyền đọc thông báo để FINORA tự bắt biến động ngân hàng.',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11.4,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!_postNotifGranted)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  final ok =
                                      await _bank.requestPostNotifications();
                                  if (!ok) {
                                    await _bank.openNotificationSettings();
                                  }
                                  await _bank.updateAppBadge();
                                  await _refresh();
                                },
                                icon: const Icon(
                                    Icons.notifications_on_rounded,
                                    size: 16),
                                label: const Text(
                                  'Bật thông báo & Badge',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          if (!_postNotifGranted && _granted == false)
                            const SizedBox(width: 8),
                          if (_granted == false)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.selectionClick();
                                  await _bank.requestPermission();
                                  await _refresh();
                                },
                                icon: const Icon(Icons.account_balance_rounded,
                                    size: 16),
                                label: const Text(
                                  'Bật đọc số dư',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(
                                      color: Color(0xFF059669)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Unified quick toolbar: Nhập / Dán số dư (đồng bộ Web & ĐT) + Xoá tất cả
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.80)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 15,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totalCount > 0
                            ? 'Đã bóc tách $totalCount biến động'
                            : 'Đồng bộ số dư Web & ĐT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _openManualBalanceEntrySheet,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.24 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Nhập số dư',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              title: const Text('Xoá tất cả giao dịch chờ?'),
                              content: Text(
                                  'Bỏ qua toàn bộ $totalCount biến động số dư đang chờ? Các giao dịch này sẽ không được ghi vào sổ.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Huỷ'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                  ),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Xoá tất cả'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _bank.acknowledgeAll();
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: isDark ? 0.20 : 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFFE11D48),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Xoá tất cả',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFFB7185)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (totalCount == 0 && importedHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.18 : 0.10),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 30,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Không có giao dịch ngân hàng chờ xử lý',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khi ngân hàng hoặc ví điện tử báo biến động số dư, Finora sẽ tự bóc tách Mã GD và đồng bộ lên bản Web để bạn ghi sổ trên mọi thiết bị.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ...pending.map(
                (tx) => _PendingTile(
                  tx: tx,
                  fromWeb: _bank.isFromWeb(tx.rawId),
                  onQuickSave: () => _quickSave(tx),
                  onReview: () => _review(tx),
                  onDismiss: () => _bank.acknowledge(tx.rawId),
                ),
              ),
              if (unrecognized.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thông báo ngân hàng chưa đọc được số tiền (${unrecognized.length})',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...unrecognized.entries.map(
                  (entry) => _UnrecognizedTile(
                    rawId: entry.key,
                    title: entry.value.title,
                    text: entry.value.text,
                    onReview: () => _review(
                      BankNotificationParser.fromUnrecognized(
                        rawId: entry.key,
                        title: entry.value.title,
                        text: entry.value.text,
                      ),
                    ),
                    onAcknowledge: () => _bank.acknowledge(entry.key),
                  ),
                ),
              ],
              if (importedHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đã nhập gần đây (${importedHistory.length})',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...importedHistory.take(15).map(
                      (item) => _ImportedHistoryTile(
                        item: item,
                        onDelete: () => _bank.deleteCloudHistoryItem(item.id),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PendingTile extends StatelessWidget {
  final ParsedBankTransaction tx;
  final bool fromWeb;
  final VoidCallback? onQuickSave;
  final VoidCallback onReview;
  final VoidCallback onDismiss;
  const _PendingTile({
    required this.tx,
    this.fromWeb = false,
    this.onQuickSave,
    required this.onReview,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.isTransfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isTransfer
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48));
    final sign = isTransfer ? '⇄ ' : (isIncome ? '+' : '-');
    final timeStr = DateFormat('HH:mm • dd/MM/yyyy').format(tx.timestamp);
    final acct = tx.accountNumber?.trim() ?? '';
    final txCode =
        tx.transactionCode.trim().isNotEmpty ? tx.transactionCode.trim() : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: AdaptiveGlassSurface(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipOval(
                        child: BankIcon(
                          bankCode: tx.bankCode,
                          bankName: tx.bankName,
                          size: 44,
                          fullBleed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tx.matchedTransferBankName != null
                                      ? '${tx.bankName} → ${tx.matchedTransferBankName}'
                                      : tx.bankName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tx.isCreditCardPayment
                                      ? 'Trả thẻ TD'
                                      : (isTransfer
                                          ? 'CK nội bộ'
                                          : (isIncome
                                              ? 'Thu nhập'
                                              : 'Chi tiêu')),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (acct.isNotEmpty) ...[
                                Text(
                                  'TK $acct',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  timeStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sign${formatVND(tx.amount.round())}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (txCode.isNotEmpty ||
                    tx.balanceAfter != null ||
                    fromWeb) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (fromWeb)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: isDark ? 0.22 : 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.laptop_mac_rounded,
                                  size: 12.5, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Nhập từ Web',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (tx.balanceAfter != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669)
                                .withValues(alpha: isDark ? 0.20 : 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded,
                                  size: 12.5, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                'Số dư cuối: ${formatVND(tx.balanceAfter!.round())}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (txCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color:
                                color.withValues(alpha: isDark ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tag_rounded, size: 13, color: color),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 190),
                                child: Text(
                                  'Mã GD: $txCode',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx.note,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onDismiss();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Bỏ qua',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onQuickSave != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onQuickSave!();
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F6E56)
                                  .withValues(alpha: isDark ? 0.24 : 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF0F6E56)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 15,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF0F6E56),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ghi nhanh',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF0F6E56),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTransfer
                                  ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                                  : (isIncome
                                      ? const [
                                          Color(0xFF059669),
                                          Color(0xFF047857)
                                        ]
                                      : const [
                                          Color(0xFFE11D48),
                                          Color(0xFFBE123C)
                                        ]),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Kiểm tra',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnrecognizedTile extends StatelessWidget {
  final String rawId;
  final String title;
  final String text;
  final VoidCallback onReview;
  final VoidCallback onAcknowledge;
  const _UnrecognizedTile({
    required this.rawId,
    required this.title,
    required this.text,
    required this.onReview,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: AdaptiveGlassSurface(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: ClipOval(
                        child: BankIcon(
                          bankCode: BankNotificationParser.resolveBank(
                            rawId,
                            title,
                            text,
                          ).code,
                          bankName: BankNotificationParser.resolveBank(
                            rawId,
                            title,
                            text,
                          ).name,
                          size: 42,
                          fullBleed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BankNotificationParser.resolveBank(rawId, title, text).code != 'bank'
                                ? BankNotificationParser.resolveBank(rawId, title, text).name
                                : (title.isEmpty ? 'Thông báo ngân hàng' : title),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onAcknowledge();
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            'Bỏ qua',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF047857)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Phân loại',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportedHistoryTile extends StatelessWidget {
  final CloudBankNotification item;
  final VoidCallback onDelete;
  const _ImportedHistoryTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fromWeb = item.importedFrom == 'web';
    final effectiveType = item.importedType ?? item.type;
    final isIncome = effectiveType == 'income';
    final isTransfer = effectiveType == 'transfer';
    final amount = item.importedAmount ?? item.amount.round();
    final sign = isTransfer ? '⇄ ' : (isIncome ? '+' : '-');
    final amountColor = isTransfer
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48));
    final badgeColor =
        fromWeb ? const Color(0xFF2563EB) : const Color(0xFF059669);
    final importedTime = DateTime.fromMillisecondsSinceEpoch(
      item.importedAtMs ?? item.timestampMs,
    );
    final timeStr = DateFormat('HH:mm · dd/MM').format(importedTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdaptiveGlassSurface(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.72)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badgeColor.withValues(alpha: isDark ? 0.34 : 0.24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipOval(
                    child: BankIcon(
                      bankCode: item.bankCode,
                      bankName: item.bankName,
                      size: 36,
                      fullBleed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.importedWalletName?.isNotEmpty == true
                            ? '${item.importedWalletName} • $timeStr'
                            : timeStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${formatVND(amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: amountColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Xoá khỏi lịch sử đồng bộ',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        fromWeb
                            ? Icons.laptop_mac_rounded
                            : Icons.smartphone_rounded,
                        size: 12,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fromWeb
                            ? 'Đã nhập từ bản Web'
                            : 'Đã nhập trên điện thoại',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.syncedBalance && item.syncedBalanceValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669)
                          .withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Đã đồng bộ số dư: ${formatVND(item.syncedBalanceValue!.round())}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
