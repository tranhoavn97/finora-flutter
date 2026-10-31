import '../../core/widgets/finora_transaction_success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/design_system/app_typography.dart';
import '../../core/theme/finora_tokens.dart';
import '../../core/utils/bank_launcher_helper.dart';
import '../../core/utils/vietqr_parser.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/vietqr_data.dart';
import '../../data/models/wallet.dart';
import '../../data/services/qr_payment_draft_store.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import 'bank_app_selector_sheet.dart';

/// Luxury Bento Modal Bottom Sheet to confirm, categorize, and save an expense
/// scanned or entered from VietQR.
class QrConfirmExpenseSheet extends StatefulWidget {
  final VietQrData qrData;
  final String userId;
  final QrPaymentDraft? resumeDraft;

  const QrConfirmExpenseSheet({
    super.key,
    required this.qrData,
    required this.userId,
    this.resumeDraft,
  });

  @override
  State<QrConfirmExpenseSheet> createState() => _QrConfirmExpenseSheetState();
}

class _QrConfirmExpenseSheetState extends State<QrConfirmExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  late Category _selectedCategory;
  Wallet? _selectedWallet;
  bool _isSaving = false;
  bool _draftSaved = false;
  bool _recorded = false;
  String? _draftError;
  late String _draftId;
  bool _isOpeningBank = false;

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';

  List<Category> _resolveExpenseCategories(BuildContext context) {
    final moreCats =
        Provider.of<MoreProvider?>(context)?.categories ?? const [];
    final txCats =
        Provider.of<TransactionProvider?>(context)?.categories ?? const [];
    final byId = <String, Category>{};

    for (final c in Category.defaults) {
      if (c.categoryGroup == 'expense') {
        byId[c.id] = c;
      }
    }
    for (final c in [...txCats, ...moreCats]) {
      if (c.categoryGroup == 'expense' && !c.isArchived) {
        byId[c.id] = c;
      }
    }
    return byId.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _draftId = widget.resumeDraft?.id ?? const Uuid().v4();
    final initialAmt =
        widget.resumeDraft?.amount.toDouble() ?? widget.qrData.amount;
    _amountController = TextEditingController(
      text: initialAmt != null && initialAmt > 0
          ? _currencyFormat.format(initialAmt.toInt()).replaceAll(',', '.')
          : '',
    );
    _memoController = TextEditingController(
        text: widget.resumeDraft?.memo ?? widget.qrData.memo ?? '');

    _selectedCategory = Category.defaults.firstWhere(
      (c) => c.id == 'food',
      orElse: () => Category.defaults.first,
    );

    _amountController.addListener(_scheduleDraft);
    _memoController.addListener(_scheduleDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletProv = context.read<WalletProvider>();
      final wallets = walletProv.wallets;
      if (wallets.isNotEmpty) {
        setState(() {
          _selectedWallet = wallets.first;
        });
      }
      final resume = widget.resumeDraft;
      if (resume != null) {
        for (final w in wallets) {
          if (w.id == resume.walletId) _selectedWallet = w;
        }
        final allCats = _resolveExpenseCategories(context);
        for (final c in allCats) {
          if (c.id == resume.categoryId) _selectedCategory = c;
        }
      }
      _persistDraft();
    });
  }

  void _scheduleDraft() {
    _persistDraft();
  }

  Future<bool> _persistDraft() async {
    if (_recorded) return true;
    final draft = QrPaymentDraft(
      id: _draftId,
      data: widget.qrData,
      amount: _parsedAmount.toInt(),
      memo: _memoController.text.trim(),
      walletId: _selectedWallet?.id,
      categoryId: _selectedCategory.id,
    );
    try {
      await QrPaymentDraftStore.save(widget.userId, draft);
      if (mounted) {
        setState(() {
          _draftSaved = true;
          _draftError = null;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _draftSaved = false;
          _draftError = 'Chưa lưu được nháp trên máy. Hãy thử lại.';
        });
      }
      return false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(clean) ?? 0.0;
    return amount.isFinite && amount <= 999999999999 ? amount : 0;
  }

  Future<void> _handleSaveAndProceed({required bool launchBank}) async {
    if (_isSaving || _isOpeningBank || _recorded) return;
    final amount = _parsedAmount;
    if (amount <= 0) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập số tiền chi tiêu lớn hơn 0')),
      );
      return;
    }

    if (launchBank) {
      setState(() => _isOpeningBank = true);
      try {
        if (!await _persistDraft() || !mounted) return;
        final walletBank = BankLauncherHelper.resolveWalletBank(
          bankCode: _selectedWallet?.bankCode,
          bankName: _selectedWallet?.bankName,
          walletName: _selectedWallet?.name,
        );
        final launched = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BankAppSelectorSheet(
            qrData: widget.qrData,
            amount: amount,
            memo: _memoController.text.trim(),
            preferredBankBin: walletBank?.bin ?? _selectedWallet?.bankCode,
            onBankSelected: (bank) => _recordTemplateTransactionOnly(bank, amount),
          ),
        );
        if (launched == true && mounted) {
          Navigator.of(context).pop();
        }
      } finally {
        if (mounted) setState(() => _isOpeningBank = false);
      }
      return;
    }

    if (_selectedWallet == null) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ví để ghi nhận khoản chi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final txId = _draftId;
    final note = _memoController.text.trim().isNotEmpty
        ? _memoController.text.trim()
        : 'Thanh toán QR (${widget.qrData.bankShortName})';

    final owner = _selectedWallet?.owner;
    final ownerTag = owner == 'wife'
        ? 'Vợ'
        : owner == 'joint'
            ? 'Chung'
            : 'Chồng';
    final tx = TransactionModel(
      id: txId,
      userId: widget.userId,
      amount: amount.toInt(),
      type: 'expense',
      date: DateTime.now().millisecondsSinceEpoch,
      note: note,
      categoryId: _selectedCategory.id,
      categoryName: _selectedCategory.name,
      categoryIcon: _selectedCategory.icon,
      walletId: _selectedWallet?.id,
      walletName: _selectedWallet?.name,
      owner: owner,
      ownerName: _selectedWallet?.ownerName,
      creatorTag: ownerTag,
      bankTransactionCode:
          'QR-${widget.qrData.bankShortName}-${widget.qrData.accountNumber}',
      tags: [ownerTag, 'VietQR'],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.createTransaction(widget.userId, tx);

      _recorded = true;
      try {
        await QrPaymentDraftStore.remove(widget.userId, _draftId);
      } catch (_) {}
      if (!mounted) return;
      await FinoraTransactionSuccessModal.show(
        context,
        transaction: tx,
        walletName: _selectedWallet?.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          SnackBar(content: Text('Không thể ghi sổ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _recordTemplateTransactionOnly(
      BankInfo bank, double amount) async {
    if (_recorded || _selectedWallet == null) return;
    final txId = _draftId;
    final memoText = _memoController.text.trim();
    final note = memoText.isNotEmpty
        ? memoText
        : 'Thanh toán QR (${widget.qrData.bankShortName})';
    final owner = _selectedWallet?.owner;
    final ownerTag = owner == 'wife'
        ? 'Vợ'
        : owner == 'joint'
            ? 'Chung'
            : 'Chồng';
    final tx = TransactionModel(
      id: txId,
      userId: widget.userId,
      amount: amount.toInt(),
      type: 'expense',
      date: DateTime.now().millisecondsSinceEpoch,
      note: note,
      categoryId: _selectedCategory.id,
      categoryName: _selectedCategory.name,
      categoryIcon: _selectedCategory.icon,
      walletId: _selectedWallet?.id,
      walletName: _selectedWallet?.name,
      owner: owner,
      ownerName: _selectedWallet?.ownerName,
      creatorTag: ownerTag,
      bankTransactionCode:
          'QR-${widget.qrData.bankShortName}-${widget.qrData.accountNumber}',
      tags: [ownerTag, 'VietQR', bank.shortName],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.createTransaction(widget.userId, tx);
      _recorded = true;
      await QrPaymentDraftStore.remove(widget.userId, _draftId);
    } catch (_) {}
  }

  /// Records the expense into Finora for the selected Husband/Wife wallet AND
  /// immediately launches that wallet's bank app (e.g., Techcombank, MB, VCB)
  /// with the amount and transfer details pre-filled/copied.
  Future<void> _handleDirectWalletBankLaunch(BankInfo bank) async {
    if (_isSaving || _isOpeningBank || _recorded) return;
    final amount = _parsedAmount;
    if (amount <= 0) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập số tiền chi tiêu lớn hơn 0')),
      );
      return;
    }
    if (_selectedWallet == null) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ví để ghi nhận khoản chi.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _isOpeningBank = true;
    });
    final txId = _draftId;
    final memoText = _memoController.text.trim();
    final note = memoText.isNotEmpty
        ? memoText
        : 'Thanh toán QR (${widget.qrData.bankShortName})';
    final owner = _selectedWallet?.owner;
    final ownerTag = owner == 'wife'
        ? 'Vợ'
        : owner == 'joint'
            ? 'Chung'
            : 'Chồng';

    final tx = TransactionModel(
      id: txId,
      userId: widget.userId,
      amount: amount.toInt(),
      type: 'expense',
      date: DateTime.now().millisecondsSinceEpoch,
      note: note,
      categoryId: _selectedCategory.id,
      categoryName: _selectedCategory.name,
      categoryIcon: _selectedCategory.icon,
      walletId: _selectedWallet?.id,
      walletName: _selectedWallet?.name,
      owner: owner,
      ownerName: _selectedWallet?.ownerName,
      creatorTag: ownerTag,
      bankTransactionCode:
          'QR-${widget.qrData.bankShortName}-${widget.qrData.accountNumber}',
      tags: [ownerTag, 'VietQR', bank.shortName],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.createTransaction(widget.userId, tx);
      _recorded = true;
      try {
        await QrPaymentDraftStore.remove(widget.userId, _draftId);
      } catch (_) {}
      if (!mounted) return;
      await BankLauncherHelper.launchBankAppDirect(
        context: context,
        bank: bank,
        data: widget.qrData,
        amount: amount,
        memo: note,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          SnackBar(content: Text('Không thể ghi sổ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isOpeningBank = false;
        });
      }
    }
  }

  void _openCategorySheet(List<Category> categories, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121C24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.layout_grid, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chọn danh mục chi tiêu',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.65,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, idx) {
                      final cat = categories[idx];
                      final selected = cat.id == _selectedCategory.id;
                      final catColor = BankIconRegistry.parseThemeColor(
                        cat.color,
                        fallback: primary,
                      );
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                          _persistDraft();
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? catColor.withValues(
                                    alpha: isDark ? 0.22 : 0.12)
                                : (isDark
                                    ? const Color(0xFF1A2632)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? catColor
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: selected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CategoryIconBadge(
                                icon: cat.icon,
                                categoryName: cat.name,
                                color: catColor,
                                size: 34,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _font,
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
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: catColor,
                                ),
                            ],
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
  }

  void _openWalletSheet(List<Wallet> wallets, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121C24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.wallet, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chọn ví nguồn thanh toán',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final w = wallets[idx];
                      final selected = w.id == _selectedWallet?.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedWallet = w);
                          _persistDraft();
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? primary.withValues(
                                    alpha: isDark ? 0.20 : 0.10)
                                : (isDark
                                    ? const Color(0xFF1A2632)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: selected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              BankIcon(
                                bankCode: w.bankCode,
                                bankName: w.name,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Số dư: ${_currencyFormat.format(w.balance).replaceAll(',', '.')} ₫',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle_rounded,
                                    color: primary, size: 20),
                            ],
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final primary = studio?.primaryColor ?? const Color(0xFF00866A);
    final secondary = studio?.secondaryColor ?? const Color(0xFF10B981);
    final wallets = context.watch<WalletProvider>().wallets;
    final expenseCategories = _resolveExpenseCategories(context);
    final selectedWallet =
        _selectedWallet ?? (wallets.isNotEmpty ? wallets.first : null);
    final selectedCatColor = BankIconRegistry.parseThemeColor(
      _selectedCategory.color,
      fallback: primary,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                40)
            .clamp(220, MediaQuery.sizeOf(context).height),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101920) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header Row with Draft Status Pill
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.qr_code,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kiểm tra giao dịch QR',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            fontFamily: _font,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _draftError == null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _draftError ??
                                    (_draftSaved
                                        ? 'Đã lưu nháp #${_draftId.split('-').first.toUpperCase()} · Chưa ghi chi'
                                        : 'Đang lưu nháp tự động…'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _draftError == null
                                      ? (isDark
                                          ? const Color(0xFF34D399)
                                          : primary)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (await _persistDraft()) {
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2834)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 1. Beneficiary Card (Luxury Bento Style)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF172430),
                            const Color(0xFF131E28),
                          ]
                        : [
                            const Color(0xFFF8FAFC),
                            Color.alphaBlend(
                                primary.withValues(alpha: 0.05), Colors.white),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    BankIcon(
                      bankCode: widget.qrData.bankShortName,
                      bankName: widget.qrData.bankName,
                      size: 46,
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
                                  widget.qrData.bankName,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: _font,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                      alpha: isDark ? 0.22 : 0.10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  widget.qrData.bankShortName,
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'STK: ${widget.qrData.accountNumber}',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF334155),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: _font,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: widget.qrData.accountNumber));
                                  FinoraNotice.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép số tài khoản'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    LucideIcons.copy,
                                    size: 13,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.qrData.accountName != null &&
                              widget.qrData.accountName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.qrData.accountName!,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: _font,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Hero Amount Input Pod
              _buildSectionLabel('SỐ TIỀN THANH TOÁN', isDark),
              const SizedBox(height: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF172430) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _parsedAmount > 0
                        ? primary.withValues(alpha: isDark ? 0.55 : 0.38)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE2E8F0)),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputExceptionPaddingFix.numberType,
                        inputFormatters: const [
                          DotSeparatorTextInputFormatter()
                        ],
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          fontFamily: _font,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFF94A3B8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (_amountController.text.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _amountController.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'VND',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: _font,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick amount pills
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children:
                        [50000, 100000, 200000, 500000, 1000000].map((amt) {
                      final formatted =
                          _currencyFormat.format(amt).replaceAll(',', '.');
                      final isCurrent = _parsedAmount.toInt() == amt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _amountController.text = formatted;
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? primary
                                  : (isDark
                                      ? const Color(0xFF172430)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: isCurrent
                                    ? primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              '$formatted ₫',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF334155)),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: _font,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Category Selector & Quick Category Strip
              Row(
                children: [
                  Expanded(
                    child: _buildSectionLabel('DANH MỤC CHI TIÊU', isDark),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () =>
                          _openCategorySheet(expenseCategories, primary),
                      child: Text(
                        'Xem tất cả (${expenseCategories.length}) ›',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Selected Category Pod
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openCategorySheet(expenseCategories, primary),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF172430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedCatColor.withValues(
                          alpha: isDark ? 0.45 : 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      CategoryIconBadge(
                        icon: _selectedCategory.icon,
                        categoryName: _selectedCategory.name,
                        color: selectedCatColor,
                        size: 38,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory.name,
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Nhấn để đổi danh mục khác',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevron_down,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Horizontal Quick-Pick Category Strip with Icons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(expenseCategories.length, (i) {
                    final cat = expenseCategories[i];
                    final isSelected = cat.id == _selectedCategory.id;
                    final catColor = BankIconRegistry.parseThemeColor(
                      cat.color,
                      fallback: primary,
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < expenseCategories.length - 1 ? 8 : 0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                          _persistDraft();
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor.withValues(
                                    alpha: isDark ? 0.24 : 0.14)
                                : (isDark
                                    ? const Color(0xFF172430)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: isSelected
                                  ? catColor
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.3 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryIconBadge(
                                icon: cat.icon,
                                categoryName: cat.name,
                                color: catColor,
                                size: 22,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A))
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569)),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontFamily: _font,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Wallet Selector (Luxury Bento Pod)
              _buildSectionLabel('VÍ NGUỒN THANH TOÁN (CHỒNG / VỢ / CHUNG)', isDark),
              const SizedBox(height: 7),
              if (wallets.isEmpty || selectedWallet == null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF172430)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FinoraTokens.line(isDark)),
                  ),
                  child: Text(
                    'Chưa có ví nào trong Finora',
                    style: TextStyle(
                      fontFamily: _font,
                      color: FinoraTokens.inkSecondary(isDark),
                    ),
                  ),
                )
              else ...[
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openWalletSheet(wallets, primary),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF172430)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            BankIcon(
                              bankCode: selectedWallet.bankCode,
                              bankName: selectedWallet.name,
                              size: 38,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -2,
                              child: FinoraMemberAvatar(
                                memberKey: selectedWallet.owner == 'wife'
                                    ? 'wife'
                                    : selectedWallet.owner == 'joint'
                                        ? 'joint'
                                        : 'husband',
                                size: 17,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedWallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Số dư khả dụng: ${_currencyFormat.format(selectedWallet.balance).replaceAll(',', '.')} ₫',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevron_down,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                if (wallets.length > 1) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: wallets.map((w) {
                        final isSelected = w.id == selectedWallet.id;
                        final mKey = w.owner == 'wife'
                            ? 'wife'
                            : w.owner == 'joint'
                                ? 'joint'
                                : 'husband';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedWallet = w);
                              _persistDraft();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary.withValues(
                                        alpha: isDark ? 0.24 : 0.14)
                                    : (isDark
                                        ? const Color(0xFF172430)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.3 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FinoraMemberAvatar(
                                    memberKey: mKey,
                                    size: 18,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    w.name,
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                          : (isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // 5. Note / Memo Field
              _buildSectionLabel('NỘI DUNG CHUYỂN KHOẢN / GHI CHÚ', isDark),
              const SizedBox(height: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF172430) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _memoController,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: const [FirstLetterUpperCaseFormatter()],
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: _font,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    prefixIcon: Icon(
                      LucideIcons.file_text,
                      size: 17,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 40),
                    hintText: 'Nhập nội dung chuyển khoản...',
                    hintStyle: TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 6. Action Buttons (Single Unified Bank Launch Button + Confirm)
              Builder(builder: (context) {
                final walletBank = BankLauncherHelper.resolveWalletBank(
                  bankCode: selectedWallet?.bankCode,
                  bankName: selectedWallet?.bankName,
                  walletName: selectedWallet?.name,
                );
                final hasDirectOwnerBank =
                    walletBank != null && selectedWallet?.owner != null;

                return Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F6E56),
                        primary,
                        secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: isDark ? 0.38 : 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_isSaving || _isOpeningBank)
                                ? null
                                : () => hasDirectOwnerBank
                                    ? _handleDirectWalletBankLaunch(walletBank)
                                    : _handleSaveAndProceed(launchBank: true),
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: _isSaving
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          hasDirectOwnerBank
                                              ? LucideIcons.zap
                                              : LucideIcons.external_link,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            hasDirectOwnerBank
                                                ? 'Mở app ${walletBank.name} & Tạo giao dịch mẫu'
                                                : 'Mở MB / Techcombank',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: _font,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (hasDirectOwnerBank)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_isSaving || _isOpeningBank)
                                ? null
                                : () => _handleSaveAndProceed(launchBank: true),
                            borderRadius: BorderRadius.circular(999),
                            child: Tooltip(
                              message: 'Chọn ngân hàng khác (MB / Techcombank)',
                              child: Container(
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.24),
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: (_isSaving || _isOpeningBank)
                      ? null
                      : () => _handleSaveAndProceed(launchBank: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? const Color(0xFF34D399) : primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(
                      color: primary.withValues(alpha: isDark ? 0.45 : 0.32),
                      width: 1.2,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? const Color(0xFF34D399) : primary,
                          ),
                        )
                      else
                        const Icon(LucideIcons.circle_check, size: 17),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Đã thanh toán · Ghi chi vào Finora',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: _font,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
        fontFamily: _font,
      ),
    );
  }
}

class TextInputExceptionPaddingFix {
  static const TextInputType numberType =
      TextInputType.numberWithOptions(decimal: true);
}
