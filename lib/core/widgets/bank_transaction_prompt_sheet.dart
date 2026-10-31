import 'dart:math' as math;
import 'adaptive_glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/bank_notification_parser.dart';
import '../services/bank_sync_service.dart';
import '../utils/formatters.dart';
import 'bank_icon.dart';
import 'finora_notice.dart';
import 'finora_transaction_success_modal.dart';
import 'premium_widgets.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';

class BankTransactionPromptSheet extends StatefulWidget {
  final ParsedBankTransaction tx;
  final String userId;

  const BankTransactionPromptSheet({
    super.key,
    required this.tx,
    required this.userId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ParsedBankTransaction transaction,
    required String userId,
  }) {
    final screenH = MediaQuery.sizeOf(context).height;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          math.max(bottomSafe, 12.0) + 8.0,
        ),
        constraints: BoxConstraints(
          maxHeight: math.min(screenH * 0.72, 580.0),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BankTransactionPromptSheet(tx: transaction, userId: userId),
        ),
      ),
    );
  }

  @override
  State<BankTransactionPromptSheet> createState() =>
      _BankTransactionPromptSheetState();
}

class _BankTransactionPromptSheetState
    extends State<BankTransactionPromptSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _bankCodeCtrl;
  late TextEditingController _noteCtrl;
  late String _selectedType; // 'expense' | 'income' | 'transfer'
  String? _selectedWalletId;
  String? _selectedToWalletId;
  String? _selectedCategoryId;
  bool _saving = false;
  bool _savedAwaitingAck = false;
  String? _validationError;
  bool _showRawText = true;

  String _catKey(Category c) =>
      c.id.trim().isNotEmpty ? c.id.trim() : c.name.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.tx.type == 'transfer'
        ? 'transfer'
        : (widget.tx.type == 'income' ? 'income' : 'expense');
    _amountCtrl = TextEditingController(
      text: widget.tx.amount > 0
          ? NumberFormat.decimalPattern('vi_VN').format(widget.tx.amount)
          : '',
    );
    // Mã giao dịch chính lấy trực tiếp từ thông báo ngân hàng
    final mainBankRef = widget.tx.transactionCode.trim();
    _bankCodeCtrl = TextEditingController(text: mainBankRef);
    // Ghi chú riêng của người dùng tách biệt hoàn toàn
    _noteCtrl = TextEditingController(text: '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletProv = context.read<WalletProvider?>();
      final moreProv = context.read<MoreProvider?>();
      if (widget.userId.isNotEmpty) {
        if (walletProv != null && walletProv.wallets.isEmpty) {
          walletProv.load(widget.userId);
        }
        if (moreProv != null && moreProv.categories.isEmpty) {
          moreProv.load(widget.userId);
        }
      }
      _autoMatchSelections();
    });
  }

  void _autoMatchSelections() {
    final walletProv = context.read<WalletProvider?>();
    final txProv = context.read<TransactionProvider?>();
    final moreProv = context.read<MoreProvider?>();
    final fromWalletProv = walletProv?.wallets ?? const <Wallet>[];
    final fromTxProv = txProv?.wallets ?? const <Wallet>[];
    final wallets = fromWalletProv.isNotEmpty ? fromWalletProv : fromTxProv;
    final categories = _availableCategories(txProv, moreProv);

    // 1. Auto-match source wallet by bank name / code
    if (wallets.isNotEmpty && _selectedWalletId == null) {
      final matched = wallets.where((w) {
        final nameLower = w.name.toLowerCase();
        final bankLower = widget.tx.bankName.toLowerCase();
        final codeLower = widget.tx.bankCode.toLowerCase();
        final wBankCode = (w.bankCode ?? '').toLowerCase();
        final wBankName = (w.bankName ?? '').toLowerCase();
        return nameLower.contains(bankLower) ||
            nameLower.contains(codeLower) ||
            wBankCode.contains(codeLower) ||
            wBankName.contains(bankLower);
      }).toList();
      _selectedWalletId =
          matched.isNotEmpty ? matched.first.id : wallets.first.id;
    }

    // 2. Auto-match destination wallet if internal transfer or credit card payment
    if (wallets.length > 1 && _selectedToWalletId == null) {
      if (widget.tx.matchedTransferBankCode != null) {
        final targetCode = widget.tx.matchedTransferBankCode!.toLowerCase();
        final targetName =
            (widget.tx.matchedTransferBankName ?? '').toLowerCase();
        final matchedDest = wallets.where((w) {
          if (w.id == _selectedWalletId) return false;
          final n = w.name.toLowerCase();
          final bc = (w.bankCode ?? '').toLowerCase();
          final bn = (w.bankName ?? '').toLowerCase();
          return n.contains(targetCode) ||
              (targetName.isNotEmpty && n.contains(targetName)) ||
              bc.contains(targetCode) ||
              (targetName.isNotEmpty && bn.contains(targetName));
        }).toList();
        if (matchedDest.isNotEmpty) {
          _selectedToWalletId = matchedDest.first.id;
        }
      } else if (widget.tx.isCreditCardPayment) {
        final creditWallets = wallets.where((w) {
          if (w.id == _selectedWalletId) return false;
          final n = w.name.toLowerCase();
          return w.type == 'credit' ||
              n.contains('tín dụng') ||
              n.contains('tin dung') ||
              n.contains('credit');
        }).toList();
        if (creditWallets.isNotEmpty) {
          _selectedToWalletId = creditWallets.first.id;
        }
      }
      _selectedToWalletId ??= wallets
          .firstWhere(
            (w) => w.id != _selectedWalletId,
            orElse: () => wallets.first,
          )
          .id;
    }

    // 3. Auto-match category by keywords and type
    _syncCategoryForCurrentType(categories);
    if (mounted) setState(() {});
  }

  List<Category> _availableCategories(
      TransactionProvider? txProv, MoreProvider? moreProv) {
    final fromMore = moreProv?.categories ?? const <Category>[];
    final fromTx = txProv?.categories ?? const <Category>[];
    final merged = <Category>[];
    final seenNames = <String>{};
    final seenIds = <String>{};

    for (final c in [...fromMore, ...fromTx, ...Category.defaults]) {
      if (c.isArchived || c.categoryGroup == 'merchant') continue;
      final idKey = c.id.trim().toLowerCase();
      final nameKey = c.name.trim().toLowerCase();
      if ((idKey.isNotEmpty && seenIds.contains(idKey)) ||
          (nameKey.isNotEmpty && seenNames.contains(nameKey))) {
        continue;
      }
      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (nameKey.isNotEmpty) seenNames.add(nameKey);
      merged.add(c);
    }
    return merged;
  }

  List<Category> _categoriesForType(List<Category> allCategories, String type) {
    if (type == 'income') {
      final incomeList =
          allCategories.where((c) => c.categoryGroup == 'income').toList();
      return incomeList.isNotEmpty ? incomeList : allCategories;
    }
    final expenseList = allCategories
        .where((c) =>
            c.categoryGroup != 'income' &&
            c.categoryGroup != 'merchant' &&
            c.categoryGroup != 'investment')
        .toList();
    return expenseList.isNotEmpty ? expenseList : allCategories;
  }

  void _syncCategoryForCurrentType(List<Category> allCategories) {
    if (allCategories.isEmpty) return;
    final pool = _categoriesForType(allCategories, _selectedType);

    if (_selectedCategoryId != null &&
        pool.any((c) => _catKey(c) == _selectedCategoryId)) {
      return;
    }

    final textLower =
        '${widget.tx.note} ${_bankCodeCtrl.text} ${_noteCtrl.text}'
            .toLowerCase();
    for (final cat in pool) {
      final catLower = cat.name.toLowerCase();
      if (textLower.contains(catLower)) {
        _selectedCategoryId = _catKey(cat);
        return;
      }
      if (_selectedType != 'income') {
        if ((textLower.contains('grab') ||
                textLower.contains('xanh sm') ||
                textLower.contains('be ') ||
                textLower.contains('xang')) &&
            (catLower.contains('di chuyển') ||
                catLower.contains('đi lại') ||
                catLower.contains('xe'))) {
          _selectedCategoryId = _catKey(cat);
          return;
        }
        if ((textLower.contains('coffee') ||
                textLower.contains('highlands') ||
                textLower.contains('phúc long') ||
                textLower.contains('ăn') ||
                textLower.contains('com') ||
                textLower.contains('bun') ||
                textLower.contains('pho')) &&
            (catLower.contains('ăn') || catLower.contains('cafe'))) {
          _selectedCategoryId = _catKey(cat);
          return;
        }
        if ((textLower.contains('shopee') ||
                textLower.contains('lazada') ||
                textLower.contains('tiktok') ||
                textLower.contains('mua')) &&
            catLower.contains('mua sắm')) {
          _selectedCategoryId = _catKey(cat);
          return;
        }
      } else {
        if ((textLower.contains('luong') ||
                textLower.contains('lương') ||
                textLower.contains('salary')) &&
            catLower.contains('lương')) {
          _selectedCategoryId = _catKey(cat);
          return;
        }
        if ((textLower.contains('thuong') || textLower.contains('thưởng')) &&
            catLower.contains('thưởng')) {
          _selectedCategoryId = _catKey(cat);
          return;
        }
      }
    }
    _selectedCategoryId = _catKey(pool.first);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankCodeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWallet(
    List<Wallet> wallets,
    bool isDark, {
    bool isDestination = false,
  }) async {
    if (wallets.isEmpty) return;
    HapticFeedback.selectionClick();
    final currentId = isDestination ? _selectedToWalletId : _selectedWalletId;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AdaptiveGlassSurface(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDestination ? 'Chọn ví nhận tiền' : 'Chọn ví giao dịch',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Số dư ví sẽ được tự động cập nhật theo giao dịch này',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final w = wallets[index];
                      final selected = w.id == currentId;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(ctx, w.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF059669)
                                      .withValues(alpha: isDark ? 0.22 : 0.10)
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF059669)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE2E8F0)),
                                width: selected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                AdaptiveGlassSurface(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: BankIcon(
                                      bankCode: w.bankCode ?? w.type,
                                      bankName: w.bankName ?? w.name,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatVND(w.balance),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF059669),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        if (isDestination) {
          _selectedToWalletId = chosen;
        } else {
          _selectedWalletId = chosen;
        }
      });
    }
  }

  Future<void> _pickCategory(List<Category> categories, bool isDark) async {
    if (categories.isEmpty) return;
    HapticFeedback.selectionClick();
    final isIncome = _selectedType == 'income';
    final accent = isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AdaptiveGlassSurface(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.68,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isIncome
                      ? 'Chọn danh mục Thu nhập'
                      : 'Chọn danh mục Chi tiêu',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn đúng danh mục giúp báo cáo phân tích chính xác hơn',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.65,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, index) {
                      final c = categories[index];
                      final key = _catKey(c);
                      final selected = key == _selectedCategoryId;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.pop(ctx, key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(
                                      alpha: isDark ? 0.22 : 0.10)
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? accent
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE2E8F0)),
                                width: selected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CategoryIconBadge(
                                  icon: c.icon,
                                  categoryName: c.name,
                                  colorHex: c.color,
                                  size: 34,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() => _selectedCategoryId = chosen);
    }
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;
    if (_savedAwaitingAck) {
      setState(() => _saving = true);
      try {
        await BankSyncService().acknowledge(widget.tx.rawId);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    final rawAmount =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (rawAmount <= 0) return;

    final txProv = context.read<TransactionProvider>();
    final walletProv = context.read<WalletProvider?>();
    final moreProv = context.read<MoreProvider?>();
    final fromWalletProv = walletProv?.wallets ?? const <Wallet>[];
    final wallets = fromWalletProv.isNotEmpty ? fromWalletProv : txProv.wallets;
    final allCategories = _availableCategories(txProv, moreProv);
    final categories = _categoriesForType(allCategories, _selectedType);

    final wallet = wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
    final destWallet = _selectedType == 'transfer'
        ? wallets.where((w) => w.id == _selectedToWalletId).firstOrNull
        : null;
    final category = categories
            .where((c) => _catKey(c) == _selectedCategoryId)
            .firstOrNull ??
        allCategories
            .where((c) => _catKey(c) == _selectedCategoryId)
            .firstOrNull;

    if (wallet == null || (_selectedType != 'transfer' && category == null)) {
      setState(() {
        _validationError = 'Chọn ví và danh mục thật trước khi lưu.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _validationError = null;
    });
    try {
      final mainBankCode = _bankCodeCtrl.text.trim();
      final userNote = capitalizeFirstLetter(_noteCtrl.text.trim());
      final resolvedCategoryName = _selectedType == 'transfer'
          ? (widget.tx.isCreditCardPayment
              ? 'Trả thẻ tín dụng'
              : 'Chuyển khoản nội bộ')
          : category!.name;

      final newTx = TransactionModel(
        id: 'bank_${widget.tx.rawId.isNotEmpty ? widget.tx.rawId : widget.tx.timestamp.millisecondsSinceEpoch}',
        userId: widget.userId,
        type: _selectedType,
        amount: rawAmount,
        categoryId: _selectedType == 'transfer'
            ? (widget.tx.isCreditCardPayment
                ? 'tra_the_tin_dung'
                : 'chuyen_khoan')
            : category!.id,
        categoryName: resolvedCategoryName,
        categoryIcon:
            _selectedType == 'transfer' ? 'arrow-right-left' : category!.icon,
        categoryColor:
            _selectedType == 'transfer' ? '#0284C7' : category!.color,
        walletId: wallet.id,
        walletName: wallet.name,
        toWalletId: destWallet?.id,
        toWalletName: destWallet?.name ?? widget.tx.matchedTransferBankName,
        owner: wallet.owner,
        ownerName: wallet.ownerName,
        toOwner: destWallet?.owner,
        merchantName: widget.tx.suggestedMerchant,
        date: widget.tx.timestamp.millisecondsSinceEpoch,
        note: userNote.isNotEmpty ? userNote : resolvedCategoryName,
        bankTransactionCode: mainBankCode,
        rawBankNotification: widget.tx.rawNotificationText.isNotEmpty
            ? widget.tx.rawNotificationText
            : widget.tx.note,
        createdAt: widget.tx.timestamp.millisecondsSinceEpoch,
      );

      await txProv.createTransaction(widget.userId, newTx);
      setState(() => _savedAwaitingAck = true);
      try {
        await BankSyncService().acknowledge(widget.tx.rawId);
        if (!mounted) return;
        await FinoraTransactionSuccessModal.show(
          context,
          transaction: newTx,
          walletName: wallet.name,
          destinationWalletName: destWallet?.name,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (_) {
        // Keep _savedAwaitingAck = true so user can tap 'Hoàn tất' to retry acknowledge
      }
    } catch (_) {
      if (!mounted) return;
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa lưu được giao dịch. Thông báo vẫn nằm trong hộp chờ.',
          ),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProv = context.watch<WalletProvider?>();
    final txProv = context.watch<TransactionProvider?>();
    final moreProv = context.watch<MoreProvider?>();

    final fromWalletProv = walletProv?.wallets ?? const <Wallet>[];
    final fromTxWallets = txProv?.wallets ?? const <Wallet>[];
    final wallets = fromWalletProv.isNotEmpty ? fromWalletProv : fromTxWallets;
    final allCategories = _availableCategories(txProv, moreProv);
    final categories = _categoriesForType(allCategories, _selectedType);

    if (wallets.isNotEmpty &&
        (_selectedWalletId == null ||
            !wallets.any((w) => w.id == _selectedWalletId))) {
      _selectedWalletId = wallets.first.id;
    }
    if (wallets.isNotEmpty &&
        (_selectedToWalletId == null ||
            !wallets.any((w) => w.id == _selectedToWalletId))) {
      _selectedToWalletId = wallets
          .firstWhere(
            (w) => w.id != _selectedWalletId,
            orElse: () => wallets.first,
          )
          .id;
    }
    if (categories.isNotEmpty &&
        (_selectedCategoryId == null ||
            !categories.any((c) => _catKey(c) == _selectedCategoryId))) {
      _selectedCategoryId = _catKey(categories.first);
    }

    final selectedWallet =
        wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
    final selectedDestWallet =
        wallets.where((w) => w.id == _selectedToWalletId).firstOrNull;
    final selectedCategory =
        categories.where((c) => _catKey(c) == _selectedCategoryId).firstOrNull;

    final isIncome = _selectedType == 'income';
    final isTransfer = _selectedType == 'transfer';
    final accentColor = isTransfer
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48));
    final timeStr =
        DateFormat('HH:mm    -    dd/MM/yyyy').format(widget.tx.timestamp);
    final acct = widget.tx.accountNumber?.trim() ?? '';

    return AdaptiveGlassSurface(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            math.max(MediaQuery.paddingOf(context).bottom, 14.0) +
            8.0,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.38 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Bank Source Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: BankIcon(
                      bankCode: widget.tx.bankCode,
                      bankName: widget.tx.bankName,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.tx.isCreditCardPayment
                                  ? 'TRẢ THẺ TÍN DỤNG'
                                  : (widget.tx.isTransfer
                                      ? 'CHUYỂN KHOẢN CÙNG MÁY'
                                      : 'TỰ ĐỘNG BÓC TÁCH'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (widget.tx.suggestedMerchant != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.tx.suggestedMerchant!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.tx.bankName}${acct.isNotEmpty ? " • TK $acct" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xem nội dung thông báo gốc',
                  onPressed: () => setState(() => _showRawText = !_showRawText),
                  icon: Icon(
                    _showRawText
                        ? Icons.expand_less_rounded
                        : Icons.receipt_long_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            // Centered Transaction Time Pill
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      timeStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showRawText &&
                (widget.tx.rawNotificationText.isNotEmpty ||
                    widget.tx.note.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SelectableText(
                  widget.tx.rawNotificationText.isNotEmpty
                      ? widget.tx.rawNotificationText
                      : widget.tx.note,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 2. Expense / Income / Transfer 3-Way Pill Switcher
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _buildTypeTab(
                    label: 'Chi tiêu',
                    typeValue: 'expense',
                    activeColor: const Color(0xFFE11D48),
                    allCategories: allCategories,
                    isDark: isDark,
                  ),
                  _buildTypeTab(
                    label: 'Thu nhập',
                    typeValue: 'income',
                    activeColor: const Color(0xFF059669),
                    allCategories: allCategories,
                    isDark: isDark,
                  ),
                  _buildTypeTab(
                    label: 'Chuyển khoản',
                    typeValue: 'transfer',
                    activeColor: const Color(0xFF0284C7),
                    allCategories: allCategories,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Amount Display & Editor Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.18),
                    ),
                    child: Center(
                      child: Text(
                        isTransfer ? '⇄' : (isIncome ? '+' : '-'),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTransfer
                              ? 'Số tiền chuyển khoản / trả thẻ'
                              : (isIncome
                                  ? 'Số tiền thu vào'
                                  : 'Số tiền chi ra'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [
                            DotSeparatorTextInputFormatter(),
                          ],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: -0.4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập số tiền...',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: accentColor.withValues(alpha: 0.45),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(top: 2),
                            suffixText: 'đ',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. Custom Bento Selector Cards for Wallet & Category (or Source -> Dest Wallet)
            Row(
              children: [
                // Source Wallet Bento Picker Card
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 5),
                        child: Text(
                          isTransfer
                              ? 'Từ ví chuyển'
                              : (isIncome ? 'Ví nhận tiền' : 'Ví thanh toán'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _pickWallet(wallets, isDark),
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                AdaptiveGlassSurface(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: BankIcon(
                                      bankCode: selectedWallet?.bankCode ??
                                          selectedWallet?.type ??
                                          widget.tx.bankCode,
                                      bankName: selectedWallet?.bankName ??
                                          selectedWallet?.name ??
                                          widget.tx.bankName,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedWallet?.name ??
                                            widget.tx.bankName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        selectedWallet != null
                                            ? formatVND(selectedWallet.balance)
                                            : 'Chạm để chọn ví',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Destination Wallet (if transfer) OR Category Bento Picker Card
                Expanded(
                  child: isTransfer
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 5),
                              child: Text(
                                widget.tx.isCreditCardPayment
                                    ? 'Thẻ / Ví nhận'
                                    : 'Đến ví nhận',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _pickWallet(
                                  wallets,
                                  isDark,
                                  isDestination: true,
                                ),
                                child: Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AdaptiveGlassSurface(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.10)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Center(
                                          child: BankIcon(
                                            bankCode: selectedDestWallet
                                                    ?.bankCode ??
                                                selectedDestWallet?.type ??
                                                (widget.tx
                                                        .matchedTransferBankCode ??
                                                    'bank'),
                                            bankName: selectedDestWallet
                                                    ?.bankName ??
                                                selectedDestWallet?.name ??
                                                (widget.tx
                                                        .matchedTransferBankName ??
                                                    'Ví nhận'),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedDestWallet?.name ??
                                                  (widget.tx
                                                          .matchedTransferBankName ??
                                                      'Chọn ví nhận'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              selectedDestWallet != null
                                                  ? formatVND(selectedDestWallet
                                                      .balance)
                                                  : 'Chạm để chọn ví',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 5),
                              child: Text(
                                'Danh mục',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _pickCategory(categories, isDark),
                                child: Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CategoryIconBadge(
                                        icon:
                                            selectedCategory?.icon ?? 'wallet',
                                        categoryName: selectedCategory?.name ??
                                            (isIncome
                                                ? 'Thu nhập'
                                                : 'Chi tiêu'),
                                        colorHex: selectedCategory?.color ??
                                            (isIncome ? '#10B981' : '#EF4444'),
                                        size: 36,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedCategory?.name ??
                                                  (isIncome
                                                      ? 'Thu nhập khác'
                                                      : 'Chi tiêu khác'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              isIncome
                                                  ? 'Khoản thu'
                                                  : 'Khoản chi',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_validationError != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ],

            // Accessible Form Field Bindings for Programmatic & Automated Selection
            SizedBox(
              height: 24,
              child: Opacity(
                opacity: 0.01,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue:
                            wallets.any((w) => w.id == _selectedWalletId)
                                ? _selectedWalletId
                                : null,
                        decoration:
                            const InputDecoration.collapsed(hintText: ''),
                        items: wallets
                            .map(
                              (w) => DropdownMenuItem<String>(
                                value: w.id,
                                child: Text(
                                  w.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedWalletId = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: categories
                                .any((c) => _catKey(c) == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration:
                            const InputDecoration.collapsed(hintText: ''),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: _catKey(c),
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedCategoryId = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4b. Quick Category Chips (when not transfer)
            if (!isTransfer && categories.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Chọn nhanh danh mục',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _pickCategory(categories, isDark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem tất cả (${categories.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final cat = categories[idx];
                    final key = _catKey(cat);
                    final isSelected = key == _selectedCategoryId;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategoryId = key);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(
                                    alpha: isDark ? 0.24 : 0.12)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryIconBadge(
                                icon: cat.icon,
                                categoryName: cat.name,
                                colorHex: cat.color,
                                size: 28,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? accentColor
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 5. Mã giao dịch chính (Gán trực tiếp từ thông báo ngân hàng)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.28 : 0.18),
                ),
              ),
              child: TextField(
                controller: _bankCodeCtrl,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Mã giao dịch chính (Từ thông báo Ngân hàng)',
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  prefixIcon: Icon(
                    Icons.tag_rounded,
                    size: 19,
                    color: accentColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 6. Ghi chú riêng của người dùng (Tự động viết hoa chữ đầu)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: const [
                  FinoraCapitalizeFirstFormatter(),
                ],
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Ghi chú riêng (Tùy chọn · Tự viết hoa chữ đầu)',
                  hintText: 'Ví dụ: Ăn trưa cùng đồng nghiệp...',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 7. Action Buttons Row (Standardized Pill Shape)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await BankSyncService()
                                  .acknowledge(widget.tx.rawId);
                              if (mounted) Navigator.of(context).pop(false);
                            } catch (_) {
                              if (mounted)
                                setState(() {
                                  _saving = false;
                                  _validationError =
                                      'Chưa thể bỏ qua. Thông báo vẫn được giữ để thử lại.';
                                });
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveTransaction,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _saving
                          ? 'Đang lưu...'
                          : (_savedAwaitingAck
                              ? 'Hoàn tất'
                              : 'Xác nhận ghi vào sổ'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
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

  Widget _buildTypeTab({
    required String label,
    required String typeValue,
    required Color activeColor,
    required List<Category> allCategories,
    required bool isDark,
  }) {
    final selected = _selectedType == typeValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedType == typeValue) return;
          HapticFeedback.selectionClick();
          setState(() {
            _selectedType = typeValue;
            _syncCategoryForCurrentType(allCategories);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
