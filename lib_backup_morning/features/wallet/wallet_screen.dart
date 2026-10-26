import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/wallet.dart';
import '../../state/wallet_provider.dart';
import '../../state/transaction_provider.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_screen.dart';
import 'add_wallet_page.dart';

class WalletScreen extends StatefulWidget {
  final String userId;
  final bool isRoot;
  const WalletScreen({super.key, required this.userId, this.isRoot = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final PageController _pageController;
  int _selectedCardIndex = 0;
  String _selectedMember = 'all'; // 'all', 'husband', 'wife'
  bool _cardView = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().load(widget.userId);
      context.read<TransactionProvider>().load(widget.userId);
    });
  }

  Widget _viewToggle(IconData icon, bool selected, VoidCallback onTap, bool dark) =>
      Material(
        color: selected
            ? const Color(0xFF2563EB)
            : (dark ? Colors.white10 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
              width: 38,
              height: 36,
              child: Icon(icon,
                  size: 19,
                  color: selected ? Colors.white : const Color(0xFF64748B))),
        ),
      );

  Widget _walletCardGroups(List<Wallet> wallets, bool dark) {
    if (wallets.isEmpty) return _emptyWalletCard(dark);
    final bank = wallets.where((w) => w.type == 'bank').toList();
    final cash = wallets.where((w) => w.type == 'cash').toList();
    final credit = wallets.where((w) => w.isCreditCard).toList();
    return Column(children: [
      if (bank.isNotEmpty) _walletCardGroup('Tài khoản ngân hàng', bank, 0),
      if (cash.isNotEmpty) _walletCardGroup('Tiền mặt', cash, bank.length),
      if (credit.isNotEmpty) _walletCardGroup('Thẻ tín dụng', credit, bank.length + cash.length),
    ]);
  }

  Widget _walletCardGroup(String title, List<Wallet> items, int offset) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _compactBankCard(items[index], offset + index),
            ),
          ),
        ]),
      );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openAdd([Wallet? wallet]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddWalletPage(userId: widget.userId, wallet: wallet),
      ),
    );
  }

  void _payCreditCard(Wallet wallet) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionPage(
        userId: widget.userId,
        initialType: 'credit_card_payment',
        initialToWalletId: wallet.id,
      ),
    ));
  }

  void _showWalletDetailSheet(Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WalletTransactionSheet(
        userId: widget.userId,
        wallet: wallet,
      ),
    );
  }

  List<Wallet> _filterByMember(List<Wallet> wallets) {
    if (_selectedMember == 'joint') {
      return wallets.where(OwnerFilter.joint.matchWallet).toList();
    }
    if (_selectedMember == 'husband') {
      return wallets
          .where((w) => w.owner == 'husband' || w.ownerName == 'Chồng')
          .toList();
    } else if (_selectedMember == 'wife') {
      return wallets
          .where((w) => w.owner == 'wife' || w.ownerName == 'Vợ')
          .toList();
    }
    return wallets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final wallets = _filterByMember(walletProvider.wallets);
    var available = 0;
    var debt = 0;
    for (final wallet in wallets) {
      if (wallet.isCreditCard) {
        debt += wallet.currentDebt;
      } else {
        available += wallet.balance;
      }
    }
    final now = DateTime.now();
    final monthTxs = txProvider.transactions.where((tx) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
      return date.year == now.year && date.month == now.month;
    });
    final incomeTypes = {'income', 'borrowing', 'loan_repayment_received'};
    final monthIncome = monthTxs
        .where((tx) => incomeTypes.contains(tx.type))
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final monthExpense = monthTxs
        .where((tx) => !incomeTypes.contains(tx.type))
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFF),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.isRoot && Navigator.canPop(context)) ...[
                _walletCircleButton(Icons.chevron_left_rounded,
                    () => Navigator.pop(context), isDark),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ví tiền',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.7,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const SizedBox(height: 3),
                      Text('Quản lý tất cả ví của bạn',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF7C86A0))),
                    ]),
              ),
              _walletCircleButton(Icons.add_rounded, () => _openAdd(), isDark,
                  gradient: const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  foreground: Colors.white),
            ]),
            const SizedBox(height: 17),
            _walletBalanceHero(available - debt, available, debt),
            const SizedBox(height: 19),
            Row(children: [
              const Expanded(child: Text('Thẻ & tài khoản', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              _viewToggle(Icons.view_agenda_outlined, !_cardView, () => setState(() => _cardView = false), isDark),
              const SizedBox(width: 6),
              _viewToggle(Icons.credit_card_rounded, _cardView, () => setState(() => _cardView = true), isDark),
            ]),
            const SizedBox(height: 10),
            if (_cardView)
              _walletCardGroups(wallets, isDark)
            else Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172033) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE8EDF5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .035),
                      blurRadius: 18,
                      offset: const Offset(0, 7))
                ],
              ),
              child: wallets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(walletProvider.isRefreshing
                          ? 'Đang tải danh sách ví...'
                          : 'Chưa có ví. Nhấn + để tạo ví mới.'),
                    )
                  : Column(children: [
                      for (var i = 0; i < wallets.length; i++) ...[
                        _walletListRow(wallets[i], i, isDark),
                        if (i != wallets.length - 1)
                          Divider(
                              height: 1,
                              indent: 66,
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFF0F3F8)),
                      ]
                    ]),
            ),
            const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }

  Widget _walletCircleButton(IconData icon, VoidCallback onTap, bool isDark,
      {List<Color>? gradient, Color? foreground}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                gradient == null ? null : LinearGradient(colors: gradient),
            color: gradient == null
                ? (isDark ? Colors.white10 : Colors.white)
                : null,
            boxShadow: [
              BoxShadow(
                  color: (gradient?.last ?? Colors.black)
                      .withValues(alpha: gradient == null ? .05 : .28),
                  blurRadius: 12,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Icon(icon,
              size: 22,
              color: foreground ??
                  (isDark ? Colors.white : const Color(0xFF0F172A))),
        ),
      ),
    );
  }

  void _showWalletHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Quản lý Ví tiền',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                'Nhấn vào một ví để xem giao dịch. Nhấn nút ⋮ để chỉnh sửa thông tin, số dư, ngân hàng hoặc thẻ.'),
          ]),
        ),
      ),
    );
  }

  Widget _walletBalanceHero(int net, int assets, int debt) {
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF086623), Color(0xFF4C9A2A), Color(0xFFA9D6E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF086623).withValues(alpha: .25),
              blurRadius: 25,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('Tổng số dư',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: .86))),
            const Spacer(),
            SubjectFilterPill(
              selected: OwnerFilter.fromString(_selectedMember),
              onColoredSurface: true,
              onSelected: (value) => setState(() => _selectedMember = value.value),
            ),
          ]),
          const SizedBox(height: 8),
          Text('${NumberFormat('#,##0', 'vi_VN').format(net)} đ',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -.6)),
          const SizedBox(height: 14),
          Row(children: [
            _walletHeroMetric('Tổng tài sản', assets, const Color(0xFF86EFAC)),
            Container(width: 1, height: 37, color: Colors.white30),
            const SizedBox(width: 17),
            _walletHeroMetric('Tổng nợ', debt, const Color(0xFFFF8A80)),
          ]),
        ],
      ),
    );
  }

  Widget _walletHeroMetric(String label, int value, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 3),
          Text('${NumberFormat('#,##0', 'vi_VN').format(value)} đ',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w900, color: color)),
        ]),
      );

  Widget _walletSectionHeader(String title, String action, IconData? icon) {
    return Row(children: [
      Expanded(
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ),
      Text(action,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C86A0))),
      if (icon != null) ...[
        const SizedBox(width: 5),
        Icon(icon, size: 18, color: const Color(0xFF7C86A0)),
      ] else
        const Icon(Icons.chevron_right_rounded,
            size: 18, color: Color(0xFF7C86A0)),
    ]);
  }

  Widget _compactBankCard(Wallet wallet, int index) {
    final palettes = [
      const [Color(0xFF111631), Color(0xFF1E2A68)],
      const [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
      const [Color(0xFF065F46), Color(0xFF14B8A6)],
      const [Color(0xFF991B1B), Color(0xFFEF4444)],
    ];
    final brand = BankIconRegistry.resolve(wallet.bankCode,
        bankName: wallet.bankName);
    final colors = wallet.type == 'cash'
        ? const [Color(0xFF047857), Color(0xFF34D399)]
        : [brand.color.withValues(alpha: .94), palettes[index % palettes.length].last];
    final digits = (wallet.accountNumber ?? '••••').replaceAll(' ', '');
    final suffix =
        digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    return GestureDetector(
      onTap: () => _showWalletDetailSheet(wallet),
      onLongPress: () => _openAdd(wallet),
      child: Container(
        width: 224,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white24),
          boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .18), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 196,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                BankIcon(
                    bankCode: wallet.bankCode,
                    bankName: wallet.bankName,
                    size: 29),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(wallet.bankName ?? wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
                if (wallet.isCreditCard)
                  const Text('VISA', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Text(wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 3),
              Text('${NumberFormat('#,##0', 'vi_VN').format(wallet.isCreditCard ? wallet.currentDebt : wallet.balance)} đ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 10),
              Text(wallet.type == 'cash' ? 'TIỀN MẶT' : '•••• $suffix',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              if (wallet.isCreditCard) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Text(wallet.ownerName.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white70))),
                  InkWell(onTap: () => _payCreditCard(wallet), child: const Text('Thanh toán', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w900))),
                ]),
              ] else ...[
                const SizedBox(height: 3),
                Text(wallet.ownerName.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _emptyWalletCard(bool isDark) => Container(
        width: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(18)),
        child: const Text('Chưa có thẻ hoặc tài khoản'),
      );

  Widget _walletListRow(Wallet wallet, int index, bool isDark) {
    final accents = const [
      Color(0xFF8B5CF6),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
    ];
    final accent = accents[index % accents.length];
    final balance = wallet.isCreditCard ? -wallet.currentDebt : wallet.balance;
    return InkWell(
      onTap: () => _showWalletDetailSheet(wallet),
      onLongPress: () => _openAdd(wallet),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          wallet.type == 'cash'
              ? Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: .14),
                      shape: BoxShape.circle),
                  child: Icon(Icons.payments_rounded, color: accent, size: 23))
              : BankIcon(
                  bankCode: wallet.bankCode,
                  bankName: wallet.bankName,
                  size: 44),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A))),
                ),
                if (index == 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Mặc định',
                        style:
                            TextStyle(fontSize: 9, color: Color(0xFF7C3AED))),
                  ),
                ]
              ]),
              const SizedBox(height: 3),
              Text(
                  wallet.isCreditCard
                      ? (wallet.bankName ?? 'Thẻ tín dụng')
                      : 'Chi tiêu & quản lý tài chính',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF7C86A0))),
              const SizedBox(height: 3),
              Text(wallet.ownerName,
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accent)),
            ]),
          ),
          const SizedBox(width: 8),
          Text('${NumberFormat('#,##0', 'vi_VN').format(balance)} đ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: balance < 0 ? const Color(0xFFEF4444) : accent)),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFF94A3B8)),
            onSelected: (value) {
              if (value == 'edit') _openAdd(wallet);
              if (value == 'history') _showWalletDetailSheet(wallet);
              if (value == 'pay') _payCreditCard(wallet);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'history', child: Text('Xem giao dịch')),
              if (wallet.isCreditCard)
                const PopupMenuItem(value: 'pay', child: Text('Thanh toán thẻ')),
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa ví/thẻ')),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _walletOverview(int income, int expense, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172033) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE8EDF5))),
      child: Column(children: [
        Row(children: [
          const Expanded(
              child: Text('Tổng quan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(999)),
            child: const Row(children: [
              Text('Tháng này',
                  style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 15, color: Color(0xFF2563EB)),
            ]),
          ),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          _overviewMetric('Tổng thu', income, true),
          const SizedBox(width: 8),
          _overviewMetric('Tổng chi', expense, false),
        ]),
      ]),
    );
  }

  Widget _overviewMetric(String label, int amount, bool income) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: income ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: income
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626))),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  '${income ? '+' : '-'}${NumberFormat('#,##0', 'vi_VN').format(amount)} đ',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: income
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626))),
            ),
          ]),
        ),
      );

  Widget _buildLegacy(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final walletProvider = context.watch<WalletProvider>();
    final allWallets = walletProvider.wallets;
    final filteredWallets = _filterByMember(allWallets);

    final creditCards = filteredWallets.where((w) => w.isCreditCard).toList();
    final bankAccounts = filteredWallets.where((w) => !w.isCreditCard).toList();

    int totalAvailable = 0;
    int totalDebt = 0;
    for (final w in filteredWallets) {
      if (w.isCreditCard) {
        totalDebt += w.currentDebt;
      } else {
        totalAvailable += w.balance;
      }
    }
    final netWorth = totalAvailable - totalDebt;

    final displayNet = netWorth;
    final displayAvailable = totalAvailable;
    final displayDebt = totalDebt;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // 1. Top Bar: Back button (if push) + Title "Ví tiền"
            Row(
              children: [
                if (!widget.isRoot && Navigator.of(context).canPop()) ...[
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
                  const SizedBox(width: 10),
                ],
                Text(
                  'Ví & Tài khoản',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _openAdd(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Member Segmented Tab: Tất cả / Chồng / Vợ (Dark Navy Active Pill)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildMemberTab('all', 'Tất cả', isDark),
                  _buildMemberTab('husband', 'Chồng', isDark),
                  _buildMemberTab('wife', 'Vợ', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Hero Violet/Purple Card: "TỔNG TÀI SẢN VÍ & THẺ" (Matching Screenshot)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F2747),
                    Color(0xFF075985),
                    Color(0xFF0891B2),
                    Color(0xFF06B6D4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                        'TỔNG TÀI SẢN VÍ & THẺ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filteredWallets.length} tài khoản',
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
                    '${NumberFormat('#,##0', 'vi_VN').format(displayNet)} đ',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiền mặt khả dụng',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${NumberFormat('#,##0', 'vi_VN').format(displayAvailable)} đ',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6EE7B7)),
                            ),
                          ],
                        ),
                        Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.15)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Dư nợ thẻ tín dụng',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${NumberFormat('#,##0', 'vi_VN').format(displayDebt)} đ',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFDA4AF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Section: THẺ TÍN DỤNG + "+ Thêm thẻ"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('💳 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'THẺ TÍN DỤNG',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openAdd(),
                  child: const Text(
                    '+ Thêm thẻ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Swipe Deck for Credit Cards
            if (creditCards.isNotEmpty) ...[
              SizedBox(
                height: 195,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: creditCards.length,
                  onPageChanged: (i) => setState(() => _selectedCardIndex = i),
                  itemBuilder: (ctx, i) {
                    final card = creditCards[i];
                    return GestureDetector(
                      onTap: () => _showWalletDetailSheet(card),
                      child: _buildCreditCardItem(card, i == 0),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (creditCards.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(creditCards.length, (i) {
                    final isSel = i == _selectedCardIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSel ? 16 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
            ] else ...[
              GestureDetector(
                onTap: () => _openAdd(),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      '+ Bấm để thêm thẻ tín dụng đầu tiên',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 4. Section: TÀI KHOẢN NGÂN HÀNG & TIỀN MẶT + "+ Thêm tài khoản"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🏦 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'TÀI KHOẢN & TIỀN MẶT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openAdd(),
                  child: const Text(
                    '+ Thêm tài khoản',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bank Accounts & Cash List
            for (final acc in bankAccounts) ...[
              GestureDetector(
                onTap: () => _showWalletDetailSheet(acc),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      if (acc.type == 'cash')
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child:
                              const Text('💵', style: TextStyle(fontSize: 20)),
                        )
                      else
                        BankIcon(bankCode: acc.bankCode ?? 'VCB', size: 42),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (acc.owner == 'wife' ||
                                        acc.ownerName == 'Vợ')
                                    ? const Color(0xFFFCE7F3)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                acc.owner == 'wife' || acc.ownerName == 'Vợ'
                                    ? 'Vợ'
                                    : 'Chồng',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: (acc.owner == 'wife' ||
                                          acc.ownerName == 'Vợ')
                                      ? const Color(0xFFDB2777)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${NumberFormat('#,##0', 'vi_VN').format(acc.balance)} đ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Số dư',
                            style: TextStyle(
                                fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTab(String key, String label, bool isDark) {
    final selected = _selectedMember == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMember = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF334155) : const Color(0xFF1E1B4B))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(Wallet card, bool isGold) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isGold
              ? const [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)]
              : const [Color(0xFF475569), Color(0xFF334155), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGold ? const Color(0xFFD97706) : const Color(0xFF334155))
                .withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDF7A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isGold ? 'GOLD CARD' : 'SILVER CARD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                card.bankName ??
                    (card.bankCode?.toUpperCase() ?? 'TECHCOMBANK'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            card.accountNumber?.isNotEmpty == true
                ? '•••• •••• •••• ${card.accountNumber!.substring(card.accountNumber!.length.clamp(0, 4))}'
                : '•••• •••• •••• 8868',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHỦ THẺ',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    card.ownerName ?? 'Louis XX',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HẠN MỨC KHẢ DỤNG',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${NumberFormat('#,##0', 'vi_VN').format(card.creditLimit - card.currentDebt)} đ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Modal Bottom Sheet: Chi tiết giao dịch khi ấn vào từng ví (Matching Chi tiết giao dịch khi ấn vào từng ví.jpg)
class _WalletTransactionSheet extends StatefulWidget {
  final String userId;
  final Wallet wallet;

  const _WalletTransactionSheet({
    required this.userId,
    required this.wallet,
  });

  @override
  State<_WalletTransactionSheet> createState() =>
      _WalletTransactionSheetState();
}

class _WalletTransactionSheetState extends State<_WalletTransactionSheet> {
  String _filter = 'all'; // 'all', 'this_month', 'last_month'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final txProvider = context.watch<TransactionProvider>();
    final allTxs = txProvider.transactions;
    final now = DateTime.now();

    final walletTxs = allTxs.where((t) {
      final match = t.walletId == widget.wallet.id ||
          t.fromWalletId == widget.wallet.id ||
          t.toWalletId == widget.wallet.id ||
          t.creditCardId == widget.wallet.id;
      if (!match) return false;

      if (_filter == 'this_month') {
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        return d.year == now.year && d.month == now.month;
      } else if (_filter == 'last_month') {
        final lastM = DateTime(now.year, now.month - 1, 1);
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        return d.year == lastM.year && d.month == lastM.month;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Card of Wallet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.wallet.type == 'cash')
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('💵', style: TextStyle(fontSize: 22)),
                  )
                else
                  BankIcon(bankCode: widget.wallet.bankCode ?? 'VCB', size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.wallet.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Số dư: ${NumberFormat('#,##0', 'vi_VN').format(widget.wallet.balance)} đ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: secondaryTextColor,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips: Tất cả | Tháng này | Tháng trước
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip('this_month', 'Tháng này'),
                const SizedBox(width: 8),
                _buildFilterChip('last_month', 'Tháng trước'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Transaction List
          Expanded(
            child: walletTxs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        Text(
                          'Không có giao dịch nào trong khoảng này',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount: walletTxs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tx = walletTxs[i];
                      final isIncome = tx.type == 'income';
                      final sign = isIncome ? '+' : '-';
                      final amountColor = isIncome
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444);
                      final d = DateTime.fromMillisecondsSinceEpoch(tx.date);
                      final dateStr =
                          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                  userId: widget.userId, transaction: tx),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  CategoryIconHelper.resolveIcon(
                                      tx.categoryIcon),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.note?.isNotEmpty == true
                                          ? tx.note!
                                          : (tx.categoryName ?? 'Giao dịch'),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$sign${NumberFormat('#,##0', 'vi_VN').format(tx.amount)} đ',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action: "+ Thêm giao dịch" Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => AddTransactionPage(
                        userId: widget.userId,
                        initialWalletId: widget.wallet.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Thêm giao dịch',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
