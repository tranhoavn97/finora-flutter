import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';

/// Loans & debts page — amounts to collect ("lent") vs. amounts to repay
/// ("borrowed"), switched via a segmented control.
class LoanScreen extends StatefulWidget {
  final String userId;
  const LoanScreen({super.key, required this.userId});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  StreamSubscription<String>? _eventsSub;
  String _activeTab = 'lent'; // lent (Phải thu) | borrowed (Phải trả)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddLoanPage(userId: widget.userId, initialType: _activeTab),
    ));
  }

  void _openRepay(Loan loan) {
    showDialog(
      context: context,
      builder: (_) => _RepayDialog(userId: widget.userId, loan: loan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<MoreProvider>();
    final loans = provider.loans;

    final isLent = _activeTab == 'lent';
    final filtered = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .toList();
    final currentTotal = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .fold<int>(0, (s, l) => s + l.remainingPrincipal);
    final labelText = isLent ? 'Tổng phải thu' : 'Tổng phải trả';
    final totalColor = isLent ? AppColors.success : AppColors.error;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Khoản vay & Nợ',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, color: AppColors.accent),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: Column(
              children: [
                SegmentedControl(
                  options: const [
                    ('lent', 'Phải thu'),
                    ('borrowed', 'Phải trả'),
                  ],
                  selected: _activeTab,
                  onChanged: (v) => setState(() => _activeTab = v),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  highlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labelText,
                          style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Text(formatVND(currentTotal),
                          style: AppTypography.largeTitle.copyWith(color: totalColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.handshake,
                      title: 'Không có khoản nợ nào',
                      subtitle:
                          'Các khoản nợ đang hoạt động sẽ xuất hiện ở đây.',
                      actionText: '+ Thêm khoản nợ',
                      onAction: _openAdd,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final loan = filtered[i];
                      return _LoanRow(
                        key: ValueKey(loan.id),
                        loan: loan,
                        onRepay: () => _openRepay(loan),
                        onDelete: () async {
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa khoản vay/nợ?',
                            content: 'Bạn có chắc chắn muốn xóa khoản vay/nợ "${loan.name}" không?',
                          );
                          if (confirm && context.mounted) {
                            context
                                .read<MoreProvider>()
                                .deleteLoan(widget.userId, loan.id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final Loan loan;
  final VoidCallback onRepay;
  final VoidCallback onDelete;
  const _LoanRow({
    super.key,
    required this.loan,
    required this.onRepay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isBorrowed = loan.type == 'borrowed';
    final colorText = isBorrowed ? AppColors.error : AppColors.success;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isOverdue = loan.dueDate != null &&
        loan.dueDate! < nowMs &&
        loan.remainingPrincipal > 0;

    String? dueDateStr;
    Color dueColor = secondaryTextColor;
    if (loan.dueDate != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(loan.dueDate!);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      dueDateStr = 'Hạn: $dd/$mm/${d.year}';
      if (isOverdue) dueColor = AppColors.error;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconBadge(
                      icon:
                          isBorrowed ? Icons.call_made : Icons.call_received,
                      tint: colorText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loan.personName,
                              style: AppTypography.body.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (dueDateStr != null)
                            Text(dueDateStr,
                                style: AppTypography.caption2.copyWith(
                                    color: dueColor,
                                    fontWeight: isOverdue
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(formatVND(loan.remainingPrincipal),
                    style: AppTypography.title3.copyWith(
                        color: colorText, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRepay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: AppRadius.button,
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.24)),
                  ),
                  child: Text(
                      isBorrowed ? 'Trả một phần' : 'Thu một phần',
                      style: AppTypography.caption2.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Repay/collect dialog — reduces remaining principal via updateLoan.
class _RepayDialog extends StatefulWidget {
  final String userId;
  final Loan loan;
  const _RepayDialog({required this.userId, required this.loan});

  @override
  State<_RepayDialog> createState() => _RepayDialogState();
}

class _RepayDialogState extends State<_RepayDialog> {
  late final TextEditingController _amountController;
  Wallet? _selectedWallet;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.loan.remainingPrincipal.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      final loan = widget.loan;
      final newPaid = loan.paidAmount + amount;
      final newRemaining = loan.remainingPrincipal - amount;
      final updated = Loan(
        id: loan.id,
        userId: loan.userId,
        personName: loan.personName,
        name: loan.name,
        type: loan.type,
        principalAmount: loan.principalAmount,
        amount: loan.amount,
        paidAmount: newPaid,
        remainingPrincipal: newRemaining,
        startDate: loan.startDate,
        dueDate: loan.dueDate,
        walletId: loan.walletId,
        walletName: loan.walletName,
        interestRate: loan.interestRate,
        note: loan.note,
        status: newRemaining <= 0 ? 'completed' : 'active',
        createdAt: loan.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await context
          .read<MoreProvider>()
          .updateLoan(widget.userId, loan.id, updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final wallets = context.watch<MoreProvider>().wallets;
    _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;
    final isBorrowed = widget.loan.type == 'borrowed';
    final title = isBorrowed
        ? 'Trả nợ cho ${widget.loan.personName}'
        : 'Thu nợ từ ${widget.loan.personName}';

    return GlassDialog(
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
              maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          Text('Số tiền thanh toán',
              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          GlassTextField(
            controller: _amountController,
            hint: '0 ₫',
            keyboardType: TextInputType.number,
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Chọn ví thực hiện',
                style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in wallets)
                  FilterChipX(
                    label: w.name,
                    selected: _selectedWallet?.id == w.id,
                    onTap: () => setState(() => _selectedWallet = w),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy',
                      style: AppTypography.buttonLabel.copyWith(color: secondaryTextColor)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  expand: true,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen form to record a new loan (lent or borrowed).
class AddLoanPage extends StatefulWidget {
  final String userId;
  final String initialType;
  const AddLoanPage({
    super.key,
    required this.userId,
    required this.initialType,
  });

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  late String _type;
  Wallet? _selectedWallet;
  int? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _dueDate = picked.millisecondsSinceEpoch);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final person = _personController.text.trim();
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (person.isEmpty || amount <= 0) return;

    setState(() => _isSaving = true);
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final loan = Loan(
        userId: widget.userId,
        personName: person,
        type: _type,
        principalAmount: amount,
        amount: amount,
        paidAmount: 0,
        remainingPrincipal: amount,
        startDate: now,
        dueDate: _dueDate,
        status: 'active',
        walletId: _selectedWallet?.id ?? '',
        walletName: _selectedWallet?.name,
        createdAt: now,
        updatedAt: now,
      );
      await context.read<MoreProvider>().addLoan(widget.userId, loan);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final wallets = context.watch<MoreProvider>().wallets;
    _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;

    String dateStr = 'Chọn ngày';
    if (_dueDate != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(_dueDate!);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      dateStr = '$dd/$mm/${d.year}';
    }

    return GlassScaffold(
      appBar: GlassTopBar(
        title: _type == 'lent' ? 'Ghi khoản cho vay' : 'Ghi khoản đi vay',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Loại khoản nợ',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                SegmentedControl(
                  options: const [
                    ('lent', 'Phải thu'),
                    ('borrowed', 'Phải trả'),
                  ],
                  selected: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Đối tượng (Người vay/Người nợ)',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _personController,
                  hint: 'Tên người vay/nợ...',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Số tiền',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _amountController,
                  hint: '0 ₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Hạn trả nợ (Tùy chọn)',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      borderRadius: AppRadius.input,
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr,
                            style: AppTypography.body.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold)),
                        const Text('📅', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                if (wallets.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Ví liên kết (Để ghi nhận giao dịch)',
                      style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in wallets)
                        FilterChipX(
                          label: w.name,
                          selected: _selectedWallet?.id == w.id,
                          onTap: () =>
                              setState(() => _selectedWallet = w),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu khoản nợ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
