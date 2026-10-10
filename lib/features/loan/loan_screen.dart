import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/finora_summary_card.dart';
import '../../core/design_system/v8/finora_v8.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/wallet_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../core/widgets/finora_motion.dart';

class LoanScreen extends StatefulWidget {
  final String userId;
  const LoanScreen({super.key, required this.userId});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String _activeTab = 'lent'; // 'lent' (Cho vay) | 'borrowed' (Vay nợ)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MoreProvider>().load(widget.userId);
        context.read<WalletProvider>().load(widget.userId);
      }
    });
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassBottomSheet(
          radius: 30,
          child: _AddLoanSheet(userId: widget.userId, initialType: _activeTab)),
    );
  }

  void _showRepayDialog(Loan loan) {
    final controller = TextEditingController();
    final walletProvider = context.read<WalletProvider>();
    final wallets = walletProvider.wallets;
    String selectedWalletId = wallets.isNotEmpty ? wallets.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
              '${loan.type == 'lent' ? 'Thu hồi nợ' : 'Trả nợ'}: ${loan.personName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Số tiền còn lại: ${NumberFormat('#,##0', 'vi_VN').format(loan.remainingPrincipal)} đ'),
              const SizedBox(height: 12),
              if (wallets.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedWalletId,
                  decoration: InputDecoration(
                    labelText:
                        loan.type == 'lent' ? 'Ví nhận tiền' : 'Ví trả tiền',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  items: wallets.map((w) {
                    return DropdownMenuItem<String>(
                      value: w.id,
                      child: Text(w.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedWalletId = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [DotSeparatorTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: loan.type == 'lent'
                      ? 'Số tiền thu (VNĐ)'
                      : 'Số tiền trả (VNĐ)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                final digits =
                    controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                final amount = int.tryParse(digits) ?? 0;
                if (amount > 0 &&
                    amount <= loan.remainingPrincipal &&
                    selectedWalletId.isNotEmpty) {
                  final provider = context.read<MoreProvider>();
                  final opId = provider.newRepaymentId(widget.userId);
                  await provider.repayLoan(
                    widget.userId,
                    loan.id,
                    selectedWalletId,
                    amount,
                    opId,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final provider = context.watch<MoreProvider>();
    final loans = provider.loans;

    final isLent = _activeTab == 'lent';
    final filtered = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .toList();
    final totalRemaining =
        filtered.fold<int>(0, (s, l) => s + l.remainingPrincipal);

    final displayTotal = totalRemaining;
    final totalPaid = filtered.fold<int>(0, (s, l) => s + l.paidAmount);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Khoản vay & Sổ nợ',
        showBottomDivider: false,
        onBack: () => Navigator.pop(context),
        actions: const [],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                GlassScaffold.topInset(context, 8),
                16,
                8,
              ),
              child: _buildLoanSummaryCard(
                isLent: isLent,
                filteredCount: filtered.length,
                displayTotal: displayTotal,
                totalPaid: totalPaid,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: BouncyPillTabs(
                labels: const ['Cho vay', 'Vay nợ'],
                selectedIndex: _activeTab == 'lent' ? 0 : 1,
                colors: const [Color(0xFF059669), Color(0xFFDC2626)],
                height: 48,
                onChanged: (i) => setState(
                    () => _activeTab = i == 0 ? 'lent' : 'borrowed'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 4. Section: DANH SÁCH CHO VAY + "+ Thêm" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isLent ? "DANH SÁCH CHO VAY" : "DANH SÁCH VAY NỢ"} (${filtered.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    FinoraAddButton(
                      onPressed: _openAdd,
                      tooltip: 'Thêm khoản vay',
                      size: 34,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Loan Items List
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                          .withValues(
                              alpha: context
                                  .watch<ThemeStudioController>()
                                  .glassOpacity),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(children: [
                      Icon(Icons.handshake_outlined,
                          size: 36,
                          color: isLent
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444)),
                      const SizedBox(height: 10),
                      Text(
                        isLent
                            ? 'Chưa có khoản cho vay'
                            : 'Bạn chưa có khoản vay nợ',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      FinoraButton(
                        onPressed: _openAdd,
                        variant: FinoraButtonVariant.compact,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded),
                            SizedBox(width: FinoraV8Space.x1),
                            Text('Thêm khoản mới'),
                          ],
                        ),
                      ),
                    ]),
                  )
                else
                  for (int i = 0; i < filtered.length; i++)
                    FinoraStaggeredItem(
                      index: i,
                      child: _loanCard(filtered[i], isDark),
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSummaryCard({
    required bool isLent,
    required int filteredCount,
    required int displayTotal,
    required int totalPaid,
  }) {
    final accent = isLent ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    return FinoraSummaryCard(
      title: isLent ? 'TỔNG CẦN THU VỀ' : 'TỔNG CẦN TRẢ ĐI',
      amount: displayTotal,
      icon: isLent ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      accent: accent,
      subtitle: isLent
          ? 'Các khoản cho vay đang theo dõi trong sổ'
          : 'Các khoản vay nợ cần thanh toán đúng hạn',
      badgeText: '$filteredCount ${isLent ? "khoản cho vay" : "khoản vay nợ"}',
      badgeColor: accent,
      metricColors: [accent, const Color(0xFF007AFF)],
      metrics: [
        ('Còn lại', displayTotal),
        (isLent ? 'Đã thu' : 'Đã trả', totalPaid),
      ],
    );
  }

  void _confirmDeleteLoan(Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa khoản vay "${loan.personName}" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<MoreProvider>()
                  .deleteLoan(widget.userId, loan.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _loanCard(Loan loan, bool dark) {
    final lent = loan.type == 'lent';
    final accent = lent ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final progress = loan.principalAmount > 0
        ? (loan.paidAmount / loan.principalAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();
    final money = NumberFormat('#,##0', 'vi_VN');

    // Extract first letter of personName
    String initial = '';
    final trimmed = loan.personName.trim();
    if (trimmed.isNotEmpty) {
      initial = trimmed.characters.first.toUpperCase();
    } else {
      initial = lent ? 'C' : 'V';
    }

    final List<List<Color>> palette = [
      [const Color(0xFF0284C7), const Color(0xFF38BDF8)], // Sky
      [const Color(0xFF059669), const Color(0xFF34D399)], // Emerald
      [const Color(0xFFD97706), const Color(0xFFFBBF24)], // Amber
      [const Color(0xFF2563EB), const Color(0xFF60A5FA)], // Royal Blue
      [const Color(0xFF0D9488), const Color(0xFF2DD4BF)], // Teal
      [const Color(0xFFE11D48), const Color(0xFFFB7185)], // Rose
      [const Color(0xFFEA580C), const Color(0xFFFB923C)], // Orange
    ];
    final colorPair = palette[loan.personName.hashCode.abs() % palette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: context.watch<ThemeStudioController>().glassOpacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? const Color(0xFF334155).withValues(alpha: 0.8)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name + Badges, Percent Pill
          Row(
            children: [
              // Avatar with initial letter
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colorPair,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorPair[0].withValues(alpha: dark ? 0.35 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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
                      loan.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (lent
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626))
                                .withValues(alpha: dark ? 0.22 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lent ? 'Khoản cho vay' : 'Khoản vay nợ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: lent
                                  ? (dark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669))
                                  : (dark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFDC2626)),
                            ),
                          ),
                        ),
                        if (loan.startDate > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•  ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(loan.startDate))}',
                            style: TextStyle(
                              fontSize: 11,
                              color: dark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (percent >= 100
                          ? const Color(0xFF059669)
                          : (dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9)))
                      .withValues(
                          alpha: percent >= 100 ? (dark ? 0.25 : 0.12) : 1.0),
                  borderRadius: BorderRadius.circular(100),
                  border: percent >= 100
                      ? Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                          width: 1)
                      : null,
                ),
                child: percent >= 100
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 3),
                          Text(
                            'Tất toán',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '$percent%',
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: dark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (val) {
                  if (val == 'repay') {
                    _showRepayDialog(loan);
                  } else if (val == 'delete') {
                    _confirmDeleteLoan(loan);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'repay',
                    child: Row(
                      children: [
                        Icon(
                          lent
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Text(lent ? 'Thu hồi nợ' : 'Trả nợ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Xóa khoản vay',
                            style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Hairline divider
          Divider(
            height: 1,
            thickness: 1,
            color: dark
                ? const Color(0xFF334155).withValues(alpha: 0.6)
                : const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 12),

          // Amount & Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Còn lại: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        FinoraAnimatedAmount(
                          amount: loan.remainingPrincipal.toDouble(),
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color:
                                dark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gốc: ${money.format(loan.principalAmount)} đ  •  Đã ${lent ? "thu" : "trả"}: ${money.format(loan.paidAmount)} đ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showRepayDialog(loan),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lent
                          ? const [Color(0xFF059669), Color(0xFF10B981)]
                          : const [Color(0xFFDC2626), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: dark ? 0.35 : 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lent
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        lent ? 'Thu hồi nợ' : 'Trả nợ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Modern Rounded Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: accent,
              backgroundColor:
                  dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet to Add Loan
class _AddLoanSheet extends StatefulWidget {
  final String userId;
  final String initialType;
  const _AddLoanSheet({required this.userId, required this.initialType});

  @override
  State<_AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<_AddLoanSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late String _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: context.watch<ThemeStudioController>().glassOpacity),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _type == 'lent' ? 'Thêm khoản cho vay' : 'Thêm khoản vay nợ',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryTextColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _type == 'lent' ? 'Tên người vay' : 'Tên chủ nợ',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [DotSeparatorTextInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Số tiền (VNĐ)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final digits =
                    _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final amount = int.tryParse(digits) ?? 0;
                if (name.isNotEmpty && amount > 0) {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final loan = Loan(
                    userId: widget.userId,
                    personName: name,
                    type: _type,
                    principalAmount: amount,
                    amount: amount,
                    remainingPrincipal: amount,
                    startDate: now,
                  );
                  await context
                      .read<MoreProvider>()
                      .addLoan(widget.userId, loan);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: const StadiumBorder(),
              ),
              child: const Text('Lưu khoản vay',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
