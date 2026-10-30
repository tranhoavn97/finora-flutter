import '../../core/widgets/finora_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_date_picker_sheet.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';

/// Apple-style Bottom Sheet to Add Loan with Source/Destination Wallet & Spender Selection
/// (used by WealthHubScreen Tab 3: Sổ nợ)
class AddLoanSheet extends StatefulWidget {
  final String userId;
  final String initialType;
  const AddLoanSheet({
    super.key,
    required this.userId,
    required this.initialType,
  });

  @override
  State<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<AddLoanSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _type; // 'lent' (Cho vay - Xuất tiền) | 'borrowed' (Đi vay - Nhận tiền)
  String _owner = 'husband'; // 'husband' (Chồng) | 'wife' (Vợ)
  String? _selectedWalletId;
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _showWalletList = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'borrowed' ? 'borrowed' : 'lent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Wallet> _resolveAvailableWallets(BuildContext context) {
    final walletProv = Provider.of<WalletProvider?>(context, listen: true);
    final txProv = Provider.of<TransactionProvider?>(context, listen: true);
    final moreProv = Provider.of<MoreProvider?>(context, listen: true);

    List<Wallet> raw = [];
    if (walletProv != null && walletProv.wallets.isNotEmpty) {
      raw = walletProv.wallets;
    } else if (txProv != null && txProv.wallets.isNotEmpty) {
      raw = txProv.wallets;
    } else if (moreProv != null && moreProv.wallets.isNotEmpty) {
      raw = moreProv.wallets;
    }

    final nonCredit = raw.where((w) => !w.isCreditCard).toList();
    return nonCredit.isNotEmpty ? nonCredit : raw;
  }

  Wallet? _resolveSelectedWallet(List<Wallet> wallets) {
    if (wallets.isEmpty) return null;
    if (_selectedWalletId != null) {
      final matched = wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
      if (matched != null) return matched;
    }
    return wallets.first;
  }

  Future<void> _pickDueDate() async {
    HapticFeedback.selectionClick();
    final picked = await FinoraDatePickerSheet.showSingleDate(
      context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _handleSave(List<Wallet> wallets) async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;

    if (name.isEmpty || amount <= 0) {
      HapticFeedback.heavyImpact();
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(
            name.isEmpty
                ? (_type == 'lent'
                    ? 'Vui lòng nhập tên người vay'
                    : 'Vui lòng nhập tên người cho vay (chủ nợ)')
                : 'Vui lòng nhập số tiền hợp lệ lớn hơn 0',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final selectedWallet = _resolveSelectedWallet(wallets);
      final rawNote = _noteController.text.trim();
      final effectiveNote = selectedWallet != null
          ? (rawNote.isNotEmpty
              ? '[Ví: ${selectedWallet.name}] $rawNote'
              : '[Ví: ${selectedWallet.name}]')
          : (rawNote.isNotEmpty ? rawNote : null);

      final loanId = 'loan_$now';
      final loan = Loan(
        id: loanId,
        userId: widget.userId,
        personName: name,
        type: _type,
        principalAmount: amount,
        amount: amount,
        remainingPrincipal: amount,
        startDate: now,
        dueDate: _dueDate?.millisecondsSinceEpoch,
        walletId: selectedWallet?.id ?? '',
        walletName: selectedWallet?.name,
        note: effectiveNote,
      );

      final moreProv = context.read<MoreProvider>();
      await moreProv.addLoan(widget.userId, loan);

      // Sync wallet balance by recording the corresponding loan / borrowing transaction
      if (selectedWallet != null && mounted) {
        final txProv = Provider.of<TransactionProvider?>(context, listen: false);
        if (txProv != null) {
          final txNote = _type == 'lent'
              ? 'Cho $name vay${rawNote.isNotEmpty ? " - $rawNote" : ""}'
              : 'Vay tiền từ $name${rawNote.isNotEmpty ? " - $rawNote" : ""}';
          final tx = TransactionModel(
            userId: widget.userId,
            amount: amount,
            type: _type == 'lent' ? 'loan' : 'borrowing',
            date: now,
            walletId: selectedWallet.id,
            walletName: selectedWallet.name,
            owner: _owner,
            ownerName: _owner == 'wife' ? 'Vợ' : 'Chồng',
            creatorTag: _owner,
            loanId: loanId,
            categoryName: _type == 'lent' ? 'Cho vay' : 'Đi vay',
            note: txNote,
          );
          await txProv.createTransaction(widget.userId, tx);
        }
        if (mounted) {
          Provider.of<WalletProvider?>(context, listen: false)
              ?.load(widget.userId, force: true);
        }
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final glassOpacity = studio?.glassOpacity ?? 0.95;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isLent = _type == 'lent';
    final accentColor =
        isLent ? const Color(0xFF0F6E56) : const Color(0xFFE11D48);
    final accentBright =
        isLent ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    final wallets = _resolveAvailableWallets(context);
    final selectedWallet = _resolveSelectedWallet(wallets);
    if (_selectedWalletId == null && selectedWallet != null) {
      _selectedWalletId = selectedWallet.id;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white)
            .withValues(alpha: glassOpacity.clamp(0.92, 1.0)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.12 : 0.06),
            width: 1.0,
          ),
        ),
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
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title & Close Button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLent
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    color: isDark ? accentBright : accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLent ? 'Thêm khoản cho vay' : 'Thêm khoản vay nợ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLent
                            ? 'Xuất tiền từ ví cho người khác vay'
                            : 'Nhận tiền vay vào ví và ghi nhận công nợ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: secondaryTextColor,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Type Selector Pills: Cho vay (Xuất tiền) vs Đi vay (Nhận tiền)
            Row(
              children: [
                Expanded(
                  child: _buildTypePill(
                    label: 'Cho vay (Xuất tiền)',
                    icon: Icons.arrow_outward_rounded,
                    isSelected: isLent,
                    activeColor: const Color(0xFF0F6E56),
                    pastelBg: isDark
                        ? const Color(0xFF0F6E56).withValues(alpha: 0.14)
                        : const Color(0xFFECFDF5),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = 'lent');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypePill(
                    label: 'Đi vay (Nhận tiền)',
                    icon: Icons.south_west_rounded,
                    isSelected: !isLent,
                    activeColor: const Color(0xFFE11D48),
                    pastelBg: isDark
                        ? const Color(0xFFE11D48).withValues(alpha: 0.14)
                        : const Color(0xFFFFF1F2),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = 'borrowed');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Spender / Owner Selector Pills: Chồng vs Vợ
            Row(
              children: [
                Text(
                  isLent ? 'Người cho vay:' : 'Người đứng vay:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildOwnerPill(
                          label: 'Chồng',
                          icon: Icons.face_rounded,
                          isSelected: _owner == 'husband',
                          color: const Color(0xFF0284C7),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _owner = 'husband');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOwnerPill(
                          label: 'Vợ',
                          icon: Icons.face_3_rounded,
                          isSelected: _owner == 'wife',
                          color: const Color(0xFFDB2777),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _owner = 'wife');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Person Name Field
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [FirstLetterUpperCaseFormatter()],
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
              decoration: InputDecoration(
                labelText:
                    isLent ? 'Tên người vay' : 'Tên người cho vay (Chủ nợ)',
                hintText: isLent ? 'VD: Anh Tuấn, Chị Mai...' : 'VD: Ngân hàng, Anh Hùng...',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: isDark ? accentBright : accentColor,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                    : const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Amount Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const [DotSeparatorTextInputFormatter()],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? accentBright : accentColor,
              ),
              decoration: InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                hintText: '0',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: isDark ? accentBright : accentColor,
                ),
                suffixText: '₫',
                suffixStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: secondaryTextColor,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                    : const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Source / Destination Wallet Selector
            Text(
              isLent
                  ? 'Nguồn tiền cho vay (Trừ tiền từ ví)'
                  : 'Ví nhận tiền vay (Cộng tiền vào ví)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: secondaryTextColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            if (wallets.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chưa có ví khả dụng (Sẽ chỉ ghi sổ nợ)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Selected Wallet Interactive Apple Tile
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showWalletList = !_showWalletList);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.75)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: isDark ? 0.45 : 0.30),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildWalletBrandAvatar(selectedWallet!, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedWallet.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isLent ? 'Xuất tiền cho vay' : 'Nhận tiền đi vay',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? accentBright : accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatVND(selectedWallet.balance),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showWalletList
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Horizontal Wallet Chips / Expandable Picker
              if (wallets.length > 1 || _showWalletList) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: wallets.map((w) {
                      final isSelected = w.id == selectedWallet.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedWalletId = w.id;
                              _showWalletList = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.08),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildWalletBrandAvatar(w, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  w.name,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '(${formatVND(w.balance)})',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : secondaryTextColor,
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
            const SizedBox(height: 12),

            // 6. Due Date & Note Row
            Row(
              children: [
                // Due Date Picker Tile
                Expanded(
                  flex: 5,
                  child: InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _dueDate != null
                              ? accentColor.withValues(alpha: 0.5)
                              : (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 17,
                            color: _dueDate != null
                                ? (isDark ? accentBright : accentColor)
                                : secondaryTextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dueDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                                  : 'Hạn trả dự kiến',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _dueDate != null
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _dueDate != null
                                    ? primaryTextColor
                                    : secondaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_dueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _dueDate = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: secondaryTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Optional Note Input
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [FirstLetterUpperCaseFormatter()],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ghi chú khoản vay...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          size: 17,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.10),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.10),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: accentColor, width: 1.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7. Solid Stadium-Pill Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _handleSave(wallets),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLent
                                ? Icons.check_circle_outline_rounded
                                : Icons.downloading_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isLent
                                  ? 'Lưu khoản cho vay'
                                  : 'Lưu khoản vay nợ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildTypePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color pastelBg,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : pastelBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? activeColor
                : activeColor.withValues(alpha: isDark ? 0.35 : 0.25),
            width: isSelected ? 1.2 : 0.9,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.28),
            width: 0.9,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBrandAvatar(Wallet wallet, {required double size}) {
    final brand = BankIconRegistry.resolve(
      wallet.bankCode ?? wallet.type,
      bankName: wallet.bankName ?? wallet.name,
    );
    final isCash = brand.code == 'cash' || wallet.type == 'cash';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCash ? const Color(0xFF10B981) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: isCash
          ? Center(
              child: Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: size * 0.52,
              ),
            )
          : (brand.assetPath != null && brand.assetPath!.isNotEmpty
              ? ClipOval(
                  child: Image.asset(
                    brand.assetPath!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: size * 0.52,
                        color: brand.color,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: size * 0.52,
                    color: brand.color,
                  ),
                )),
    );
  }
}
