import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/wallet_provider.dart';

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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Thu nợ: ${loan.personName}'),
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
                    labelText: 'Ví nhận tiền',
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
                  labelText: 'Số tiền thu (VNĐ)',
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
                if (amount > 0) {
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
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Top Header Row: Back button + Title "Khoản vay & Nợ" + Add (+ Thêm) Purple Button
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: primaryTextColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Vay & Nợ',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: primaryTextColor)),
                    const SizedBox(height: 3),
                    Text('Quản lý các khoản bạn nợ và người nợ bạn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5, color: secondaryTextColor)),
                  ])),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openAdd,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 23),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // 2. Tabs: Cho vay | Vay nợ
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _buildTab('lent', 'Cho vay', isDark),
                  _buildTab('borrowed', 'Vay nợ', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hero Emerald Card: "TỔNG CẦN THU VỀ" (Matching Screenshot)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isLent
                      ? const [Color(0xFF059669), Color(0xFF10B981)]
                      : const [Color(0xFFDC2626), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLent
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626))
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLent ? 'TỔNG CẦN THU VỀ' : 'TỔNG CẦN TRẢ ĐI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filtered.length} ${isLent ? 'khoản cho vay' : 'khoản vay nợ'}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${NumberFormat('#,##0', 'vi_VN').format(displayTotal)} đ',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${isLent ? 'Đã thu' : 'Đã trả'}: ${NumberFormat('#,##0', 'vi_VN').format(totalPaid)} đ',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Còn lại: ${NumberFormat('#,##0', 'vi_VN').format(displayTotal)} đ',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 4. Section: DANH SÁCH CHO VAY
            Text(
              '${isLent ? "DANH SÁCH CHO VAY" : "DANH SÁCH VAY NỢ"} (${filtered.length})',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: secondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Loan Items List
            if (filtered.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _openAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm khoản'),
                  )
                ]),
              ),
            ] else ...[
              for (final loan in filtered)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('💸', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.personName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gốc: ${NumberFormat('#,##0', 'vi_VN').format(loan.principalAmount)} đ',
                              style: TextStyle(
                                  fontSize: 12, color: secondaryTextColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Còn: ${NumberFormat('#,##0', 'vi_VN').format(loan.remainingPrincipal)} đ',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showRepayDialog(loan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Thu một phần',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loanSummaryCard(
          {required String title,
          required int amount,
          required int count,
          required Color color,
          required IconData icon,
          required bool dark}) =>
      Container(
        height: 145,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: dark ? .20 : .09),
            color.withValues(alpha: dark ? .07 : .015)
          ]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 16,
                offset: const Offset(0, 7))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 21)),
            const SizedBox(width: 9),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800)))
          ]),
          const SizedBox(height: 11),
          Text('${NumberFormat('#,##0', 'vi_VN').format(amount)} đ',
              maxLines: 1,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(99)),
              child: Text('$count khoản',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: color))),
        ]),
      );

  Widget _buildTab(String key, String label, bool isDark) {
    final selected = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color:
                  selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoLoanItem({
    required String title,
    required String amount,
    required String date,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('💸', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gốc: $amount · $date',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Còn: $amount',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text(
              'Thu một phần',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
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
