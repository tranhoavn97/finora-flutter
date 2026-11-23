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
import 'finora_modal_scope.dart';
import 'finora_notice.dart';
import 'glass_widgets.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../domain/finance/transaction_member.dart';
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

  static ({String owner, String ownerName}) resolveOwnerForWallet(
          Wallet wallet) =>
      _BankTransactionPromptSheetState.resolveOwnerForWallet(wallet);

  static Wallet? selectBestWallet(
          List<Wallet> wallets, ParsedBankTransaction tx) =>
      _BankTransactionPromptSheetState.selectBestWallet(wallets, tx);

  static Future<bool?> show(
    BuildContext context, {
    required ParsedBankTransaction transaction,
    required String userId,
  }) {
    final screenH = MediaQuery.sizeOf(context).height;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: screenH,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BankTransactionPromptSheet(tx: transaction, userId: userId),
          ),
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
  late TextEditingController _balanceAfterCtrl;
  late TextEditingController _bankCodeCtrl;
  late TextEditingController _noteCtrl;
  late String _selectedType; // 'expense' | 'income' | 'transfer'
  String? _selectedWalletId;
  String? _selectedToWalletId;
  String? _selectedCategoryId;
  String? _selectedMerchantId;
  String? _selectedMerchantName;
  bool _saving = false;
  bool _savedAwaitingAck = false;
  String? _validationError;
  bool _showRawText = true;
  bool _syncBalanceToBank = false;
  ({
    String transactionId,
    String walletId,
    String walletName,
    String? toWalletId,
    String? toWalletName,
    int amount,
    String type,
    String? categoryName,
    bool syncedBalance,
    double? syncedBalanceValue,
  })? _pendingImportMeta;
  VoidCallback? _bankListener;

  static ({String owner, String ownerName}) resolveOwnerForWallet(Wallet wallet) {
    final explicitOwner = wallet.hasExplicitOwner
        ? parseTransactionMember(wallet.owner)
        : null;
    if (explicitOwner == TransactionMember.husband) {
      return (owner: 'husband', ownerName: 'Chồng');
    }
    if (explicitOwner == TransactionMember.wife) {
      return (owner: 'wife', ownerName: 'Vợ');
    }

    final explicitName = wallet.hasExplicitOwnerName
        ? parseTransactionMember(wallet.ownerName)
        : null;
    if (explicitOwner == null && explicitName == TransactionMember.husband) {
      return (owner: 'husband', ownerName: 'Chồng');
    }
    if (explicitOwner == null && explicitName == TransactionMember.wife) {
      return (owner: 'wife', ownerName: 'Vợ');
    }

    final nameHint = BankNotificationParser.detectMemberHint(wallet.name);
    if (nameHint == 'husband') return (owner: 'husband', ownerName: 'Chồng');
    if (nameHint == 'wife') return (owner: 'wife', ownerName: 'Vợ');

    if (explicitOwner == TransactionMember.joint ||
        explicitName == TransactionMember.joint) {
      return (owner: 'joint', ownerName: 'Chung');
    }
    final fallbackOwner = wallet.owner.trim().isNotEmpty ? wallet.owner : 'joint';
    final fallbackName =
        wallet.ownerName.trim().isNotEmpty ? wallet.ownerName : 'Chung';
    return (owner: fallbackOwner, ownerName: fallbackName);
  }

  static List<Wallet> _narrowCandidatesByContext(
    List<Wallet> pool,
    ParsedBankTransaction tx,
  ) {
    var refined = pool;
    final contextText = '${tx.rawNotificationText} ${tx.note}';
    if (BankNotificationParser.isSavingsContext(contextText)) {
      final savingsMatches = refined
          .where((w) =>
              w.type == 'saving' ||
              BankNotificationParser.isSavingsContext(w.name))
          .toList();
      if (savingsMatches.isNotEmpty) refined = savingsMatches;
    }
    final memberHint = BankNotificationParser.detectMemberHint(contextText);
    if (memberHint != null) {
      final memberMatches = refined
          .where((w) => resolveOwnerForWallet(w).owner == memberHint)
          .toList();
      if (memberMatches.isNotEmpty) refined = memberMatches;
    }
    return refined;
  }

  static Wallet? selectBestWallet(
    List<Wallet> wallets,
    ParsedBankTransaction tx,
  ) {
    if (wallets.isEmpty) return null;
    if (wallets.length == 1) return wallets.first;

    // 1. Khớp chính xác hoặc phần đuôi số tài khoản ngân hàng
    final notifAcct = tx.accountNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (notifAcct.length >= 3) {
      final acctMatches = wallets.where((w) {
        final wAcct = (w.accountNumber ?? '').replaceAll(RegExp(r'\D'), '');
        return wAcct.isNotEmpty &&
            (wAcct.endsWith(notifAcct) || notifAcct.endsWith(wAcct));
      }).toList();
      if (acctMatches.length == 1) return acctMatches.first;
      if (acctMatches.length > 1) {
        return _narrowCandidatesByContext(acctMatches, tx).first;
      }
    }

    // 2. Khớp chuẩn mã thương hiệu ngân hàng thông qua BankIconRegistry (hỗ trợ 38+ ngân hàng & ví điện tử)
    final resolvedTxBrand =
        BankIconRegistry.resolve(tx.bankCode, bankName: tx.bankName);
    if (resolvedTxBrand.code != 'cash') {
      final brandMatches = wallets.where((w) {
        final wBrand = BankIconRegistry.resolve(
          w.bankCode,
          bankName: w.bankName ?? w.name,
        );
        return wBrand.code == resolvedTxBrand.code;
      }).toList();
      if (brandMatches.length == 1) return brandMatches.first;
      if (brandMatches.length > 1) {
        final refinedBrand = _narrowCandidatesByContext(brandMatches, tx);
        if (refinedBrand.length == 1) return refinedBrand.first;
        final notifBal = tx.balanceAfter;
        if (notifBal != null) {
          Wallet? closest;
          double minDiff = double.infinity;
          for (final w in refinedBrand) {
            final wBal = w.balance.toDouble();
            final diffDirect = (wBal - notifBal).abs();
            final diffPreTx = tx.isExpense
                ? (wBal - (notifBal + tx.amount)).abs()
                : (wBal - (notifBal - tx.amount)).abs();
            final diff = math.min(diffDirect, diffPreTx);
            if (diff < minDiff) {
              minDiff = diff;
              closest = w;
            }
          }
          if (closest != null) return closest;
        }
        return refinedBrand.first;
      }
    }

    // 3. Lọc các ví khớp tên ngân hàng hoặc mã ngân hàng (bao gồm NCB Quốc Dân và toàn bộ 66+ ngân hàng / ví điện tử)
    final bankKeywords = <String>{
      tx.bankCode.toLowerCase(),
      tx.bankName.toLowerCase(),
    };
    final bLower = '${tx.bankName} ${tx.bankCode}'.toLowerCase();
    if (bLower.contains('ncb') || bLower.contains('quốc dân') || bLower.contains('quoc dan') || bLower.contains('izimobile')) {
      bankKeywords.addAll(['ncb', 'quốc dân', 'quoc dan', 'izimobile']);
    }
    if (bLower.contains('mb') || bLower.contains('mbbank')) {
      bankKeywords.addAll(['mb', 'mbbank', 'quân đội', 'quan doi']);
    }
    if (bLower.contains('tech') || bLower.contains('tcb')) {
      bankKeywords.addAll(['tech', 'techcom', 'techcombank', 'tcb']);
    }
    if (bLower.contains('vietcom') || bLower.contains('vcb')) {
      bankKeywords.addAll(['vietcom', 'vietcombank', 'vcb']);
    }
    if (bLower.contains('vietin') || bLower.contains('vtb') || bLower.contains('ctg')) {
      bankKeywords.addAll(['vietin', 'vietinbank', 'vtb', 'ctg']);
    }
    if (bLower.contains('acb')) {
      bankKeywords.addAll(['acb', 'á châu', 'a chau']);
    }
    if (bLower.contains('vpbank') || bLower.contains('vpb')) {
      bankKeywords.addAll(['vpbank', 'vpb', 'vp']);
    }
    if (bLower.contains('bidv')) {
      bankKeywords.addAll(['bidv']);
    }
    if (bLower.contains('tpbank') || bLower.contains('tpb')) {
      bankKeywords.addAll(['tpbank', 'tpb', 'tiên phong', 'tien phong']);
    }
    if (bLower.contains('agribank') || bLower.contains('agri')) {
      bankKeywords.addAll(['agribank', 'agri', 'nông nghiệp', 'nong nghiep', 'vba']);
    }
    if (bLower.contains('sacom') || bLower.contains('stb')) {
      bankKeywords.addAll(['sacom', 'sacombank', 'stb']);
    }
    if (bLower.contains('momo')) {
      bankKeywords.addAll(['momo']);
    }
    if (bLower.contains('zalo')) {
      bankKeywords.addAll(['zalo', 'zalopay']);
    }
    if (bLower.contains('viettel')) {
      bankKeywords.addAll(['viettel', 'viettel money', 'vtpay']);
    }
    if (resolvedTxBrand.code != 'cash') {
      bankKeywords.add(resolvedTxBrand.code.toLowerCase());
      bankKeywords.add(resolvedTxBrand.name.toLowerCase());
    }

    final bankMatches = wallets.where((w) {
      final wName = w.name.toLowerCase();
      final wBName = (w.bankName ?? '').toLowerCase();
      final wBCode = (w.bankCode ?? '').toLowerCase();
      return bankKeywords.any((k) =>
          k.isNotEmpty && (wName.contains(k) || wBName.contains(k) || wBCode.contains(k)));
    }).toList();

    final candidatePool = _narrowCandidatesByContext(
      bankMatches.isNotEmpty ? bankMatches : wallets,
      tx,
    );

    // 3. Khớp số dư gần đúng nhất với số dư sau giao dịch (SD / So du)
    final notifBal = tx.balanceAfter;
    if (notifBal != null && notifBal > 0) {
      Wallet? closest;
      double minDiff = double.infinity;
      for (final w in candidatePool) {
        final wBal = w.balance.toDouble();
        final diffDirect = (wBal - notifBal).abs();
        final diffPreTx = tx.isExpense
            ? (wBal - (notifBal + tx.amount)).abs()
            : (wBal - (notifBal - tx.amount)).abs();
        final diff = math.min(diffDirect, diffPreTx);
        if (diff < minDiff) {
          minDiff = diff;
          closest = w;
        }
      }
      if (closest != null) return closest;
    }

    // 4. Nếu là thanh toán thẻ tín dụng, ưu tiên ví loại credit/thẻ tín dụng
    if (tx.isCreditCardPayment) {
      final credit = candidatePool.where((w) =>
          w.type == 'credit' ||
          w.type == 'credit_card' ||
          w.name.toLowerCase().contains('tín dụng') ||
          w.name.toLowerCase().contains('credit')).firstOrNull;
      if (credit != null) return credit;
    }

    return candidatePool.first;
  }

  Wallet? _findBestWallet(List<Wallet> wallets, ParsedBankTransaction tx) =>
      selectBestWallet(wallets, tx);

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
    _balanceAfterCtrl = TextEditingController(
      text: widget.tx.balanceAfter != null
          ? NumberFormat.decimalPattern('vi_VN')
              .format(widget.tx.balanceAfter!.round())
          : '',
    );
    _syncBalanceToBank = widget.tx.balanceAfter != null;
    // Mã giao dịch chính lấy trực tiếp từ thông báo ngân hàng
    final mainBankRef = widget.tx.transactionCode.trim();
    _bankCodeCtrl = TextEditingController(text: mainBankRef);
    // Ghi chú riêng của người dùng tách biệt hoàn toàn
    _noteCtrl = TextEditingController(text: '');
    _selectedMerchantName = widget.tx.suggestedMerchant?.trim().isNotEmpty == true
        ? widget.tx.suggestedMerchant!.trim()
        : null;
    _bankListener = () {
      if (mounted) setState(() {});
    };
    BankSyncService().addListener(_bankListener!);

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

    // 1. Auto-match source wallet by bank name / code and closest balance
    if (wallets.isNotEmpty && _selectedWalletId == null) {
      final best = _findBestWallet(wallets, widget.tx);
      _selectedWalletId = best?.id ?? wallets.first.id;
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

    // 4. Auto-match merchant from user's merchant categories
    final merchants = _availableMerchants(txProv, moreProv);
    if (_selectedMerchantName == null && merchants.isNotEmpty) {
      final notifFull = '${widget.tx.rawNotificationText} ${widget.tx.note} ${widget.tx.suggestedMerchant ?? ''}'.toLowerCase();
      for (final m in merchants) {
        if (m.name.length >= 2 && notifFull.contains(m.name.toLowerCase())) {
          _selectedMerchantId = m.id;
          _selectedMerchantName = m.name;
          break;
        }
      }
    } else if (_selectedMerchantName != null && _selectedMerchantId == null && merchants.isNotEmpty) {
      final match = merchants.where((m) => m.name.toLowerCase() == _selectedMerchantName!.toLowerCase()).firstOrNull;
      if (match != null) {
        _selectedMerchantId = match.id;
        _selectedMerchantName = match.name;
      }
    }

    if (mounted) setState(() {});
  }

  List<Category> _availableMerchants(
      TransactionProvider? txProv, MoreProvider? moreProv) {
    final fromTx = txProv?.categories ?? const <Category>[];
    final fromMore = moreProv?.categories ?? const <Category>[];
    final all = <Category>[...fromMore, ...fromTx];
    return Category.resolveMerchants(
      all,
      preserveId: _selectedMerchantId,
      preserveName: _selectedMerchantName,
    );
  }

  List<Category> _availableCategories(
      TransactionProvider? txProv, MoreProvider? moreProv) {
    final fromTx = txProv?.categories ?? const <Category>[];
    final fromMore = moreProv?.categories ?? const <Category>[];
    final userCategories = fromTx.isNotEmpty ? fromTx : fromMore;

    if (userCategories.isNotEmpty) {
      return userCategories
          .where((c) => !c.isArchived && c.categoryGroup != 'merchant')
          .toList();
    }
    return Category.defaults
        .where((c) => !c.isArchived && c.categoryGroup != 'merchant')
        .toList();
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
    if (_bankListener != null) {
      BankSyncService().removeListener(_bankListener!);
    }
    _amountCtrl.dispose();
    _balanceAfterCtrl.dispose();
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
    final isTransferMode = _selectedType == 'transfer';
    final oppositeId =
        isDestination ? _selectedWalletId : _selectedToWalletId;
    final selectableWallets =
        (isTransferMode && wallets.length > 1 && oppositeId != null)
            ? wallets.where((w) => w.id != oppositeId).toList()
            : wallets;
    final pool = selectableWallets.isNotEmpty ? selectableWallets : wallets;
    final currentId = isDestination ? _selectedToWalletId : _selectedWalletId;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final q = searchQuery.trim().toLowerCase();
            final filteredWallets = q.isEmpty
                ? pool
                : pool
                    .where((w) =>
                        w.name.toLowerCase().contains(q) ||
                        (w.bankName?.toLowerCase().contains(q) ?? false) ||
                        (w.bankCode?.toLowerCase().contains(q) ?? false))
                    .toList();

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              child: GlassBottomSheet(
                radius: 32,
                child: SafeArea(
                  top: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                                shape: BoxShape.circle,
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
                                    isDestination
                                        ? 'Chọn ví nhận tiền'
                                        : 'Chọn ví giao dịch',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Số dư ví được đồng bộ tự động theo thông báo ngân hàng',
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
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) =>
                                      setStateSheet(() => searchQuery = val),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm nhanh ví hoặc ngân hàng...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredWallets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final w = filteredWallets[index];
                              final selected = w.id == currentId;
                              final ownerIsWife =
                                  w.owner.toLowerCase() == 'wife' ||
                                      w.ownerName.toLowerCase().contains('vợ');
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
                                          ? const Color(0xFF059669).withValues(
                                              alpha: isDark ? 0.22 : 0.10)
                                          : (isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF059669)
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : const Color(0xFFE2E8F0)),
                                        width: selected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        BankIcon(
                                          bankCode: w.bankCode ?? w.type,
                                          bankName: w.bankName ?? w.name,
                                          customIconUrl: w.iconUrl,
                                          size: 40,
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
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Text(
                                                    w.isCreditCard
                                                        ? 'Thẻ tín dụng'
                                                        : (w.type == 'bank'
                                                            ? 'Ngân hàng'
                                                            : 'Tiền mặt'),
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF94A3B8)
                                                          : const Color(
                                                              0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: ownerIsWife
                                                          ? (isDark
                                                              ? const Color(
                                                                  0xFF500724)
                                                              : const Color(
                                                                  0xFFFCE7F3))
                                                          : (isDark
                                                              ? const Color(
                                                                  0xFF082F49)
                                                              : const Color(
                                                                  0xFFE0F2FE)),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      ownerIsWife
                                                          ? 'Vợ'
                                                          : 'Chồng',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: ownerIsWife
                                                            ? const Color(
                                                                0xFFDB2777)
                                                            : const Color(
                                                                0xFF0284C7),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatVND(w.balance),
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                            Text(
                                              'Số dư',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF059669),
                                            size: 20,
                                          ),
                                        ],
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
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        if (isDestination) {
          _selectedToWalletId = chosen;
          if (_selectedType == 'transfer' &&
              _selectedWalletId == chosen &&
              wallets.length > 1) {
            _selectedWalletId =
                wallets.firstWhere((w) => w.id != chosen).id;
          }
        } else {
          _selectedWalletId = chosen;
          if (_selectedType == 'transfer' &&
              _selectedToWalletId == chosen &&
              wallets.length > 1) {
            _selectedToWalletId =
                wallets.firstWhere((w) => w.id != chosen).id;
          }
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
        String searchQuery = '';
        bool isListView = false;
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final q = searchQuery.trim().toLowerCase();
            final filtered = q.isEmpty
                ? categories
                : categories
                    .where((c) => c.name.toLowerCase().contains(q))
                    .toList();

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              child: GlassBottomSheet(
                radius: 32,
                child: SafeArea(
                  top: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                    alpha: isDark ? 0.22 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                size: 18,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isIncome
                                              ? 'Chọn danh mục Thu nhập'
                                              : 'Chọn danh mục Chi tiêu',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(
                                              alpha: isDark ? 0.22 : 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${filtered.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đồng bộ 100% biểu tượng & màu sắc danh mục',
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
                            InkWell(
                              onTap: () =>
                                  setStateSheet(() => isListView = !isListView),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  isListView
                                      ? Icons.grid_view_rounded
                                      : Icons.view_list_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) =>
                                      setStateSheet(() => searchQuery = val),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm nhanh danh mục...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: isListView
                              ? ListView.separated(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, index) {
                                    final c = filtered[index];
                                    final key = _catKey(c);
                                    final selected = key == _selectedCategoryId;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => Navigator.pop(ctx, key),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? accent.withValues(
                                                    alpha: isDark ? 0.22 : 0.10)
                                                : (isDark
                                                    ? const Color(0xFF0F172A)
                                                    : const Color(0xFFF8FAFC)),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: selected
                                                  ? accent
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08)
                                                      : const Color(
                                                          0xFFE2E8F0)),
                                              width: selected ? 1.4 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CategoryIconBadge(
                                                icon: c.icon,
                                                categoryName: c.name,
                                                colorHex: c.color,
                                                size: 40,
                                                isDark: isDark,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  c.name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: selected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              if (selected)
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: accent,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, index) {
                                    final c = filtered[index];
                                    final key = _catKey(c);
                                    final selected = key == _selectedCategoryId;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => Navigator.pop(ctx, key),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? accent.withValues(
                                                    alpha: isDark ? 0.24 : 0.14)
                                                : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06)
                                                    : const Color(0xFFF8FAFC)),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: selected
                                                  ? accent
                                                  : (isDark
                                                      ? Colors.white12
                                                      : const Color(
                                                          0xFFE2E8F0)),
                                              width: selected ? 1.8 : 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CategoryIconBadge(
                                                icon: c.icon,
                                                categoryName: c.name,
                                                colorHex: c.color,
                                                size: 38,
                                                isDark: isDark,
                                              ),
                                              const SizedBox(height: 6),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: Text(
                                                  c.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: selected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A),
                                                    height: 1.15,
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
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() => _selectedCategoryId = chosen);
    }
  }


  Future<void> _pickMerchant(List<Category> merchants, bool isDark) async {
    HapticFeedback.selectionClick();
    final accent = _selectedType == 'income'
        ? const Color(0xFF059669)
        : const Color(0xFFE11D48);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final query = searchQuery.trim().toLowerCase();
            final filtered = query.isEmpty
                ? merchants
                : merchants
                    .where((m) =>
                        m.name.toLowerCase().contains(query) ||
                        (m.id.toLowerCase().contains(query)))
                    .toList();

            final bool hasExactMatch =
                filtered.any((m) => m.name.toLowerCase() == query);

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              child: GlassBottomSheet(
                radius: 32,
                child: SafeArea(
                  top: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                    alpha: isDark ? 0.22 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 18,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chọn nơi mua sắm',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đồng bộ thương hiệu, sàn TMĐT & gợi ý ví thông minh',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: TextField(
                            autofocus: false,
                            onChanged: (val) {
                              setStateSheet(() {
                                searchQuery = val;
                              });
                            },
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              hintText: 'Tìm kiếm hoặc nhập tên nơi mua mới...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            children: [
                          // 1. Option: Custom input from search query if not matching existing
                          if (query.isNotEmpty && !hasExactMatch)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.20 : 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_location_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Sử dụng: "$searchQuery"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                subtitle: Text(
                                  'Lưu nơi mua mới này cho giao dịch',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedMerchantId = null;
                                    _selectedMerchantName = searchQuery.trim();
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),

                          // 2. Option: Clear / Không chọn nơi mua
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.block_rounded,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                'Không chọn nơi mua',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              trailing: (_selectedMerchantId == null &&
                                      (_selectedMerchantName == null ||
                                          _selectedMerchantName!.isEmpty))
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: accent,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedMerchantId = null;
                                  _selectedMerchantName = null;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                          ),

                          // 3. Merchants from categories
                          ...filtered.map((m) {
                            final isSel = (_selectedMerchantId == m.id) ||
                                (_selectedMerchantName?.toLowerCase() ==
                                    m.name.toLowerCase());
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? accent.withValues(
                                        alpha: isDark ? 0.22 : 0.10)
                                    : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel
                                      ? accent
                                      : (isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSel ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                leading: CategoryIconBadge(
                                  icon: m.icon,
                                  categoryName: m.name,
                                  colorHex: m.color,
                                  size: 38,
                                  isDark: isDark,
                                ),
                                title: Text(
                                  m.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A))
                                        : (isDark
                                            ? const Color(0xFFE2E8F0)
                                            : const Color(0xFF1E293B)),
                                  ),
                                ),
                                subtitle: Text(
                                  'Danh mục nơi mua',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                trailing: isSel
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: accent,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedMerchantId = m.id;
                                    _selectedMerchantName = m.name;
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Xong',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
  }

  int? _parsedEndingBalance() {
    final digits = _balanceAfterCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;
    final bankSync = BankSyncService();
    if (_savedAwaitingAck) {
      setState(() => _saving = true);
      try {
        final meta = _pendingImportMeta;
        if (meta != null) {
          await bankSync.markImported(
            widget.tx.rawId,
            transactionId: meta.transactionId,
            walletId: meta.walletId,
            walletName: meta.walletName,
            toWalletId: meta.toWalletId,
            toWalletName: meta.toWalletName,
            amount: meta.amount,
            type: meta.type,
            categoryName: meta.categoryName,
            syncedBalance: meta.syncedBalance,
            syncedBalanceValue: meta.syncedBalanceValue,
            fallbackTx: widget.tx,
          );
        } else {
          await bankSync.acknowledge(widget.tx.rawId);
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    if (bankSync.isAlreadyImported(widget.tx.rawId)) {
      final cloud = bankSync.cloudRecordFor(widget.tx.rawId);
      final where = cloud?.importedFrom == 'web' ? 'trên Web' : 'trên thiết bị khác';
      setState(() {
        _validationError =
            'Giao dịch này đã được nhập $where rồi nên không thể ghi trùng.';
      });
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
    if (_selectedType == 'transfer' &&
        destWallet != null &&
        destWallet.id == wallet.id) {
      setState(() {
        _validationError = 'Ví nguồn và ví nhận không được trùng nhau.';
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

      final resolvedOwner = resolveOwnerForWallet(wallet);
      final resolvedDestOwner =
          destWallet != null ? resolveOwnerForWallet(destWallet) : null;

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
        fromWalletId: _selectedType == 'transfer' ? wallet.id : null,
        fromWalletName: _selectedType == 'transfer' ? wallet.name : null,
        toWalletId: destWallet?.id,
        toWalletName: destWallet?.name ?? widget.tx.matchedTransferBankName,
        creditCardId: widget.tx.isCreditCardPayment ? destWallet?.id : null,
        creditCardName: widget.tx.isCreditCardPayment
            ? (destWallet?.name ?? widget.tx.matchedTransferBankName)
            : null,
        owner: resolvedOwner.owner,
        ownerName: resolvedOwner.ownerName,
        fromOwner: _selectedType == 'transfer' ? resolvedOwner.owner : null,
        toOwner: resolvedDestOwner?.owner,
        merchantId: _selectedMerchantId,
        merchantName: _selectedMerchantName?.trim(),
        date: widget.tx.timestamp.millisecondsSinceEpoch,
        note: userNote.isNotEmpty
            ? userNote
            : (_selectedMerchantName ?? resolvedCategoryName),
        bankTransactionCode: mainBankCode,
        rawBankNotification: widget.tx.rawNotificationText.isNotEmpty
            ? widget.tx.rawNotificationText
            : widget.tx.note,
        createdAt: widget.tx.timestamp.millisecondsSinceEpoch,
      );

      final parsedEndingBalance = _parsedEndingBalance();
      final effectiveEndingBalance =
          parsedEndingBalance ?? widget.tx.balanceAfter?.round();
      var didSyncBalance = false;

      if (!_savedAwaitingAck) {
        await txProv.createTransaction(widget.userId, newTx);
        if (_syncBalanceToBank &&
            effectiveEndingBalance != null &&
            walletProv != null &&
            !wallet.isCreditCard) {
          final targetEndBalance = effectiveEndingBalance;
          final txDelta = _selectedType == 'income' ? rawAmount : -rawAmount;
          final expectedAfter = wallet.balance + txDelta;
          final diff = targetEndBalance - expectedAfter;
          if (diff != 0) {
            final updatedWallet = Wallet(
              id: wallet.id,
              name: wallet.name,
              type: wallet.type,
              owner: wallet.owner,
              ownerName: wallet.ownerName,
              hasExplicitOwner: wallet.hasExplicitOwner,
              hasExplicitOwnerName: wallet.hasExplicitOwnerName,
              bankCode: wallet.bankCode,
              bankName: wallet.bankName,
              accountNumber: wallet.accountNumber,
              themeColor: wallet.themeColor,
              initialBalance: wallet.initialBalance + diff,
              hasInitialBalance: true,
              balance: targetEndBalance,
              creditLimit: wallet.creditLimit,
              initialDebt: wallet.initialDebt,
              currentDebt: wallet.currentDebt,
              statementDay: wallet.statementDay,
              paymentDueDay: wallet.paymentDueDay,
              minimumPaymentPercent: wallet.minimumPaymentPercent,
              createdAt: wallet.createdAt,
            );
            try {
              await walletProv.updateWallet(
                  widget.userId, wallet.id, updatedWallet);
              didSyncBalance = true;
            } catch (_) {}
          } else {
            didSyncBalance = true;
          }
        }
        _pendingImportMeta = (
          transactionId: newTx.id,
          walletId: wallet.id,
          walletName: wallet.name,
          toWalletId: destWallet?.id,
          toWalletName: destWallet?.name,
          amount: rawAmount,
          type: _selectedType,
          categoryName: resolvedCategoryName,
          syncedBalance: didSyncBalance,
          syncedBalanceValue:
              didSyncBalance ? effectiveEndingBalance?.toDouble() : null,
        );
        if (mounted) {
          setState(() => _savedAwaitingAck = true);
        }
      }
      try {
        final meta = _pendingImportMeta;
        await bankSync.markImported(
          widget.tx.rawId,
          transactionId: meta?.transactionId ?? newTx.id,
          walletId: meta?.walletId ?? wallet.id,
          walletName: meta?.walletName ?? wallet.name,
          toWalletId: meta?.toWalletId ?? destWallet?.id,
          toWalletName: meta?.toWalletName ?? destWallet?.name,
          amount: meta?.amount ?? rawAmount,
          type: meta?.type ?? _selectedType,
          categoryName: meta?.categoryName ?? resolvedCategoryName,
          syncedBalance: meta?.syncedBalance ?? didSyncBalance,
          syncedBalanceValue: meta?.syncedBalanceValue,
          fallbackTx: widget.tx,
        );
        if (!mounted) return;
        setState(() => _saving = false);
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
    return FinoraModalScope(
      child: Theme(
        data: FinoraModalScope.opaqueModalTheme(context),
        child: Builder(builder: _buildScopedContent),
      ),
    );
  }

  Widget _buildScopedContent(BuildContext context) {
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
      final best = _findBestWallet(wallets, widget.tx);
      _selectedWalletId = best?.id ?? wallets.first.id;
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

    return FinoraDraggableSheetWrapper(
      onClose: () => Navigator.of(context).maybePop(false),
      child: AdaptiveGlassSurface(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              math.max(MediaQuery.paddingOf(context).bottom, 14.0) +
              8.0,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interactive Drag Handle outside ScrollView
            FinoraSheetDragHandle(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              onClose: () => Navigator.of(context).maybePop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

            // 3. Amount Display & Recognized Bank Balance Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.38 : 0.24),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.18),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
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
                                      ? 'Số tiền thu vào nhận diện'
                                      : 'Số tiền chi ra nhận diện'),
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
                  const SizedBox(height: 10),
                  if (!_savedAwaitingAck &&
                      BankSyncService().isAlreadyImported(widget.tx.rawId)) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669)
                            .withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF059669)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              BankSyncService()
                                          .cloudRecordFor(widget.tx.rawId)
                                          ?.importedFrom ==
                                      'web'
                                  ? 'Giao dịch này đã được nhập trên bản Web. Bạn có thể đóng lại để tránh ghi trùng.'
                                  : 'Giao dịch này đã được ghi vào sổ trước đó.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.72)
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF059669)
                            .withValues(alpha: isDark ? 0.35 : 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tx.balanceAfter != null
                                    ? 'Số dư cuối nhận diện từ ${widget.tx.bankName}'
                                    : 'Nhập số dư cuối sau GD (tùy chọn)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.2,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              TextField(
                                controller: _balanceAfterCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  DotSeparatorTextInputFormatter(),
                                ],
                                onChanged: (val) {
                                  final hasDigits = val
                                      .replaceAll(RegExp(r'[^0-9]'), '')
                                      .isNotEmpty;
                                  if (hasDigits && !_syncBalanceToBank) {
                                    setState(() => _syncBalanceToBank = true);
                                  } else if (!hasDigits && _syncBalanceToBank) {
                                    setState(() => _syncBalanceToBank = false);
                                  }
                                },
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Nhập số dư thực tế...',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.only(top: 1),
                                  suffixText: 'đ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => _syncBalanceToBank = !_syncBalanceToBank,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: _syncBalanceToBank
                                  ? const Color(0xFF059669)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _syncBalanceToBank
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF059669)
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _syncBalanceToBank
                                      ? Icons.check_circle_rounded
                                      : Icons.sync_rounded,
                                  size: 13,
                                  color: _syncBalanceToBank
                                      ? Colors.white
                                      : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _syncBalanceToBank
                                      ? 'Đồng bộ ví'
                                      : 'Đồng bộ số dư',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _syncBalanceToBank
                                        ? Colors.white
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
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
                                      customIconUrl: selectedWallet?.iconUrl,
                                      size: 32,
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
                if (isTransfer)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 20),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            final oldFrom = _selectedWalletId;
                            final oldTo = _selectedToWalletId;
                            _selectedWalletId = oldTo;
                            _selectedToWalletId = oldFrom;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            border: Border.all(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: isDark ? 0.50 : 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 17,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                  )
                else
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
                                            customIconUrl:
                                                selectedDestWallet?.iconUrl,
                                            size: 32,
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
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                selectedCategory?.name ??
                                                    (isIncome
                                                        ? 'Thu nhập khác'
                                                        : 'Chi tiêu khác'),
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
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

            // 4b. Nơi mua sắm / Đơn vị chi tiêu (Dropdown / Select đồng bộ danh mục)
            if (!isTransfer) ...[
              () {
                final merchants = _availableMerchants(txProv, moreProv);
                final selectedMerchantCategory = _selectedMerchantId != null
                    ? merchants
                        .where((m) => m.id == _selectedMerchantId)
                        .firstOrNull
                    : (_selectedMerchantName != null
                        ? merchants
                            .where((m) =>
                                m.name.toLowerCase() ==
                                _selectedMerchantName!.toLowerCase())
                            .firstOrNull
                        : null);

                final hasMerchant = _selectedMerchantName != null &&
                    _selectedMerchantName!.trim().isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 5),
                        child: Text(
                          'Nơi mua sắm / Đơn vị',
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
                          onTap: () => _pickMerchant(merchants, isDark),
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: hasMerchant
                                    ? accentColor.withValues(
                                        alpha: isDark ? 0.35 : 0.25)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : const Color(0xFFE2E8F0)),
                                width: hasMerchant ? 1.2 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (selectedMerchantCategory != null)
                                  CategoryIconBadge(
                                    icon: selectedMerchantCategory.icon,
                                    categoryName: selectedMerchantCategory.name,
                                    colorHex: selectedMerchantCategory.color,
                                    size: 36,
                                    isDark: isDark,
                                  )
                                else if (hasMerchant)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF059669)
                                          .withValues(
                                              alpha: isDark ? 0.22 : 0.12),
                                      border: Border.all(
                                        color: const Color(0xFF059669)
                                            .withValues(alpha: 0.30),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 20,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.storefront_outlined,
                                        size: 19,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasMerchant
                                            ? _selectedMerchantName!
                                            : 'Chọn nơi mua sắm (Tùy chọn)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: hasMerchant
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: hasMerchant
                                              ? (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A))
                                              : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        selectedMerchantCategory != null
                                            ? 'Danh mục nơi mua'
                                            : (hasMerchant
                                                ? 'Nơi mua tùy chỉnh'
                                                : 'Chạm để chọn hoặc thêm mới'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasMerchant)
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedMerchantId = null;
                                        _selectedMerchantName = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 17,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
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
                );
              }(),
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

            // 7. Action Buttons Row (Standardized Equal-Width Pill Shape, Height 48px)
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
                              if (context.mounted) {
                                Navigator.of(context).pop(false);
                              }
                            } catch (_) {
                              if (mounted) {
                                setState(() {
                                  _saving = false;
                                  _validationError =
                                      'Chưa thể bỏ qua. Thông báo vẫn được giữ để thử lại.';
                                });
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Bỏ qua',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                        : const Icon(Icons.check_circle_rounded, size: 17),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _saving
                            ? 'Đang lưu...'
                            : (_savedAwaitingAck
                                ? 'Hoàn tất'
                                : 'Ghi vào sổ'),
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
                  ],
                ),
              ),
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
