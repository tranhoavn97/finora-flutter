import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/vikram_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';

/// Loans & debts page — amounts to collect ("lent") vs. amounts to repay ("borrowed").
class LoanScreen extends StatefulWidget {
  final String userId;
  const LoanScreen({super.key, required this.userId});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  StreamSubscription<String>? _eventsSub;
  String _activeTab = 'lent'; // lent (Cho vay) | borrowed (Vay nợ)

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
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          AddLoanPage(userId: widget.userId, initialType: _activeTab),
    ));
  }

  void _openEdit(Loan loan) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddLoanPage(
          userId: widget.userId, initialType: loan.type, loan: loan),
    ));
  }

  void _openRepay(Loan loan) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => _RepayDialog(userId: widget.userId, loan: loan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MoreProvider>();
    final loans = provider.loans;

    final isLent = _activeTab == 'lent';
    final filtered = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .toList();
    final currentTotal = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .fold<int>(0, (s, l) => s + l.remainingPrincipal);
    final labelText = isLent ? 'TỔNG CẦN THU VỀ' : 'TỔNG CẦN CHI TRẢ';
    final totalColor = isLent ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PearlMeshBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Khoản vay & Nợ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: c.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openAdd,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Thêm',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Tabs: Cho vay | Vay nợ
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    SegmentedControl(
                      options: const [
                        ('lent', 'Cho vay'),
                        ('borrowed', 'Vay nợ'),
                      ],
                      selected: _activeTab,
                      onChanged: (v) => setState(() => _activeTab = v),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          colors: isLent
                              ? [
                                  const Color(0xFF065F46),
                                  const Color(0xFF059669),
                                  const Color(0xFF10B981),
                                ]
                              : [
                                  const Color(0xFF881337),
                                  const Color(0xFFBE123C),
                                  const Color(0xFFF43F5E),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isLent
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFE11D48))
                                .withOpacity(0.40),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                labelText,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white70,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.25)),
                                ),
                                child: Text(
                                  '${filtered.length} khoản ${isLent ? "cho vay" : "vay nợ"}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatVND(currentTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.handshake_outlined,
                          title: isLent
                              ? 'Không có khoản cho vay nào'
                              : 'Không có khoản vay nợ nào',
                          subtitle:
                              'Các khoản nợ đang hoạt động sẽ xuất hiện ở đây.',
                          actionText: isLent
                              ? 'Thêm khoản cho vay'
                              : 'Thêm khoản vay nợ',
                          onAction: _openAdd,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final loan = filtered[i];
                          return _LoanRow(
                            key: ValueKey(loan.id),
                            loan: loan,
                            onRepay: () => _openRepay(loan),
                            onEdit: () => _openEdit(loan),
                            onDelete: () async {
                              final confirm = await showConfirmDeleteDialog(
                                context: context,
                                title: 'Xóa khoản vay/nợ?',
                                content:
                                    'Bạn có chắc chắn muốn xóa "${loan.personName}" không?',
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
        ),
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final Loan loan;
  final VoidCallback onRepay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _LoanRow({
    super.key,
    required this.loan,
    required this.onRepay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    final isBorrowed = loan.type == 'borrowed';
    final colorText = isBorrowed ? AppColors.error : AppColors.success;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isOverdue = loan.dueDate != null &&
        loan.dueDate! < nowMs &&
        loan.remainingPrincipal > 0;

    String? dueDateStr;
    Color dueColor = c.textTertiary;
    if (loan.dueDate != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(loan.dueDate!);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      dueDateStr = 'Hạn: $dd/$mm/${d.year}';
      if (isOverdue) dueColor = AppColors.error;
    }

    return FrostedCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
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
                      icon: isBorrowed
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      tint: colorText,
                      size: 42,
                      radius: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.personName,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (dueDateStr != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              dueDateStr,
                              style: TextStyle(
                                color: dueColor,
                                fontSize: 11,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn khoản vay',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                icon: const Icon(Icons.more_horiz_rounded, size: 21),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa khoản vay')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa khoản vay')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  formatVND(loan.remainingPrincipal),
                  style: TextStyle(
                    color: colorText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRepay,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    isBorrowed ? 'Trả một phần' : 'Thu một phần',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    _amountController =
        TextEditingController(text: widget.loan.remainingPrincipal.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
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
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          const Overline('SỐ TIỀN THANH TOÁN'),
          const SizedBox(height: 6),
          FinoraTextField(
            controller: _amountController,
            hint: '0 ₫',
            keyboardType: TextInputType.number,
            inputFormatters: [DotSeparatorTextInputFormatter()],
            radius: 18,
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Overline('CHỌN VÍ THỰC HIỆN'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in wallets)
                  FilterChipX(
                    label: w.name,
                    selected: _selectedWallet?.id == w.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedWallet = w);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy', style: TextStyle(color: c.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  expand: true,
                  onPressed: _isSaving ? null : _submit,
                  isLoading: _isSaving,
                  child: const Text('Xác nhận',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddLoanPage extends StatefulWidget {
  final String userId;
  final String initialType;
  final Loan? loan;
  const AddLoanPage({
    super.key,
    required this.userId,
    required this.initialType,
    this.loan,
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
    final loan = widget.loan;
    if (loan != null) {
      _personController.text = loan.personName;
      _amountController.text = loan.principalAmount.toString();
      _dueDate = loan.dueDate;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GlassCalendarPicker(
        initialDate: _dueDate != null
            ? DateTime.fromMillisecondsSinceEpoch(_dueDate!)
            : now,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked.millisecondsSinceEpoch);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final person = _personController.text.trim();
    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (person.isEmpty || amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final loan = Loan(
        id: widget.loan?.id ?? '',
        userId: widget.userId,
        personName: person,
        type: _type,
        principalAmount: amount,
        amount: amount,
        paidAmount: widget.loan?.paidAmount ?? 0,
        remainingPrincipal:
            (amount - (widget.loan?.paidAmount ?? 0)).clamp(0, amount),
        startDate: widget.loan?.startDate ?? now,
        dueDate: _dueDate,
        status: widget.loan?.status ?? 'active',
        walletId: _selectedWallet?.id ?? '',
        walletName: _selectedWallet?.name,
        createdAt: widget.loan?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.loan == null) {
        await context.read<MoreProvider>().addLoan(widget.userId, loan);
      } else {
        await context
            .read<MoreProvider>()
            .updateLoan(widget.userId, widget.loan!.id, loan);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wallets = context.watch<MoreProvider>().wallets;
    if (_selectedWallet == null && wallets.isNotEmpty) {
      final linkedId = widget.loan?.walletId;
      _selectedWallet = wallets.first;
      for (final wallet in wallets) {
        if (wallet.id == linkedId) _selectedWallet = wallet;
      }
    }

    String dateStr = 'Chọn ngày hết hạn';
    if (_dueDate != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(_dueDate!);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      dateStr = '$dd/$mm/${d.year}';
    }

    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.loan != null
            ? 'Sửa khoản vay & nợ'
            : (_type == 'lent' ? 'Ghi nhận cho vay' : 'Ghi nhận đi vay'),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('LOẠI KHOẢN NỢ'),
                        const SizedBox(height: 6),
                        SegmentedControl(
                          options: const [
                            ('lent', 'Phải thu (Cho vay)'),
                            ('borrowed', 'Phải trả (Đi vay)'),
                          ],
                          selected: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),
                        const SizedBox(height: 14),
                        const Overline('ĐỐI TƯỢNG (NGƯỜI VAY / CHỦ NỢ)'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _personController,
                          hint: 'Nhập họ và tên...',
                          radius: 18,
                        ),
                        const SizedBox(height: 14),
                        const Overline('SỐ TIỀN'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _amountController,
                          hint: '0 ₫',
                          keyboardType: TextInputType.number,
                          inputFormatters: [DotSeparatorTextInputFormatter()],
                          radius: 18,
                        ),
                        const SizedBox(height: 14),
                        const Overline('HẠN TRẢ NỢ (TÙY CHỌN)'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pickDate();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF141F3C)
                                  : const Color(0xFFF6F9FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF202D4E)
                                    : const Color(0xFFE8EEF8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? c.textPrimary
                                        : c.textTertiary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (wallets.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Overline('VÍ THANH TOÁN LIÊN KẾT'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final w in wallets)
                                FilterChipX(
                                  label: w.name,
                                  selected: _selectedWallet?.id == w.id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedWallet = w);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                isLoading: _isSaving,
                child: Text(
                    widget.loan == null ? 'Lưu khoản nợ' : 'Lưu thay đổi',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
