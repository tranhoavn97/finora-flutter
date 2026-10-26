import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/finora_tokens.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/vietqr_data.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import 'bank_app_selector_sheet.dart';

/// Modal bottom sheet to confirm, categorize, and save an expense scanned from QR
class QrConfirmExpenseSheet extends StatefulWidget {
  final VietQrData qrData;
  final String userId;

  const QrConfirmExpenseSheet({
    super.key,
    required this.qrData,
    required this.userId,
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

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    final initialAmt = widget.qrData.amount;
    _amountController = TextEditingController(
      text: initialAmt != null && initialAmt > 0
          ? _currencyFormat.format(initialAmt.toInt())
          : '',
    );
    _memoController = TextEditingController(text: widget.qrData.memo ?? '');

    // Default category: Food
    _selectedCategory = Category.defaults.firstWhere(
      (c) => c.id == 'food',
      orElse: () => Category.defaults.first,
    );

    // Auto-select wallet matching the bank or default to first wallet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletProv = context.read<WalletProvider>();
      final wallets = walletProv.wallets;
      if (wallets.isNotEmpty) {
        final match = wallets.firstWhere(
          (w) =>
              (w.bankCode != null &&
                  w.bankCode!.toUpperCase() ==
                      widget.qrData.bankShortName.toUpperCase()) ||
              w.name
                  .toLowerCase()
                  .contains(widget.qrData.bankShortName.toLowerCase()),
          orElse: () => wallets.first,
        );
        setState(() {
          _selectedWallet = match;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  Future<void> _handleSaveAndProceed({required bool launchBank}) async {
    final amount = _parsedAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền chi tiêu lớn hơn 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final txId = const Uuid().v4();
    final note = _memoController.text.trim().isNotEmpty
        ? _memoController.text.trim()
        : 'Thanh toán QR (${widget.qrData.bankShortName})';

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
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final txProvider = context.read<TransactionProvider>();
      await txProvider.createTransaction(widget.userId, tx);

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop(); // Close confirm sheet

      if (launchBank) {
        // Show Bank selector or auto launch
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => BankAppSelectorSheet(
            qrData: widget.qrData,
            amount: amount,
            memo: note,
            preferredBankBin: _selectedWallet?.bankCode ?? widget.qrData.bankBin,
            onCancelTransaction: () async {
              try {
                await txProvider.delete(widget.userId, txId);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã hoàn tác và huỷ ghi sổ giao dịch')),
                );
              } catch (_) {}
            },
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đã ghi sổ giao dịch vào Finora thành công!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể ghi sổ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = context.watch<WalletProvider>().wallets;
    final popularCategories = Category.defaults
        .where((c) => c.categoryGroup == 'expense')
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: FinoraTokens.line(isDark),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? FinoraTokens.paperLine2Dark : FinoraTokens.paperLine2Light,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xác nhận chi tiêu QR',
                      style: TextStyle(
                        color: FinoraTokens.ink(isDark),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'BeVietnamPro',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: FinoraTokens.surface2(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FinoraTokens.line(isDark),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: FinoraTokens.ink(isDark),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Beneficiary Card (Ledger Style)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FinoraTokens.surface2(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FinoraTokens.line(isDark)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.qrData.bankLogo != null
                          ? Image.asset(
                              widget.qrData.bankLogo!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _fallbackBankIcon(isDark),
                            )
                          : _fallbackBankIcon(isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.qrData.bankName,
                            style: TextStyle(
                              color: FinoraTokens.ink(isDark),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'STK: ${widget.qrData.accountNumber}',
                            style: TextStyle(
                              color: FinoraTokens.inkSecondary(isDark),
                              fontSize: 12.5,
                              fontFamily: 'JetBrains Mono',
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.qrData.accountName != null &&
                              widget.qrData.accountName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.qrData.accountName!,
                              style: TextStyle(
                                color: FinoraTokens.ink(isDark),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

              // Amount Input
              Text(
                'SỐ TIỀN CHI TIÊU',
                style: TextStyle(
                  color: FinoraTokens.inkSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: FinoraTokens.surface2(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FinoraTokens.line(isDark)),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputExceptionPaddingFix.numberType,
                  inputFormatters: const [DotSeparatorTextInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: FinoraTokens.ink(isDark),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'BeVietnamPro',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: FinoraTokens.inkSecondary(isDark).withValues(alpha: 0.4),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    suffixText: '₫',
                    suffixStyle: TextStyle(
                      color: FinoraTokens.inkSecondary(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Quick amount pills
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [50000, 100000, 200000, 500000].map((amt) {
                    return InkWell(
                      onTap: () {
                        _amountController.text = _currencyFormat.format(amt);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: FinoraTokens.surface2(isDark),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FinoraTokens.line(isDark)),
                        ),
                        child: Text(
                          '+${_currencyFormat.format(amt)}',
                          style: TextStyle(
                            color: FinoraTokens.ink(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Category Selector
              Text(
                'DANH MỤC CHI TIÊU',
                style: TextStyle(
                  color: FinoraTokens.inkSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = popularCategories[i];
                    final isSelected = cat.id == _selectedCategory.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FinoraTokens.ink(isDark)
                              : FinoraTokens.surface2(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? FinoraTokens.ink(isDark)
                                : FinoraTokens.line(isDark),
                          ),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? FinoraTokens.paperBgDark : Colors.white)
                                : FinoraTokens.inkSecondary(isDark),
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Wallet Selector
              Text(
                'VÍ NGUỒN THANH TOÁN',
                style: TextStyle(
                  color: FinoraTokens.inkSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (wallets.isEmpty)
                Text(
                  'Chưa có ví nào trong Finora',
                  style: TextStyle(color: FinoraTokens.inkSecondary(isDark)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: FinoraTokens.surface2(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FinoraTokens.line(isDark)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Wallet>(
                      value: _selectedWallet ?? wallets.first,
                      dropdownColor: FinoraTokens.surface2(isDark),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: FinoraTokens.inkSecondary(isDark)),
                      items: wallets.map((w) {
                        return DropdownMenuItem(
                          value: w,
                          child: Text(
                            '${w.name} (${_currencyFormat.format(w.balance)} đ)',
                            style: TextStyle(
                              color: FinoraTokens.ink(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (w) => setState(() => _selectedWallet = w),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Note / Memo Field
              Text(
                'NỘI DUNG CHUYỂN KHOẢN / GHI CHÚ',
                style: TextStyle(
                  color: FinoraTokens.inkSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: FinoraTokens.surface2(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FinoraTokens.line(isDark)),
                ),
                child: TextField(
                  controller: _memoController,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: const [FirstLetterUpperCaseFormatter()],
                  style: TextStyle(
                    color: FinoraTokens.ink(isDark),
                    fontSize: 13.5,
                    fontFamily: 'BeVietnamPro',
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nhập nội dung chuyển khoản...',
                    hintStyle: TextStyle(
                      color: FinoraTokens.inkSecondary(isDark).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : () => _handleSaveAndProceed(launchBank: true),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: FinoraTokens.ink(isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSaving
                        ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: isDark ? FinoraTokens.paperBgDark : Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                color: isDark ? FinoraTokens.paperBgDark : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ghi sổ & Mở App Ngân hàng',
                                style: TextStyle(
                                  color: isDark ? FinoraTokens.paperBgDark : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'BeVietnamPro',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _isSaving ? null : () => _handleSaveAndProceed(launchBank: false),
                child: Text(
                  'Chỉ ghi sổ vào Finora (Đã thanh toán rồi)',
                  style: TextStyle(
                    color: FinoraTokens.inkSecondary(isDark),
                    fontSize: 12.5,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackBankIcon(bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: FinoraTokens.surface2(isDark),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.account_balance_rounded, color: FinoraTokens.inkSecondary(isDark)),
    );
  }
}

class TextInputExceptionPaddingFix {
  static const TextInputType numberType =
      TextInputType.numberWithOptions(decimal: true);
}
