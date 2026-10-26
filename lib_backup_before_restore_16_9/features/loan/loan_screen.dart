import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/wallet_provider.dart';
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
        isDark ? AppColors.darkTextSecondary : const Color(0xFF7A90A5);

    final provider = context.watch<MoreProvider>();
    final loans = provider.loans;

    final isLent = _activeTab == 'lent';
    final filtered = loans
        .where((l) => l.type == _activeTab && l.status == 'active')
        .toList();
    final totalRemaining =
        filtered.fold<int>(0, (s, l) => s + l.remainingPrincipal);

    final money = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Header: head('Khoản vay & cho vay', 'Giữ lời hẹn với dòng tiền', btn('plus', 'notice'))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khoản vay & cho vay',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giữ lời hẹn với dòng tiền',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1D354B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C4861) : const Color(0xFFDCE5EF),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _openAdd,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1D354B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C4861) : const Color(0xFFDCE5EF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF224E74).withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            size: 19,
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Tabs: tabs(['Đi vay', 'Cho vay'], 'loan')
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C3146) : const Color(0xFFE6EEF5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF284460) : const Color(0xFFE2EBF3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabPill('Đi vay', !isLent, () {
                        setState(() => _activeTab = 'borrowed');
                      }, isDark),
                      const SizedBox(width: 4),
                      _buildTabPill('Cho vay', isLent, () {
                        setState(() => _activeTab = 'lent');
                      }, isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Hero Ink Card: .hero.ink
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F374F), Color(0xFF152738)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF122B47).withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KỲ THANH TOÁN TIẾP THEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF91AAC5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '25',
                                    style: TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / 09',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF91AAC5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Còn 8 ngày',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF91AAC5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isLent ? '2.000.000 ₫' : '3.500.000 ₫',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLent ? 'Minh · Hẹn hoàn trả' : 'Khoản vay mua xe',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF91AAC5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () {
                        if (filtered.isNotEmpty) {
                          _showRepayDialog(filtered.first);
                        } else {
                          _openAdd();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 49,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isLent ? 'Ghi nhận thu tiền' : 'Ghi nhận thanh toán',
                            style: const TextStyle(
                              color: Color(0xFF173452),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // 4. Section: Lộ trình thanh toán + 'Xem lịch ↗'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lộ trình thanh toán',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lịch thanh toán chi tiết')),
                      );
                    },
                    child: const Text(
                      'Xem lịch ↗',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF005FEA),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timeline (.timeline)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.only(left: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(0xFFDCE7F0),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildTimelineEvent(
                      month: 'Tháng 8',
                      badge: '· Đã trả',
                      badgeColor: const Color(0xFF17876A),
                      detail: isLent ? '2.000.000 ₫ · 25/08/2026' : '3.500.000 ₫ · 25/08/2026',
                      dotColor: const Color(0xFF17876A),
                      isDark: isDark,
                    ),
                    _buildTimelineEvent(
                      month: 'Tháng 9',
                      badge: '· Sắp đến hạn',
                      badgeColor: const Color(0xFFC68A27),
                      detail: isLent ? '2.000.000 ₫ · 25/09/2026' : '3.500.000 ₫ · 25/09/2026',
                      dotColor: const Color(0xFF005FEA),
                      isDark: isDark,
                    ),
                    _buildTimelineEvent(
                      month: 'Tháng 10',
                      badge: null,
                      badgeColor: null,
                      detail: isLent ? '2.000.000 ₫ · 25/10/2026' : '3.500.000 ₫ · 25/10/2026',
                      dotColor: const Color(0xFFB0C4D6),
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Split Card: Dư nợ còn lại
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2F44) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C4861) : const Color(0xFFE7ECF1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF224E74).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLent ? 'Số tiền cần thu lại' : 'Dư nợ còn lại',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      totalRemaining > 0
                          ? '${money.format(totalRemaining)} ₫'
                          : (isLent ? '8.000.000 ₫' : '42.000.000 ₫'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF142438),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // 6. Real Loans List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isLent ? "Danh sách cho vay" : "Danh sách vay nợ"} (${filtered.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C3146) : const Color(0xFFE8F1FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: Color(0xFF005FEA),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Thêm',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF005FEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2F44) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C4861) : const Color(0xFFE7ECF1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.hand_coins,
                        size: 32,
                        color: isLent ? const Color(0xFF16846C) : const Color(0xFF005FEA),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isLent ? 'Chưa có khoản cho vay nào' : 'Chưa có khoản vay nợ nào',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhấn Thêm để ghi nhận giao dịch vay mượn mới',
                        style: TextStyle(fontSize: 11.5, color: secondaryTextColor),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((loan) => _loanCard(loan, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF284562) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF355C80).withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF1769DA)
                : (isDark ? const Color(0xFFABC0D3) : const Color(0xFF71869B)),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineEvent({
    required String month,
    required String? badge,
    required Color? badgeColor,
    required String detail,
    required Color dotColor,
    required bool isDark,
    bool isLast = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -27,
          top: 3,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? const Color(0xFF17876A),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                ),
              ),
            ],
          ),
        ),
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
        color: dark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF1E293B))
                .withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 16,
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
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
