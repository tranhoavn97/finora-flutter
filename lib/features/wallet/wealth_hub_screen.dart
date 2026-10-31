import '../../core/widgets/adaptive_glass_surface.dart';
// ignore: unused_import

import '../../core/widgets/fresh_design.dart';

import '../../core/widgets/finora/financial_components.dart'
    show TransactionRow;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../core/design_system/credit_card_palette.dart';

import '../../core/design_system/v8/finora_v8.dart';

import '../../core/utils/formatters.dart';

import '../../core/utils/date_filter.dart';

import '../../core/widgets/glass_widgets.dart';

import '../../core/widgets/finora_mascot.dart';

// ignore: unused_import

import '../../core/widgets/ai_context_button.dart';

import '../../core/widgets/finora_privacy_mask.dart';

import '../../core/widgets/bank_icon.dart';

import '../../core/widgets/date_filter_modal.dart';

import '../../core/widgets/finora_member_filter.dart';

import '../../data/models/finance_models.dart';

import '../../data/models/wallet.dart';

import '../../data/models/transaction.dart';

import '../../state/wallet_provider.dart';

import '../../state/more_provider.dart';

import '../../state/transaction_provider.dart';

import '../../state/theme_studio_controller.dart';

import 'add_wallet_page.dart';

// ignore: unused_import

import 'web_wallet_card.dart';

// ignore: unused_import

import 'swipeable_bank_card_deck.dart';

import '../transaction/transaction_history_sheet.dart';

import '../transaction/transaction_detail_sheet.dart';

import '../asset/asset_screen.dart';

import '../loan/loan_screen.dart';

import '../transaction/add_transaction_page.dart';

import '../../core/widgets/finora_swipeable_transaction_card.dart';

import '../qr_pay/qr_scanner_screen.dart';

/// Siêu Trung Tâm Quản Lý Tài Sản Ròng & Sổ Nợ (WealthHubScreen) - Thiết Kế Clean Fintech Mới.

/// Một màn hình cuộn duy nhất (Single Unified Scroll View), hoàn toàn không lồng ghép Scaffold,

/// không đè chồng thanh cuộn hay thẻ chức năng, giao diện thoáng đãng, sắc nét và hiện đại.

class WealthHubScreen extends StatefulWidget {
  final String userId;

  final String? familyId;

  final bool isRoot;

  final int initialTabIndex;

  const WealthHubScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.isRoot = false,
    this.initialTabIndex = 0,
  });

  @override
  State<WealthHubScreen> createState() => _WealthHubScreenState();
}

class _WealthHubScreenState extends State<WealthHubScreen> {
  late int _selectedTab; // 0: Giao dịch, 1: Ví tiền, 2: Đầu tư, 3: Sổ nợ

  String _loanSubTab = 'lent'; // 'lent' (Cho vay) | 'borrowed' (Vay nợ)

  bool _obscureBalances = false;

  bool _isSearchOpen = false;

  int _activeWalletIndex = 0;

  late final PageController _walletPageController;

  late final PageController _tabContentPageController;

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _selectedTab = widget.initialTabIndex.clamp(0, 3);

    _walletPageController = PageController(viewportFraction: 0.95);

    _tabContentPageController = PageController(initialPage: _selectedTab);

    final initialQuery = context.read<TransactionProvider>().searchQuery;

    _isSearchOpen = initialQuery.isNotEmpty;

    _searchController = TextEditingController(text: initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final studio = context.read<ThemeStudioController?>();

      if (studio != null && _obscureBalances != studio.isPrivacyShieldActive) {
        setState(() => _obscureBalances = studio.isPrivacyShieldActive);
      }

      context
          .read<WalletProvider>()
          .load(widget.userId, familyId: widget.familyId);

      context
          .read<MoreProvider>()
          .load(widget.userId, familyId: widget.familyId);

      context
          .read<TransactionProvider>()
          .load(widget.userId, familyId: widget.familyId);
    });
  }

  @override
  void dispose() {
    _walletPageController.dispose();

    _tabContentPageController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  void _animateToWalletCard(int index, int count) {
    if (index >= 0 && index < count) {
      HapticFeedback.selectionClick();

      setState(() => _activeWalletIndex = index);

      if (_walletPageController.hasClients) {
        _walletPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant WealthHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      final newTab = widget.initialTabIndex.clamp(0, 3);

      setState(() => _selectedTab = newTab);

      if (_tabContentPageController.hasClients) {
        _tabContentPageController.jumpToPage(newTab);
      }
    }

    if (oldWidget.userId != widget.userId ||
        oldWidget.familyId != widget.familyId) {
      context
          .read<WalletProvider>()
          .load(widget.userId, familyId: widget.familyId);

      context
          .read<MoreProvider>()
          .load(widget.userId, familyId: widget.familyId);

      context
          .read<TransactionProvider>()
          .load(widget.userId, familyId: widget.familyId);
    }
  }

  void _switchTab(int index) {
    if (_selectedTab != index) {
      HapticFeedback.selectionClick();

      setState(() => _selectedTab = index);

      if (_tabContentPageController.hasClients) {
        _tabContentPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  // --- ACTIONS ---

  // ignore: unused_element

  void _openAddHubModal() {
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showFinoraGlassModalBottomSheet(
      context: context,
      title: 'Thêm vào danh mục',
      subtitle: 'Chọn loại tài sản hoặc khoản nợ muốn thêm mới',
      icon: Icons.add_circle_outline_rounded,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              context: ctx,
              title: 'Ghi chép giao dịch thu chi',
              subtitle: 'Chi tiêu, thu nhập, chuyển khoản...',
              icon: Icons.receipt_long_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddTransactionPage(userId: widget.userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              context: ctx,
              title: 'Quét mã VietQR chuyển tiền & Ghi sổ',
              subtitle: 'Nhận diện tài khoản, ghi chép và mở App ngân hàng',
              icon: Icons.qr_code_scanner_rounded,
              gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrScannerScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              context: ctx,
              title: 'Thêm ví hoặc tài khoản ngân hàng',
              subtitle: 'Tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử...',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const [Color(0xFF0070F3), Color(0xFF00C2FA)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddWalletPage(userId: widget.userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              context: ctx,
              title: 'Thêm tài sản tích luỹ & đầu tư',
              subtitle: 'Vàng miếng, bất động sản, sổ tiết kiệm, hụi...',
              icon: Icons.trending_up_rounded,
              gradient: const [Color(0xFFD97706), Color(0xFFFBBF24)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddAssetPage(userId: widget.userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              context: ctx,
              title: 'Thêm khoản vay nợ hoặc cho vay',
              subtitle: 'Sổ nợ cá nhân, vay ngân hàng, người quen...',
              icon: Icons.handshake_rounded,
              gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GlassBottomSheet(
                    radius: 30,
                    showHandle: false,
                    child: AddLoanSheet(
                        userId: widget.userId, initialType: _loanSubTab),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element

  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.12 : 0.08),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFA3B4D4)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFFA3B4D4) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showRepayDialog(BuildContext ctx, Loan loan) {
    final controller = TextEditingController(
      text: DotSeparatorTextInputFormatter.formatDigits(
        loan.remainingPrincipal.toString(),
      ),
    );

    final walletProvider = ctx.read<WalletProvider>();

    final rawWallets = walletProvider.wallets;

    final nonCredit = rawWallets.where((w) => !w.isCreditCard).toList();

    final wallets = nonCredit.isNotEmpty ? nonCredit : rawWallets;

    String selectedWalletId =
        loan.walletId.isNotEmpty && wallets.any((w) => w.id == loan.walletId)
            ? loan.walletId
            : (wallets.isNotEmpty ? wallets.first.id : '');

    final lent = loan.type == 'lent';

    final accentColor =
        lent ? const Color(0xFF059669) : const Color(0xFFE11D48);

    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lent ? Icons.south_west_rounded : Icons.arrow_outward_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lent ? 'Thu hồi nợ cho vay' : 'Thanh toán nợ vay',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.14 : 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.22),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lent ? 'Người vay' : 'Chủ nợ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              loan.personName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Dư nợ còn lại',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            formatVND(loan.remainingPrincipal),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (wallets.isNotEmpty) ...[
                  Text(
                    lent ? 'Ví nhận tiền thu nợ:' : 'Nguồn ví trích trả nợ:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFA3B4D4)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWalletId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: wallets
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(
                              '${w.name} (${formatVND(w.balance)})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedWalletId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lent ? 'Số tiền thu hồi (VNĐ):' : 'Số tiền trả nợ (VNĐ):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFA3B4D4)
                            : const Color(0xFF475569),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller.text =
                            DotSeparatorTextInputFormatter.formatDigits(
                          loan.remainingPrincipal.toString(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Tất toán 100%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [DotSeparatorTextInputFormatter()],
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập số tiền (VNĐ)',
                    suffixText: '₫',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                final digits =
                    controller.text.replaceAll(RegExp(r'[^0-9]'), '');

                final amount = int.tryParse(digits) ?? 0;

                if (amount > 0 &&
                    amount <= loan.remainingPrincipal &&
                    selectedWalletId.isNotEmpty) {
                  final provider = ctx.read<MoreProvider>();

                  final opId = provider.newRepaymentId(widget.userId);

                  await provider.repayLoan(
                    widget.userId,
                    loan.id,
                    selectedWalletId,
                    amount,
                    opId,
                  );

                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: Text(
                lent ? 'Xác nhận thu nợ' : 'Xác nhận trả nợ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final walletProv = context.watch<WalletProvider>();

    final moreProv = context.watch<MoreProvider>();

    final txProv = context.watch<TransactionProvider>();

    final wallets = walletProv.wallets;

    if (_activeWalletIndex >= wallets.length && wallets.isNotEmpty) {
      _activeWalletIndex = wallets.length - 1;
    }

    final assets = moreProv.assets.where((a) => a.status == 'active').toList();

    final loans = moreProv.loans.where((l) => l.status == 'active').toList();

    final filteredTransactions = txProv.filteredTransactions;

    // Macro Financial Computations

    final totalWalletCash = wallets
        .where((w) => !w.isCreditCard)
        .fold<int>(0, (s, w) => s + w.balance);

    final totalInvestments = assets.fold<int>(
        0, (s, a) => s + (a.marketValue > 0 ? a.marketValue : a.costBasis));

    final totalCostBasis = assets.fold<int>(0, (s, a) => s + a.costBasis);

    final totalLent = loans
        .where((l) => l.type == 'lent')
        .fold<int>(0, (s, l) => s + l.remainingPrincipal);

    final totalBorrowed = loans
        .where((l) => l.type == 'borrowed')
        .fold<int>(0, (s, l) => s + l.remainingPrincipal);

    // Cashflow computations for filtered transactions

    final txIncome = filteredTransactions
        .where((t) => TransactionVisuals.isInflow(t.type))
        .fold<int>(0, (s, t) => s + t.amount);

    final txExpense = filteredTransactions
        .where((t) =>
            TransactionVisuals.isOutflow(t.type) &&
            !TransactionVisuals.isTransfer(t.type))
        .fold<int>(0, (s, t) => s + t.amount);

    final canPop = !widget.isRoot && Navigator.of(context).canPop();

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: '',
        titleWidget: _buildAppleSegmentBar(
          isDark: isDark,
          studio: studio,
          txCount: filteredTransactions.length,
          walletCount: wallets.length,
          assetCount: assets.length,
          loanCount: loans.length,
        ),
        showBack: canPop,
        onBack: canPop ? () => Navigator.of(context).pop() : null,
        height: 52,
      ),
      body: PageView(
        controller: _tabContentPageController,
        physics: const PageScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        onPageChanged: (index) {
          if (_selectedTab != index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedTab = index);
          }
        },
        children: [
          _buildTransactionsPage(
            context: context,
            txProv: txProv,
            filteredTransactions: filteredTransactions,
            txIncome: txIncome,
            txExpense: txExpense,
            isDark: isDark,
            studio: studio,
          ),
          _buildWalletsPage(
            context: context,
            wallets: wallets,
            totalWalletCash: totalWalletCash,
            txProv: txProv,
            isDark: isDark,
            studio: studio,
          ),
          _buildAssetsPage(
            context: context,
            assets: assets,
            totalInvestments: totalInvestments,
            totalCostBasis: totalCostBasis,
            isDark: isDark,
            studio: studio,
          ),
          _buildLoansPage(
            context: context,
            loans: loans,
            totalLent: totalLent,
            totalBorrowed: totalBorrowed,
            txProv: txProv,
            isDark: isDark,
            studio: studio,
          ),
        ],
      ),
    );
  }

  Widget _buildTopStickyHeader({
    required BuildContext context,
    required bool isDark,
    required ThemeStudioController? studio,
    required int txCount,
    required int walletCount,
    required int assetCount,
    required int loanCount,
  }) {
    final canPop = !widget.isRoot && Navigator.of(context).canPop();
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);
    final topPad = MediaQuery.of(context).padding.top;

    return GlassTopBar.floatingCapsule(
      context: context,
      margin: EdgeInsets.fromLTRB(12, topPad + 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          if (canPop) ...[
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
          Expanded(
            child: _buildAppleSegmentBar(
              isDark: isDark,
              studio: studio,
              txCount: txCount,
              walletCount: walletCount,
              assetCount: assetCount,
              loanCount: loanCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsPage({
    required BuildContext context,
    required TransactionProvider txProv,
    required List<TransactionModel> filteredTransactions,
    required int txIncome,
    required int txExpense,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();

        txProv.load(widget.userId, familyId: widget.familyId, force: true);

        context
            .read<WalletProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: GlassScaffold.topInset(context, 6, 52)),
          ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCompactTransactionHeroCard(
                  context: context,
                  txProv: txProv,
                  txIncome: txIncome,
                  txExpense: txExpense,
                  filteredTxCount: filteredTransactions.length,
                  isDark: isDark,
                  studio: studio,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: _buildTransactionFilterAndActionRow(
                    context: context,
                    txProv: txProv,
                    isDark: isDark,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _buildTransactionTypeTabs(
                    context: context,
                    txProv: txProv,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          ..._buildTransactionsSlivers(
            context: context,
            transactions: filteredTransactions,
            txProv: txProv,
            isDark: isDark,
            studio: studio,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsPage({
    required BuildContext context,
    required List<Wallet> wallets,
    required int totalWalletCash,
    required TransactionProvider txProv,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();

        txProv.load(widget.userId, familyId: widget.familyId, force: true);

        context
            .read<WalletProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: GlassScaffold.topInset(context, 6, 52)),
          ),
          if (wallets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  height: 235,
                  child: _buildTopWalletCardDeckHero(
                    context: context,
                    wallets: wallets,
                    isDark: isDark,
                    isMasked: _obscureBalances,
                  ),
                ),
              ),
            ),
          ..._buildWalletsSlivers(
            context: context,
            wallets: wallets,
            transactions: txProv.transactions,
            isDark: isDark,
            studio: studio,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsPage({
    required BuildContext context,
    required List<Asset> assets,
    required int totalInvestments,
    required int totalCostBasis,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();

        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: GlassScaffold.topInset(context, 6, 52)),
          ),
          SliverToBoxAdapter(
            child: _buildCompactInvestmentHeroCard(
              context: context,
              totalInvestments: totalInvestments,
              totalCostBasis: totalCostBasis,
              assetCount: assets.length,
              isDark: isDark,
              studio: studio,
            ),
          ),
          ..._buildAssetsSlivers(
            context: context,
            assets: assets,
            isDark: isDark,
            studio: studio,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansPage({
    required BuildContext context,
    required List<Loan> loans,
    required int totalLent,
    required int totalBorrowed,
    required TransactionProvider txProv,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();

        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId, force: true);

        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: GlassScaffold.topInset(context, 6, 52)),
          ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCompactLoanHeroCard(
                  context: context,
                  txProv: txProv,
                  totalLent: totalLent,
                  totalBorrowed: totalBorrowed,
                  isDark: isDark,
                  studio: studio,
                ),
                _buildPinnedLoanToolbar(
                  context: context,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          ..._buildLoansSlivers(
            context: context,
            loans: loans,
            isDark: isDark,
            studio: studio,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTransactionHeroCard({
    required BuildContext context,
    required TransactionProvider txProv,
    required int txIncome,
    required int txExpense,
    required int filteredTxCount,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final cardRadius = studio?.cardCornerRadius ?? 20.0;

    final netCashflow = txIncome - txExpense;

    final isPositive = netCashflow >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4F3E), Color(0xFF0F6E56), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0F6E56).withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'DÒNG TIỀN THÁNG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (netCashflow > 0
                                  ? const Color(0xFF10B981)
                                  : netCashflow < 0
                                      ? const Color(0xFFF43F5E)
                                      : Colors.white)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          netCashflow > 0
                              ? 'Dương'
                              : netCashflow < 0
                                  ? 'Thâm hụt'
                                  : 'Cân bằng',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: netCashflow > 0
                                ? const Color(0xFF6EE7B7)
                                : netCashflow < 0
                                    ? const Color(0xFFFDA4AF)
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$filteredTxCount giao dịch',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();

                        setState(() => _obscureBalances = !_obscureBalances);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          _obscureBalances
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FinoraPrivacyMask(
                  isMasked: _obscureBalances,
                  fallbackDots: '••••••',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${isPositive ? '+' : ''}${formatVND(netCashflow)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          'Thu +${_formatCompactStat(txIncome)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF43F5E).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFFF43F5E).withValues(alpha: 0.4),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          'Chi -${_formatCompactStat(txExpense)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFDA4AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInvestmentHeroCard({
    required BuildContext context,
    required int totalInvestments,
    required int totalCostBasis,
    required int assetCount,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final cardRadius = studio?.cardCornerRadius ?? 20.0;

    final netGain = totalInvestments - totalCostBasis;

    final isGain = netGain >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFD97706).withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TỔNG GIÁ TRỊ ĐẦU TƯ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$assetCount tài sản',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();

                      setState(() => _obscureBalances = !_obscureBalances);
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        _obscureBalances
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FinoraPrivacyMask(
                  isMasked: _obscureBalances,
                  fallbackDots: '••••••',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatVND(totalInvestments),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      'Vốn ${_formatCompactStat(totalCostBasis)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isGain
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF43F5E))
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isGain
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF43F5E))
                            .withValues(alpha: 0.4),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      '${isGain ? '+' : ''}${_formatCompactStat(netGain)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isGain
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFFDA4AF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoanHeroCard({
    required BuildContext context,
    required TransactionProvider txProv,
    required int totalLent,
    required int totalBorrowed,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final cardRadius = studio?.cardCornerRadius ?? 20.0;

    final netLoan = totalLent - totalBorrowed;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFF9F1239), Color(0xFFE11D48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFE11D48).withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDA4AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SỔ NỢ RÒNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMemberFilterPill(
                      context: context, txProv: txProv, isDark: isDark),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();

                      setState(() => _obscureBalances = !_obscureBalances);
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        _obscureBalances
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FinoraPrivacyMask(
                  isMasked: _obscureBalances,
                  fallbackDots: '••••••',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${netLoan >= 0 ? '+' : ''}${formatVND(netLoan)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      'Cho vay ${_formatCompactStat(totalLent)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      'Nợ vay ${_formatCompactStat(totalBorrowed)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFDA4AF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element

  double get _unifiedHeaderMaxHeight {
    if (_selectedTab == 0) return 338.0;

    if (_selectedTab == 1) return 310.0;

    if (_selectedTab == 2) return 300.0;

    return 338.0;
  }

  // ignore: unused_element

  double get _unifiedHeaderMinHeight {
    if (_selectedTab == 0) return 180.0;

    if (_selectedTab == 1) return 132.0;

    if (_selectedTab == 2) return 132.0;

    return 180.0;
  }

  // ignore: unused_element

  double get _heroFullHeight {
    if (_selectedTab == 1) return 212.0;

    return 204.0;
  }

  String _formatCompactStat(int amount) {
    final absVal = amount.abs();

    if (absVal >= 1000000000) {
      final v = (absVal / 1000000000).toStringAsFixed(1).replaceAll('.0', '');

      return '${amount < 0 ? '-' : ''}$v tỷ';
    } else if (absVal >= 1000000) {
      final v = (absVal / 1000000).toStringAsFixed(1).replaceAll('.0', '');

      return '${amount < 0 ? '-' : ''}$v tr';
    } else if (absVal >= 1000) {
      final v = (absVal / 1000).toStringAsFixed(0);

      return '${amount < 0 ? '-' : ''}${v}k';
    }

    return formatVND(amount);
  }

  // ignore: unused_element

  Widget _buildCompactHeroBar({
    required int selectedTab,
    required bool isDark,
    required bool isMasked,
    required int netCashflow,
    required int txIncome,
    required int txExpense,
    required int totalWalletCash,
    required int totalInvestments,
    required int totalLent,
    required int totalBorrowed,
    required int walletCount,
    required int assetCount,
    required VoidCallback onToggleMask,
  }) {
    final Color barAccent;

    final String label;

    final int mainAmount;

    final String rightStat1;

    final Color rightColor1;

    final String rightStat2;

    final Color? rightColor2;

    if (selectedTab == 0) {
      barAccent = const Color(0xFF10B981);

      label = 'DÒNG TIỀN:';

      mainAmount = netCashflow;

      rightStat1 = 'Thu +${_formatCompactStat(txIncome)}';

      rightColor1 = const Color(0xFF10B981);

      rightStat2 = 'Chi -${_formatCompactStat(txExpense)}';

      rightColor2 = const Color(0xFFEF4444);
    } else if (selectedTab == 1) {
      barAccent = const Color(0xFF0284C7);

      label = 'SỐ DƯ VÍ:';

      mainAmount = totalWalletCash;

      rightStat1 = '$walletCount tài khoản';

      rightColor1 = const Color(0xFF0284C7);

      rightStat2 = '';

      rightColor2 = null;
    } else if (selectedTab == 2) {
      barAccent = const Color(0xFFD97706);

      label = 'ĐẦU TƯ:';

      mainAmount = totalInvestments;

      rightStat1 = '$assetCount tài sản';

      rightColor1 = const Color(0xFFD97706);

      rightStat2 = '';

      rightColor2 = null;
    } else {
      barAccent = const Color(0xFFE11D48);

      label = 'SỔ NỢ RÒNG:';

      mainAmount = totalLent - totalBorrowed;

      rightStat1 = 'Cho vay ${_formatCompactStat(totalLent)}';

      rightColor1 = const Color(0xFF10B981);

      rightStat2 = 'Vay ${_formatCompactStat(totalBorrowed)}';

      rightColor2 = const Color(0xFFEF4444);
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                barAccent.withValues(alpha: 0.14), const Color(0xFF1E293B))
            : Color.alphaBlend(barAccent.withValues(alpha: 0.08), Colors.white),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: barAccent.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: barAccent.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: barAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: barAccent.withValues(alpha: 0.65),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: barAccent,
            ),
          ),
          const SizedBox(width: 5),
          FinoraPrivacyMask(
            isMasked: isMasked,
            fallbackDots: '••••••',
            child: Text(
              '${(selectedTab == 0 && mainAmount > 0) ? '+' : ''}${formatVND(mainAmount)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: onToggleMask,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                isMasked
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 13,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (rightStat1.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: rightColor1.withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rightStat1,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? rightColor1
                          : rightColor1.withValues(alpha: 0.95),
                    ),
                  ),
                ),
                if (rightStat2.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (rightColor2 ?? barAccent)
                          .withValues(alpha: isDark ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rightStat2,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? (rightColor2 ?? Colors.white)
                            : (rightColor2?.withValues(alpha: 0.95) ??
                                const Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ignore: unused_element

  Widget _buildDedicatedFilterRow({
    required BuildContext context,
    required TransactionProvider txProv,
    required bool isDark,
    required List<Wallet> wallets,
    required int totalWalletCash,
    required List<Asset> assets,
    required int totalInvestments,
    required List<Loan> loans,
  }) {
    final safeWalletIndex = _activeWalletIndex.clamp(
        0, wallets.isNotEmpty ? wallets.length - 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  constraints.maxWidth > 20 ? constraints.maxWidth - 20 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedTab == 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateFilterPill(
                          context: context, txProv: txProv, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildMemberFilterPill(
                          context: context, txProv: txProv, isDark: isDark),
                    ],
                  )
                else if (_selectedTab == 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.55),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'SỐ DƯ VÍ & TÀI KHOẢN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFF7DD3FC)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7)
                              .withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: FinoraPrivacyMask(
                          isMasked: _obscureBalances,
                          fallbackDots: '••••••',
                          child: Text(
                            formatVND(totalWalletCash),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ),
                      if (wallets.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${safeWalletIndex + 1}/${wallets.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      FinoraAddButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) =>
                                AddWalletPage(userId: widget.userId),
                          ),
                        ),
                        tooltip: 'Thêm ví mới',
                        size: 28,
                        color: const Color(0xFF00866A),
                      ),
                    ],
                  )
                else if (_selectedTab == 2)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.55),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'TỔNG TÀI SẢN TÍCH LUỸ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706)
                              .withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: FinoraPrivacyMask(
                          isMasked: _obscureBalances,
                          fallbackDots: '••••••',
                          child: Text(
                            formatVND(totalInvestments),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FinoraAddButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => AddTransactionPage(
                              userId: widget.userId,
                              initialType: 'investment',
                            ),
                          ),
                        ),
                        tooltip: 'Ghi nhận đầu tư',
                        size: 28,
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMemberFilterPill(
                          context: context, txProv: txProv, isDark: isDark),
                      const SizedBox(width: 8),
                      FinoraAddButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GlassBottomSheet(
                            radius: 30,
                            showHandle: false,
                            child: AddLoanSheet(
                                userId: widget.userId,
                                initialType: _loanSubTab),
                          ),
                        ),
                        tooltip: 'Thêm khoản nợ',
                        size: 28,
                        color: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();

                    setState(() => _obscureBalances = !_obscureBalances);
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _obscureBalances
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          _obscureBalances ? 'Hiện' : 'Ẩn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
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
      },
    );
  }

  // ignore: unused_element

  Widget _buildTransparentTopHeader(BuildContext context, bool isDark) {
    final canPop = !widget.isRoot && Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          if (canPop) ...[
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              'Giao dịch & Tài sản',
              style: TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color:
                    isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedLoanToolbar({
    required BuildContext context,
    required bool isDark,
  }) {
    final isLent = _loanSubTab == 'lent';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: BouncyPillTabs(
              labels: const ['Cho vay', 'Vay nợ'],
              selectedIndex: isLent ? 0 : 1,
              colors: const [Color(0xFF059669), Color(0xFFDC2626)],
              height: 42,
              fontSize: 13,
              onChanged: (i) =>
                  setState(() => _loanSubTab = i == 0 ? 'lent' : 'borrowed'),
            ),
          ),
          const SizedBox(width: 8),
          FinoraAddButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GlassBottomSheet(
                radius: 30,
                showHandle: false,
                child: AddLoanSheet(
                    userId: widget.userId, initialType: _loanSubTab),
              ),
            ),
            tooltip: 'Thêm khoản nợ',
            size: 38,
            color: _loanSubTab == 'lent'
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  void _showTransactionStyleModal(BuildContext context, bool isDark) {
    final studio = context.read<ThemeStudioController?>();
    final currentStyle = studio?.transactionListStyle ??
        AppTransactionListStyle.modernStreamlined;

    final styles = [
      (
        style: AppTransactionListStyle.modernStreamlined,
        title: '1. Pha lê Zenvest (Crystal Pill Deck)',
        subtitle:
            'Thẻ kính bo 20px, avatar Vợ/Chồng lồng góc & chip ví rút gọn',
        icon: Icons.auto_awesome_mosaic_rounded,
        accent: const Color(0xFF00866A),
      ),
      (
        style: AppTransactionListStyle.bentoCards,
        title: '2. Hộp Ngọc Bento (Luxury Bento Box)',
        subtitle:
            'Thẻ Bento 2 tầng bo 24px, huy hiệu Vợ/Chồng & ví ngân hàng nổi',
        icon: Icons.dashboard_customize_rounded,
        accent: const Color(0xFF0EA5E9),
      ),
      (
        style: AppTransactionListStyle.timelineRail,
        title: '3. Trục Thời Gian (Chrono Pulse Rail)',
        subtitle:
            'Cột giờ HH:mm bên trái nối hạt ngọc phát sáng & thẻ giao dịch',
        icon: Icons.timeline_rounded,
        accent: const Color(0xFF8B5CF6),
      ),
      (
        style: AppTransactionListStyle.magazineLedger,
        title: '4. Sổ Cái Hoàng Gia (Editorial Ledger)',
        subtitle: 'Ruy-băng màu dọc 6px, chữ số kế toán & nhãn mã GD ngân hàng',
        icon: Icons.menu_book_rounded,
        accent: const Color(0xFFF59E0B),
      ),
      (
        style: AppTransactionListStyle.compactTable,
        title: '5. Bảng Vi Mạch (Micro Matrix Row)',
        subtitle:
            'Siêu gọn 1 dòng: Icon + Avatar Vợ/Chồng + Tên + Ví ngắn + Số tiền',
        icon: Icons.table_rows_rounded,
        accent: const Color(0xFFEC4899),
      ),
      (
        style: AppTransactionListStyle.minimalDivided,
        title: '6. Lụa Phẳng Tinh Khiết (Pure Silk Hairline)',
        subtitle: 'Không khung hộp, kẻ chỉ mảnh tinh tế kèm avatar Vợ/Chồng',
        icon: Icons.horizontal_rule_rounded,
        accent: const Color(0xFF64748B),
      ),
    ];

    Widget buildMiniStylePreview(
      AppTransactionListStyle s,
      Color accent,
      bool selected,
    ) {
      final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
      final linePrimary = isDark
          ? Colors.white.withValues(alpha: 0.78)
          : const Color(0xFF334155);
      final lineSecondary = isDark
          ? Colors.white.withValues(alpha: 0.30)
          : const Color(0xFFCBD5E1);

      Widget sampleContent({double dotSize = 18}) {
        return Row(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.7)],
                ),
              ),
              child: const Icon(
                Icons.local_mall_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: linePrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lineSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-150.000 ₫',
              style: TextStyle(
                fontFamily: s == AppTransactionListStyle.magazineLedger
                    ? 'monospace'
                    : 'BeVietnamPro',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE11D48),
              ),
            ),
          ],
        );
      }

      switch (s) {
        case AppTransactionListStyle.modernStreamlined:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: sampleContent(),
          );
        case AppTransactionListStyle.bentoCards:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: sampleContent(dotSize: 20),
          );
        case AppTransactionListStyle.timelineRail:
          return Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 1.8,
                    height: 8,
                    color: accent.withValues(alpha: 0.45),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  Container(
                    width: 1.8,
                    height: 8,
                    color: accent.withValues(alpha: 0.45),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: sampleContent(dotSize: 16),
                ),
              ),
            ],
          );
        case AppTransactionListStyle.magazineLedger:
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: const Color(0xFFE11D48)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        child: sampleContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        case AppTransactionListStyle.compactTable:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: sampleContent(dotSize: 14),
          );
        case AppTransactionListStyle.minimalDivided:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
            ),
            child: sampleContent(dotSize: 16),
          );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AdaptiveGlassSurface(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.86,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF0D9488)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.style_rounded,
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
                            '6 Kiểu giao diện sổ giao dịch',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xem trước trực quan và chạm để áp dụng ngay',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: styles.map((item) {
                        final isSelected = item.style == currentStyle;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                studio?.setTransactionListStyle(item.style);
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF064E3B)
                                              .withValues(alpha: 0.35)
                                          : const Color(0xFFECFDF5))
                                      : (isDark
                                          ? const Color(0xFF162032)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF059669)
                                        : (isDark
                                            ? const Color(0xFF283548)
                                            : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? const Color(0xFF059669)
                                                : item.accent
                                                    .withValues(alpha: 0.14),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 17,
                                            color: isSelected
                                                ? Colors.white
                                                : item.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontFamily: 'BeVietnamPro',
                                                  fontSize: 13.8,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                item.subtitle,
                                                style: TextStyle(
                                                  fontFamily: 'BeVietnamPro',
                                                  fontSize: 11.5,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF059669),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Đang dùng',
                                                  style: TextStyle(
                                                    fontFamily: 'BeVietnamPro',
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    buildMiniStylePreview(
                                      item.style,
                                      item.accent,
                                      isSelected,
                                    ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionFilterAndActionRow({
    required BuildContext context,
    required TransactionProvider txProv,
    required bool isDark,
  }) {
    if (_isSearchOpen) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: isDark ? 0.90 : 0.96),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color:
                const Color(0xFF0F6E56).withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              size: 16,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: const [FirstLetterUpperCaseFormatter()],
                onChanged: (q) => txProv.setSearchQuery(q),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Tìm kiếm ghi chú, danh mục, ví...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();

                  _searchController.clear();

                  txProv.setSearchQuery('');
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFFA3B4D4)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();

                _searchController.clear();

                txProv.setSearchQuery('');

                setState(() => _isSearchOpen = false);
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // 1. Month Filter Pill (Bộ lọc tháng - chiều cao chuẩn 38px)
        Expanded(
          child: _buildDateFilterPill(
            context: context,
            txProv: txProv,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 6),

        // 2. Member Filter Avatar Button (Chồng / Vợ / Tất cả - 38x38 tròn, đặc 100%)
        _buildMemberFilterPill(
          context: context,
          txProv: txProv,
          isDark: isDark,
        ),
        const SizedBox(width: 6),

        // 3. View Style Button (Kiểu hiển thị giao dịch - 38x38)
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showTransactionStyleModal(context, isDark);
          },
          borderRadius: BorderRadius.circular(100),
          child: Tooltip(
            message: 'Chọn giao diện danh sách giao dịch',
            child: AdaptiveGlassSurface(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.style_rounded,
                size: 18,
                color:
                    isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 4. Search Button (Tìm kiếm - 38x38)
        InkWell(
          onTap: () => setState(() => _isSearchOpen = true),
          borderRadius: BorderRadius.circular(100),
          child: Tooltip(
            message: 'Tìm kiếm giao dịch',
            child: AdaptiveGlassSurface(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_rounded,
                size: 18,
                color:
                    isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 5. Add Transaction Button (+) (Thêm giao dịch - 38x38)
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => AddTransactionPage(userId: widget.userId),
            ),
          ),
          borderRadius: BorderRadius.circular(100),
          child: Tooltip(
            message: 'Thêm giao dịch',
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeTabs({
    required BuildContext context,
    required TransactionProvider txProv,
    required bool isDark,
  }) {
    const types = <String?>[null, 'expense', 'income', 'transfer'];

    return Row(
      children: [
        Expanded(
          child: FinoraSegmentedTabs(
            labels: const ['Tất cả', 'Chi tiêu', 'Thu nhập', 'Chuyển khoản'],
            colors: const [
              Color(0xFF475569),
              Color(0xFFE11D48),
              Color(0xFF059669),
              Color(0xFF0284C7)
            ],
            selectedIndex: types.indexOf(txProv.selectedType),
            height: 42,
            onChanged: (index) => txProv.setSelectedType(types[index]),
          ),
        ),
      ],
    );
  }

  // --- 1. ADAPTIVE MASTER HERO CARD (TAB-MATCHED COLORS) ---

  // --- 1. ADAPTIVE MASTER HERO CARD (TAB-MATCHED COLORS) ---

  // ignore: unused_element

  Widget _buildAdaptiveHeroCard({
    required int selectedTab,
    required BuildContext context,
    required TransactionProvider txProv,
    required int totalWalletCash,
    required int totalCreditDebt,
    required int totalInvestments,
    required int totalCostBasis,
    required int totalLent,
    required int totalBorrowed,
    required int txIncome,
    required int txExpense,
    required int walletCount,
    int filteredTxCount = 0,
    required bool isMasked,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final cardRadius = studio?.cardCornerRadius ?? 24.0;

    // 1. Dynamic Titles, Figures & Tab-Matched Colors depending on active tab

    final String heroTitle;

    final String mainFigureText;

    final Color mainFigureColor;

    final String captionText;

    final String? statChipText;

    final String statusBadgeText;

    final Color statusBadgeBg;

    final Color statusBadgeTextColor;

    final double ratioLeft;

    final Color ratioLeftColor;

    final Color ratioRightColor;

    final String ratioLeftLabel;

    final String ratioRightLabel;

    final String pod1Title;

    final String pod1Value;

    final IconData pod1Icon;

    final Color pod1Color;

    final String pod2Title;

    final String pod2Value;

    final IconData pod2Icon;

    final Color pod2Color;

    final Color tabThemeColor;

    final List<Color> cardGradient;

    if (selectedTab == 0) {
      // TAB 0: GIAO DỊCH — Emerald (#0F6E56 / #10B981)

      tabThemeColor = const Color(0xFF10B981);

      cardGradient = const [
        Color(0xFF0B4F3E),
        Color(0xFF0F6E56),
        Color(0xFF10B981),
      ];

      final netCashflow = txIncome - txExpense;

      heroTitle = 'DÒNG TIỀN';

      captionText = 'DÒNG TIỀN RÒNG';

      statChipText = '$filteredTxCount giao dịch';

      mainFigureText =
          '${netCashflow >= 0 ? '+' : ''}${formatVND(netCashflow)}';

      mainFigureColor = Colors.white;

      if (netCashflow > 0) {
        statusBadgeText = 'Dương';

        statusBadgeBg = const Color(0xFF10B981).withValues(alpha: 0.24);

        statusBadgeTextColor = const Color(0xFF6EE7B7);
      } else if (netCashflow < 0) {
        statusBadgeText = 'Thâm hụt';

        statusBadgeBg = const Color(0xFFF43F5E).withValues(alpha: 0.24);

        statusBadgeTextColor = const Color(0xFFFDA4AF);
      } else {
        statusBadgeText = 'Cân bằng';

        statusBadgeBg = Colors.white.withValues(alpha: 0.16);

        statusBadgeTextColor = Colors.white;
      }

      final totalFlow = txIncome + txExpense;

      ratioLeft =
          totalFlow > 0 ? (txIncome / totalFlow).clamp(0.06, 0.94) : 0.50;

      ratioLeftColor = const Color(0xFF6EE7B7);

      ratioRightColor = const Color(0xFFFDA4AF);

      ratioLeftLabel = 'Thu: ${formatVND(txIncome)}';

      ratioRightLabel = 'Chi: ${formatVND(txExpense)}';

      pod1Title = 'Tổng thu';

      pod1Value = '+${formatVND(txIncome)}';

      pod1Icon = Icons.arrow_downward_rounded;

      pod1Color = const Color(0xFF6EE7B7);

      pod2Title = 'Tổng chi';

      pod2Value = '-${formatVND(txExpense)}';

      pod2Icon = Icons.arrow_upward_rounded;

      pod2Color = const Color(0xFFFDA4AF);
    } else if (selectedTab == 1) {
      // TAB 1: VÍ TIỀN — Ocean Sapphire (#0284C7 / #38BDF8)

      tabThemeColor = const Color(0xFF38BDF8);

      cardGradient = const [
        Color(0xFF0C4A6E),
        Color(0xFF0369A1),
        Color(0xFF0284C7),
      ];

      heroTitle = 'SỐ DƯ VÍ & TÀI KHOẢN';

      captionText = 'TỔNG SỐ DƯ TÀI KHOẢN';

      statChipText = '$walletCount tài khoản';

      mainFigureText = formatVND(totalWalletCash);

      mainFigureColor = Colors.white;

      statusBadgeText = 'An toàn';

      statusBadgeBg = const Color(0xFF0284C7).withValues(alpha: 0.24);

      statusBadgeTextColor = const Color(0xFF7DD3FC);

      final totalLiab = totalWalletCash + totalCreditDebt;

      ratioLeft =
          totalLiab > 0 ? (totalWalletCash / totalLiab).clamp(0.06, 0.94) : 1.0;

      ratioLeftColor = const Color(0xFF38BDF8);

      ratioRightColor = const Color(0xFFFDA4AF);

      ratioLeftLabel = 'Tiền mặt/Bank: ${formatVND(totalWalletCash)}';

      ratioRightLabel = 'Dư nợ thẻ: ${formatVND(totalCreditDebt)}';

      pod1Title = 'Tiền mặt & Ngân hàng';

      pod1Value = formatVND(totalWalletCash);

      pod1Icon = Icons.account_balance_wallet_rounded;

      pod1Color = const Color(0xFF7DD3FC);

      pod2Title = 'Dư nợ tín dụng';

      pod2Value = formatVND(totalCreditDebt);

      pod2Icon = Icons.credit_card_rounded;

      pod2Color = const Color(0xFFFDA4AF);
    } else if (selectedTab == 2) {
      // TAB 2: ĐẦU TƯ — Amber Gold (#D97706 / #F59E0B)

      tabThemeColor = const Color(0xFFF59E0B);

      cardGradient = const [
        Color(0xFF78350F),
        Color(0xFFB45309),
        Color(0xFFD97706),
      ];

      heroTitle = 'ĐẦU TƯ';

      captionText = 'GIÁ TRỊ THỊ TRƯỜNG HIỆN TẠI';

      final profit = totalInvestments - totalCostBasis;

      final double profitPct =
          totalCostBasis > 0 ? (profit / totalCostBasis * 100) : 0.0;

      statChipText = totalCostBasis > 0
          ? (profit >= 0 ? '▲ Tăng trưởng' : '▼ Giảm')
          : 'Tích luỹ';

      mainFigureText = formatVND(totalInvestments);

      mainFigureColor = Colors.white;

      statusBadgeText = totalCostBasis > 0
          ? '${profit >= 0 ? '+' : ''}${profitPct.toStringAsFixed(1)}%'
          : 'Tích luỹ';

      statusBadgeBg =
          (profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
              .withValues(alpha: 0.24);

      statusBadgeTextColor =
          profit >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF);

      final totalInvBase = totalCostBasis + totalInvestments;

      ratioLeft = totalInvBase > 0
          ? (totalCostBasis / totalInvBase).clamp(0.06, 0.94)
          : 0.50;

      ratioLeftColor = const Color(0xFFFDE68A);

      ratioRightColor = const Color(0xFF6EE7B7);

      ratioLeftLabel = 'Vốn gốc: ${formatVND(totalCostBasis)}';

      ratioRightLabel = 'Thị trường: ${formatVND(totalInvestments)}';

      pod1Title = 'Vốn gốc đầu tư';

      pod1Value = formatVND(totalCostBasis);

      pod1Icon = Icons.savings_rounded;

      pod1Color = const Color(0xFFFDE68A);

      pod2Title = 'Giá trị thị trường';

      pod2Value = formatVND(totalInvestments);

      pod2Icon = Icons.trending_up_rounded;

      pod2Color = const Color(0xFF6EE7B7);
    } else {
      // TAB 3: SỔ NỢ — Crimson Rose (#E11D48 / #F43F5E)

      tabThemeColor = const Color(0xFFF43F5E);

      cardGradient = const [
        Color(0xFF881337),
        Color(0xFFBE123C),
        Color(0xFFE11D48),
      ];

      final netDebt = totalLent - totalBorrowed;

      heroTitle = 'SỔ NỢ';

      captionText = 'SỔ NỢ RÒNG';

      statChipText = totalLent >= totalBorrowed ? '• Thu > Trả' : '• Trả > Thu';

      mainFigureText = '${netDebt >= 0 ? '+' : ''}${formatVND(netDebt)}';

      mainFigureColor = Colors.white;

      statusBadgeText = totalLent >= totalBorrowed ? 'Thu > Trả' : 'Trả > Thu';

      statusBadgeBg = const Color(0xFFF43F5E).withValues(alpha: 0.24);

      statusBadgeTextColor = const Color(0xFFFECDD3);

      final totalDebtPool = totalLent + totalBorrowed;

      ratioLeft = totalDebtPool > 0
          ? (totalLent / totalDebtPool).clamp(0.06, 0.94)
          : 0.50;

      ratioLeftColor = const Color(0xFF6EE7B7);

      ratioRightColor = const Color(0xFFFDA4AF);

      ratioLeftLabel = 'Cho vay: ${formatVND(totalLent)}';

      ratioRightLabel = 'Vay nợ: ${formatVND(totalBorrowed)}';

      pod1Title = 'Cần thu về';

      pod1Value = formatVND(totalLent);

      pod1Icon = Icons.arrow_downward_rounded;

      pod1Color = const Color(0xFF6EE7B7);

      pod2Title = 'Cần phải trả';

      pod2Value = formatVND(totalBorrowed);

      pod2Icon = Icons.arrow_upward_rounded;

      pod2Color = const Color(0xFFFECDD3);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: 212,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: tabThemeColor.withValues(alpha: isDark ? 0.20 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            // Layer 1: Rich velvet gradient base

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Layer 2: Ambient Luminous Bloom Painter

            Positioned.fill(
              child: CustomPaint(
                painter: _ZenvestWealthBloomPainter(
                  themeColor: tabThemeColor,
                  isDark: isDark,
                ),
              ),
            ),

            // Layer 3: Specular Ambient Sheen Overlay

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.8, -1.0),
                      end: const Alignment(0.8, 1.0),
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 4: Crystalline hairline border 1.0px

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.18 : 0.22),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Layer 5: Card Content with 16px horizontal, 11px vertical insets

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Header: Dot + Title + Status Pill Badge + Date/Member Filters

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                width: 7.5,
                                height: 7.5,
                                decoration: BoxDecoration(
                                  color: tabThemeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          tabThemeColor.withValues(alpha: 0.65),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  heroTitle,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.white.withValues(alpha: 0.90),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (statusBadgeText.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusBadgeBg,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      statusBadgeText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: statusBadgeTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (selectedTab == 0) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            flex: 5,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildDateFilterPill(
                                        context: context,
                                        txProv: txProv,
                                        isDark: isDark,
                                        onHeroCard: true),
                                    const SizedBox(width: 4),
                                    _buildMemberFilterPill(
                                        context: context,
                                        txProv: txProv,
                                        isDark: isDark),
                                  ]),
                            ),
                          ),
                        ] else if (selectedTab == 3) ...[
                          _buildMemberFilterPill(
                              context: context, txProv: txProv, isDark: isDark),
                        ] else if (statChipText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              statChipText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // 2. Middle Row: Caption + Big Amount

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          captionText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: FinoraPrivacyMask(
                            isMasked: isMasked,
                            fallbackDots: '•••••••••• đ',
                            child: Text(
                              mainFigureText,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                color: mainFigureColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. Tab-Specific Differentiated Visual Core

                    if (selectedTab == 2) ...[
                      // TAB 2: ĐẦU TƯ — Asset Allocation Spectrum & ROI Matrix

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Segmented Spectrum Bar

                          Container(
                            height: 7,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 60,
                                    child: Container(
                                        color: const Color(0xFFF59E0B)),
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    flex: 25,
                                    child: Container(
                                        color: const Color(0xFF10B981)),
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    flex: 15,
                                    child: Container(
                                        color: const Color(0xFF38BDF8)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFF59E0B),
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('Vàng & Bất động sản (60%)',
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFDE68A))),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('Cổ phiếu & Quỹ (25%)',
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6EE7B7))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 0.8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('VỐN GỐC ĐẦU TƯ',
                                      style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white70)),
                                  const SizedBox(height: 2),
                                  FinoraPrivacyMask(
                                    isMasked: isMasked,
                                    fallbackDots: '••••••',
                                    child: Text(formatVND(totalCostBasis),
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: (totalInvestments >= totalCostBasis
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF43F5E))
                                    .withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (totalInvestments >= totalCostBasis
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF43F5E))
                                      .withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalInvestments >= totalCostBasis
                                        ? 'LÃI RÒNG'
                                        : 'THÂM HỤT',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: totalInvestments >= totalCostBasis
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFFFDA4AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FinoraPrivacyMask(
                                    isMasked: isMasked,
                                    fallbackDots: '••••••',
                                    child: Text(
                                      '${(totalInvestments - totalCostBasis) >= 0 ? '+' : ''}${formatVND(totalInvestments - totalCostBasis)}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            totalInvestments >= totalCostBasis
                                                ? const Color(0xFF6EE7B7)
                                                : const Color(0xFFFDA4AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (selectedTab == 3) ...[
                      // TAB 3: SỔ NỢ — Financial Equilibrium Dual Balance Scale

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.35),
                                    width: 0.8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded,
                                          size: 11, color: Color(0xFF6EE7B7)),
                                      SizedBox(width: 4),
                                      Text('CẦN THU VỀ',
                                          style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF6EE7B7))),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  FinoraPrivacyMask(
                                    isMasked: isMasked,
                                    fallbackDots: '••••••',
                                    child: Text(formatVND(totalLent),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.balance_rounded,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFF43F5E)
                                        .withValues(alpha: 0.35),
                                    width: 0.8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded,
                                          size: 11, color: Color(0xFFFDA4AF)),
                                      SizedBox(width: 4),
                                      Text('PHẢI TRẢ',
                                          style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFFDA4AF))),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  FinoraPrivacyMask(
                                    isMasked: isMasked,
                                    fallbackDots: '••••••',
                                    child: Text(formatVND(totalBorrowed),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Equilibrium progress track

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: (ratioLeft * 1000)
                                        .toInt()
                                        .clamp(1, 999),
                                    child: Container(
                                        color: const Color(0xFF10B981)),
                                  ),
                                  Flexible(
                                    flex: ((1.0 - ratioLeft) * 1000)
                                        .toInt()
                                        .clamp(1, 999),
                                    child: Container(
                                        color: const Color(0xFFF43F5E)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Thu: ${formatVND(totalLent)}',
                                  style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6EE7B7))),
                              Text('Trả: ${formatVND(totalBorrowed)}',
                                  style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFDA4AF))),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      // TAB 0 & 1: GIAO DỊCH & VÍ TIỀN — Cashflow Ratio & Dual Flow Pods

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: (ratioLeft * 1000)
                                        .toInt()
                                        .clamp(1, 999),
                                    child: Container(color: ratioLeftColor),
                                  ),
                                  Flexible(
                                    flex: ((1.0 - ratioLeft) * 1000)
                                        .toInt()
                                        .clamp(1, 999),
                                    child: Container(color: ratioRightColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  ratioLeftLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w700,
                                    color: ratioLeftColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  ratioRightLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w700,
                                    color: ratioRightColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Two Frosted Glass Sub-Pod Cards

                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroSubPodCard(
                              title: pod1Title,
                              value: pod1Value,
                              icon: pod1Icon,
                              accentColor: pod1Color,
                              isMasked: isMasked,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroSubPodCard(
                              title: pod2Title,
                              value: pod2Value,
                              icon: pod2Icon,
                              accentColor: pod2Color,
                              isMasked: isMasked,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSubPodCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isMasked,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: FinoraPrivacyMask(
                    isMasked: isMasked,
                    fallbackDots: '••••••',
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterPill({
    required BuildContext context,
    required TransactionProvider txProv,
    required bool isDark,
    bool onHeroCard = false,
  }) {
    final baseSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final fill = onHeroCard
        ? Colors.white.withValues(alpha: 0.18)
        : Color.alphaBlend(
            const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.08),
            baseSurface,
          );

    return InkWell(
      onTap: () => _openDateFilterSheet(context, txProv, isDark),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: onHeroCard
                ? Colors.white.withValues(alpha: 0.28)
                : const Color(0xFF10B981)
                    .withValues(alpha: isDark ? 0.45 : 0.32),
            width: 1.0,
          ),
          boxShadow: !onHeroCard
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onHeroCard
                    ? Colors.white.withValues(alpha: 0.18)
                    : const Color(0xFF10B981)
                        .withValues(alpha: isDark ? 0.24 : 0.14),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 12.5,
                color: onHeroCard
                    ? const Color(0xFF6EE7B7)
                    : (isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF059669)),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                txProv.activeDateFilterLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: onHeroCard
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: onHeroCard
                  ? Colors.white.withValues(alpha: 0.8)
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberFilterPill({
    required BuildContext context,
    required TransactionProvider txProv,
    required bool isDark,
  }) {
    return FinoraUnifiedMemberPill(
      currentMember: txProv.selectedMemberTag,
      onSelected: (val) => txProv.setSelectedMemberTag(val),
      isDark: isDark,
    );
  }

  void _openDateFilterSheet(
      BuildContext context, TransactionProvider txProv, bool isDark) async {
    final result = await showDateFilterModal(
      context,
      currentOption: txProv.selectedDateFilter,
      currentCustomDate: txProv.customDate,
      showAllTime: true,
    );

    if (result != null) {
      if (result.option == DateFilterOption.customDate &&
          result.customDate != null) {
        txProv.setCustomDate(result.customDate!);
      } else {
        txProv.setSelectedDateFilter(result.option);
      }
    }
  }

  // --- 2. TAB-MATCHED SEGMENT CONTROL ---

  Widget _buildAppleSegmentBar({
    required bool isDark,
    required ThemeStudioController? studio,
    required int txCount,
    required int walletCount,
    required int assetCount,
    required int loanCount,
  }) {
    return FinoraSegmentedTabs(
      labels: const ['Giao dịch', 'Ví tiền', 'Đầu tư', 'Sổ nợ'],
      icons: const [
        Icons.receipt_long_rounded,
        Icons.account_balance_wallet_rounded,
        Icons.trending_up_rounded,
        Icons.handshake_rounded,
      ],
      colors: const [
        Color(0xFF0F6E56), // Giao dịch: Finora Emerald

        Color(0xFF0284C7), // Ví tiền: Ocean Blue

        Color(0xFFD97706), // Đầu tư: Amber Gold

        Color(0xFFE11D48), // Sổ nợ: Rose Red
      ],
      selectedIndex: _selectedTab,
      height: 40,
      transparentBackground: true,
      onChanged: _switchTab,
    );
  }

  // --- 3. SECTION 1: TOP HORIZONTAL BANK CARD DECK HERO & WALLETS TAB ---

  Widget _buildTopWalletCardDeckHero({
    required BuildContext context,
    required List<Wallet> wallets,
    required bool isDark,
    required bool isMasked,
  }) {
    final safeIndex = _activeWalletIndex.clamp(0, wallets.length - 1);

    final totalWalletCash = wallets
        .where((w) => !w.isCreditCard)
        .fold<int>(0, (s, w) => s + w.balance);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0284C7).withValues(alpha: 0.55),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SỐ DƯ VÍ & TÀI KHOẢN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFF7DD3FC)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7)
                          .withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: FinoraPrivacyMask(
                      isMasked: isMasked,
                      fallbackDots: '••••••',
                      child: Text(
                        formatVND(totalWalletCash),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${safeIndex + 1}/${wallets.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              FinoraAddButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddWalletPage(userId: widget.userId),
                  ),
                ),
                tooltip: 'Thêm ví mới',
                size: 26,
                color: const Color(0xFF00866A),
              ),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _walletPageController,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: wallets.length,
              onPageChanged: (idx) {
                HapticFeedback.selectionClick();

                setState(() => _activeWalletIndex = idx);
              },
              itemBuilder: (context, index) {
                final wallet = wallets[index];

                return _buildTopHorizontalBankCard(
                  context: context,
                  wallet: wallet,
                  isSelected: index == safeIndex,
                  isDark: isDark,
                  isMasked: isMasked,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHorizontalBankCard({
    required BuildContext context,
    required Wallet wallet,
    required bool isSelected,
    required bool isDark,
    required bool isMasked,
  }) {
    final brand = BankIconRegistry.resolve(
      wallet.bankCode,
      bankName: wallet.bankName ?? wallet.name,
    );

    final isCash = brand.code == 'cash' ||
        wallet.type == 'cash' ||
        wallet.name.toLowerCase().contains('tiền mặt') ||
        wallet.name.toLowerCase().contains('cash');

    final isCredit = wallet.isCreditCard;

    final isBankBrand = !isCash && brand.code != 'cash';

    final List<Color> cardColors;

    final Color brandColor;

    if (isCash) {
      cardColors = const [
        Color(0xFF06281D),
        Color(0xFF093527),
        Color(0xFF041A13),
      ];

      brandColor = const Color(0xFF10B981);
    } else {
      final walletName = wallet.name.toLowerCase();

      var skin = wallet.themeColor ?? '';

      if (skin.isEmpty) {
        if (RegExp(r'gold|vàng').hasMatch(walletName)) {
          skin = 'gold';
        } else if (RegExp(r'silver|sliver|bạc|platinum').hasMatch(walletName)) {
          skin = 'silver';
        } else if (['mbbank', 'mb', 'bidv', 'acb', 'vtb', 'vietinbank', 'scb']
            .contains(brand.code)) {
          skin = 'blue';
        } else if (['vcb', 'vietcombank', 'vpb', 'vpbank', 'ocb']
            .contains(brand.code)) {
          skin = 'emerald';
        } else if ([
          'tcb',
          'techcombank',
          'cake',
          'hdb',
          'hdbank',
          'agri',
          'agribank'
        ].contains(brand.code)) {
          skin = 'rose';
        } else if (['tpb', 'tpbank', 'timo'].contains(brand.code)) {
          skin = 'purple';
        } else if (['shb', 'sea', 'seabank'].contains(brand.code)) {
          skin = 'orange';
        } else if (['vib', 'zalo', 'zalopay'].contains(brand.code)) {
          skin = 'cyan';
        } else if (['momo'].contains(brand.code)) {
          skin = 'pink';
        }
      }

      final resolved =
          skin.isNotEmpty ? CreditCardPalette.skins[skin.toLowerCase()] : null;

      if (resolved != null) {
        cardColors = resolved;

        brandColor = resolved.length >= 2 ? resolved[1] : brand.color;
      } else if (isBankBrand) {
        brandColor = brand.color;

        cardColors = [
          Color.lerp(const Color(0xFF080C14), brandColor, 0.55)!,
          Color.lerp(const Color(0xFF141A28), brandColor, 0.85)!,
          Color.lerp(const Color(0xFF04060A), brandColor, 0.40)!,
        ];
      } else {
        cardColors = CreditCardPalette.skins['blue']!;

        brandColor = const Color(0xFF0284C7);
      }
    }

    final String cardTierOrDate;

    if (isCredit) {
      cardTierOrDate =
          wallet.creditLimit >= 50000000 ? 'FINORA PLATINUM' : 'CREDIT CARD';
    } else if (wallet.type == 'bank') {
      cardTierOrDate = 'DEBIT CARD';
    } else if (isCash) {
      cardTierOrDate = 'TIỀN MẶT';
    } else {
      cardTierOrDate = 'FINORA PAY';
    }

    final int displayBalance = isCredit && wallet.creditLimit > 0
        ? (wallet.creditLimit - wallet.currentDebt)
        : wallet.balance;

    final String displayCurrency = (brand.code != 'cash' && !isCash)
        ? brand.name.toUpperCase()
        : (isCash ? 'TIỀN MẶT' : 'VND');

    final accountNumber = wallet.accountNumber;

    final displayAccount = accountNumber != null && accountNumber.isNotEmpty
        ? '•••• •••• •••• ${accountNumber.substring(accountNumber.length > 4 ? accountNumber.length - 4 : 0)}'
        : (isCash ? 'TIỀN MẶT' : 'CHƯA CÓ STK');

    final owner = wallet.ownerName.isNotEmpty
        ? wallet.ownerName
        : (wallet.owner == 'wife' ? 'Vợ' : 'Chồng');

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: isDark ? 0.38 : 0.24),
              blurRadius: 20,
              offset: const Offset(0, 7),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cardColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.8, -1.0),
                        end: const Alignment(0.8, 1.0),
                        colors: [
                          Colors.white.withValues(alpha: 0.14),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.22),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ZenvestWealthBloomPainter(
                    themeColor: brandColor,
                    isDark: isDark,
                  ),
                ),
              ),
              const FinoraAmbientMascotWatermark(
                pose: FinoraMascotPose.card,
                size: 132,
                opacity: 0.10,
                right: -14,
                bottom: -18,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Bank Logo Pill + Tier + Contactless + 3-Dots Menu

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isBankBrand && brand.assetPath != null)
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            brand.assetPath!,
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                              child: Text(
                                                brand.name.isNotEmpty
                                                    ? brand.name[0]
                                                    : 'B',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCash
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF0284C7),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isCash
                                                ? Icons.payments_rounded
                                                : Icons.credit_card_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          displayCurrency,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 85),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    cardTierOrDate,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.contactless_rounded,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onSelected: (val) {
                                  if (val == 'history') {
                                    _openWalletHistory(context, wallet);
                                  } else if (val == 'edit') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (_) => AddWalletPage(
                                          userId: widget.userId,
                                          wallet: wallet,
                                        ),
                                      ),
                                    );
                                  } else if (val == 'pay' && isCredit) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionPage(
                                          userId: widget.userId,
                                          initialType: 'credit_card_payment',
                                          initialWalletId: wallet.id,
                                        ),
                                      ),
                                    );
                                  } else if (val == 'delete') {
                                    _confirmDeleteWallet(context, wallet);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'history',
                                    child: Text('Xem lịch sử giao dịch'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Chỉnh sửa thông tin ví'),
                                  ),
                                  if (isCredit)
                                    const PopupMenuItem(
                                      value: 'pay',
                                      child: Text('Thanh toán dư nợ thẻ'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Xóa ví này',
                                      style:
                                          TextStyle(color: Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Middle Row: Wallet Name & Large Balance

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FinoraPrivacyMask(
                              isMasked: isMasked,
                              fallbackDots: '•••••••• ₫',
                              child: Text(
                                formatVND(displayBalance),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          if (isCredit) ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (_) {
                                final limit = wallet.creditLimit;

                                final spent = wallet.currentDebt;

                                final remaining =
                                    (limit - spent).clamp(0, limit);

                                final ratio = limit > 0
                                    ? (spent / limit).clamp(0.0, 1.0)
                                    : 0.0;

                                final isHighUsage = ratio > 0.85;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Đã tiêu: ${isMasked ? '••••••' : formatVND(spent)}',
                                          style: TextStyle(
                                            fontSize: 9.8,
                                            fontWeight: FontWeight.w700,
                                            color: isHighUsage
                                                ? const Color(0xFFFECDD3)
                                                : Colors.white
                                                    .withValues(alpha: 0.88),
                                          ),
                                        ),
                                        Text(
                                          'Còn lại: ${isMasked ? '••••••' : formatVND(remaining)}',
                                          style: TextStyle(
                                            fontSize: 9.8,
                                            fontWeight: FontWeight.w800,
                                            color: isHighUsage
                                                ? const Color(0xFFFCA5A5)
                                                : const Color(0xFF6EE7B7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3.5),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 5.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.22),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              ratio == 0.0 ? 0.02 : ratio,
                                          child: Container(
                                            height: 5.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              gradient: LinearGradient(
                                                colors: isHighUsage
                                                    ? const [
                                                        Color(0xFFF43F5E),
                                                        Color(0xFFE11D48),
                                                      ]
                                                    : const [
                                                        Color(0xFF38BDF8),
                                                        Color(0xFF10B981),
                                                      ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isHighUsage
                                                          ? const Color(
                                                              0xFFF43F5E)
                                                          : const Color(
                                                              0xFF10B981))
                                                      .withValues(alpha: 0.45),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2.5),
                                    Text(
                                      'Hạn mức: ${formatVND(wallet.creditLimit)}',
                                      style: TextStyle(
                                        fontSize: 9.2,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.70),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      // Bottom Row: Account Number + Gold EMV Chip + Owner Badge

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  displayAccount,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFB8860B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF8B6508),
                                        width: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  owner.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  void _openWalletHistory(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: TransactionHistorySheet(
          userId: widget.userId,
          familyId: widget.familyId,
          walletId: wallet.id,
          walletName: wallet.name,
          wallet: wallet,
        ),
      ),
    );
  }

  List<Widget> _buildWalletsSlivers({
    required BuildContext context,
    required List<Wallet> wallets,
    required List<TransactionModel> transactions,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    if (wallets.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: _buildEmptySectionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Chưa có ví hoặc thẻ nào',
              subtitle:
                  'Thêm ví tiền mặt, tài khoản ngân hàng hoặc thẻ tín dụng để bắt đầu quản lý.',
              buttonLabel: 'Thêm ví mới',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddWalletPage(userId: widget.userId),
                ),
              ),
              isDark: isDark,
              accentColor: const Color(0xFF0284C7),
            ),
          ),
        ),
      ];
    }

    final activeWallet =
        wallets[_activeWalletIndex.clamp(0, wallets.length - 1)];

    return [
      // 1. Quick Actions Dock for Active Wallet

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
          child: _buildWalletQuickActionBar(context, activeWallet, isDark),
        ),
      ),

      // 2. Compact All Accounts Switcher (tap to flip top horizontal bank card)

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: _buildCompactAllWalletsSection(wallets, activeWallet, isDark),
        ),
      ),

      // 3. Recent Transactions of the Active Wallet

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: _buildWalletRecentTransactionsSection(
            context,
            activeWallet,
            transactions,
            isDark,
          ),
        ),
      ),
    ];
  }

  Widget _buildWalletQuickActionBar(
    BuildContext context,
    Wallet wallet,
    bool isDark,
  ) {
    final isCredit = wallet.isCreditCard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: isDark ? 0.72 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.12),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildWalletActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Lịch sử',
              color: const Color(0xFF0284C7),
              isDark: isDark,
              onTap: () => _openWalletHistory(context, wallet),
            ),
          ),
          Expanded(
            child: _buildWalletActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Ghi thu chi',
              color: const Color(0xFF0F6E56),
              isDark: isDark,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionPage(
                    userId: widget.userId,
                    initialWalletId: wallet.id,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildWalletActionButton(
              icon: Icons.edit_note_rounded,
              label: 'Sửa ví',
              color: const Color(0xFFD97706),
              isDark: isDark,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddWalletPage(
                    userId: widget.userId,
                    wallet: wallet,
                  ),
                ),
              ),
            ),
          ),
          if (isCredit)
            Expanded(
              child: _buildWalletActionButton(
                icon: Icons.credit_card_rounded,
                label: 'Trả nợ',
                color: const Color(0xFFE11D48),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionPage(
                      userId: widget.userId,
                      initialType: 'credit_card_payment',
                      initialWalletId: wallet.id,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();

        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAllWalletsSection(
    List<Wallet> wallets,
    Wallet activeWallet,
    bool isDark,
  ) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final glassOpacity = studio?.glassOpacity ?? 0.88;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
            alpha: isDark
                ? (0.65 * glassOpacity).clamp(0.2, 0.95)
                : (0.88 * glassOpacity).clamp(0.2, 0.95)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.08 : 0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TẤT CẢ TÀI KHOẢN (${wallets.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFA3B4D4)
                        : const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Chạm để lật thẻ',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: wallets.asMap().entries.map((entry) {
              final idx = entry.key;

              final w = entry.value;

              final isCurrent = w.id == activeWallet.id;

              final brand = BankIconRegistry.resolve(
                w.bankCode,
                bankName: w.bankName ?? w.name,
              );

              final isCash = brand.code == 'cash' || w.type == 'cash';

              final displayBalance = w.isCreditCard && w.creditLimit > 0
                  ? (w.creditLimit - w.currentDebt)
                  : w.balance;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => _animateToWalletCard(idx, wallets.length),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF0284C7)
                              .withValues(alpha: isDark ? 0.18 : 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF0284C7).withValues(alpha: 0.45)
                            : (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                        width: isCurrent ? 1.0 : 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCash ? const Color(0xFF10B981) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: isCash
                              ? const Center(
                                  child: Icon(
                                    Icons.payments_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                )
                              : (brand.assetPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        brand.assetPath!,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            brand.name.isNotEmpty
                                                ? brand.name[0]
                                                : 'B',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.account_balance,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    )),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                w.accountNumber != null &&
                                        w.accountNumber!.isNotEmpty
                                    ? '•••• ${w.accountNumber!.substring(w.accountNumber!.length > 4 ? w.accountNumber!.length - 4 : 0)} · ${w.isCreditCard ? "Tín dụng" : "Thanh toán"}'
                                    : (isCash ? 'Ví tiền mặt' : 'Tài khoản'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 112),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _obscureBalances
                                      ? '••••••••'
                                      : formatVND(displayBalance),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent
                                        ? (isDark
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF0284C7))
                                        : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF334155)),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Đang xem',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletRecentTransactionsSection(
    BuildContext context,
    Wallet wallet,
    List<TransactionModel> transactions,
    bool isDark,
  ) {
    final recentTxs = transactions
        .where((t) =>
            t.walletId == wallet.id ||
            t.fromWalletId == wallet.id ||
            t.toWalletId == wallet.id)
        .take(3)
        .toList();

    final moreCats = context.watch<MoreProvider>().categories;
    final txCats = context.watch<TransactionProvider>().categories;
    final allCats = <dynamic>[...moreCats, ...txCats];
    final studio = context.watch<ThemeStudioController?>();
    final glassOpacity = studio?.glassOpacity ?? 0.85;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
          alpha: (isDark ? 0.65 * glassOpacity : 0.88 * glassOpacity)
              .clamp(0.18, 0.98),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.08 : 0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'GIAO DỊCH GẦN ĐÂY CỦA VÍ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFA3B4D4)
                        : const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (recentTxs.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openWalletHistory(context, wallet),
                  child: Text(
                    'Xem tất cả →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (recentTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Chưa có giao dịch gần đây trên ví này.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            Column(
              children: recentTxs.map((tx) {
                final isIncome = TransactionVisuals.isInflow(tx.type);
                final isTransfer = TransactionVisuals.isTransfer(tx.type);
                final amountColor = TransactionVisuals.colorFor(tx.type);
                final prefix = isTransfer ? '' : (isIncome ? '+' : '-');
                final dateStr =
                    DateFormat('HH:mm · dd/MM').format(_parseTxDate(tx.date));

                final txCatId = tx.categoryId?.trim().toLowerCase();
                final txCatName = tx.categoryName?.trim().toLowerCase();
                final matchingCat = allCats.cast<dynamic>().firstWhere(
                  (c) {
                    if (c == null) return false;
                    final cId = c.id?.toString().trim().toLowerCase();
                    final cName = c.name?.toString().trim().toLowerCase();
                    if (txCatId != null &&
                        txCatId.isNotEmpty &&
                        cId == txCatId) {
                      return true;
                    }
                    if (txCatName != null &&
                        txCatName.isNotEmpty &&
                        cName == txCatName) {
                      return true;
                    }
                    return false;
                  },
                  orElse: () => null,
                );
                final resolvedCategoryIcon =
                    matchingCat?.icon ?? tx.categoryIcon;
                final resolvedCategoryName =
                    matchingCat?.name ?? tx.categoryName;
                final resolvedCategoryColor =
                    matchingCat?.color ?? tx.categoryColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      TransactionIconWidget(
                        type: tx.type,
                        categoryIcon: resolvedCategoryIcon,
                        categoryName: resolvedCategoryName ?? tx.note,
                        categoryColor: resolvedCategoryColor,
                        merchantId: tx.merchantId,
                        merchantName: tx.merchantName,
                        showBankBadge: false,
                        showBorder: false,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (tx.note != null && tx.note!.isNotEmpty)
                                  ? tx.note!
                                  : (resolvedCategoryName != null &&
                                          resolvedCategoryName.isNotEmpty
                                      ? resolvedCategoryName
                                      : 'Giao dịch'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (resolvedCategoryName != null &&
                                    resolvedCategoryName.isNotEmpty) ...[
                                  Flexible(
                                    child: Text(
                                      resolvedCategoryName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
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
                            _obscureBalances
                                ? '••••••'
                                : '$prefix${formatVND(tx.amount)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, Wallet wallet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa ví "${wallet.name}"?'),
        content: const Text(
            'Tất cả số dư và giao dịch liên quan đến ví này có thể bị ảnh hưởng.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
              foregroundColor:
                  isDark ? Colors.white70 : const Color(0xFF64748B),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await context
                  .read<WalletProvider>()
                  .deleteWallet(wallet.id, widget.userId);
            },
            child: const Text('Xóa vĩnh viễn',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- SECTION: TRANSACTIONS HISTORY SLIVERS ---

  List<Widget> _buildTransactionsSlivers({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required TransactionProvider txProv,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final hasActiveFilter = txProv.selectedType != null ||
        txProv.searchQuery.isNotEmpty ||
        txProv.selectedMemberTag != null ||
        txProv.selectedDateFilter != DateFilterOption.thisMonth;

    // Nhóm giao dịch theo ngày (phân loại theo ngày)

    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (final tx in transactions) {
      final dt = _parseTxDate(tx.date);

      final dayKey = DateTime(dt.year, dt.month, dt.day);

      grouped.putIfAbsent(dayKey, () => []).add(tx);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      // Empty State or Grouped Transactions List

      // 4. Empty State or Grouped Transactions List

      if (transactions.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: _buildEmptySectionCard(
              icon: Icons.receipt_long_outlined,
              title: hasActiveFilter
                  ? 'Không tìm thấy giao dịch'
                  : 'Chưa có giao dịch',
              subtitle: hasActiveFilter
                  ? 'Thử thay đổi bộ lọc ngày, thành viên hoặc loại giao dịch để xem thêm.'
                  : 'Ghi lại các khoản thu, chi hoặc chuyển khoản để quản lý tài sản chính xác.',
              buttonLabel: hasActiveFilter ? 'Đặt lại bộ lọc' : 'Ghi chép ngay',
              onTap: hasActiveFilter
                  ? () {
                      HapticFeedback.selectionClick();

                      txProv.setSelectedType(null);

                      txProv.setSearchQuery('');

                      txProv.setSelectedMemberTag(null);

                      txProv.setSelectedDateFilter(DateFilterOption.thisMonth);

                      _searchController.clear();

                      setState(() => _isSearchOpen = false);
                    }
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) =>
                              AddTransactionPage(userId: widget.userId),
                        ),
                      ),
              isDark: isDark,
              accentColor: const Color(0xFF10B981),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, dayIndex) {
                final day = sortedDays[dayIndex];

                final dayTxs = grouped[day]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateGroupHeader(
                        day: day,
                        dayTxs: dayTxs,
                        isDark: isDark,
                        studio: studio,
                        isFirst: dayIndex == 0,
                      ),
                      for (int i = 0; i < dayTxs.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: studio?.freshAppearance == true
                                ? 0
                                : studio?.transactionListStyle ==
                                        AppTransactionListStyle.minimalDivided
                                    ? 0
                                    : (studio?.transactionListStyle ==
                                            AppTransactionListStyle.compactTable
                                        ? 5
                                        : 8),
                          ),
                          child: _buildWealthTransactionItem(
                            context: context,
                            tx: dayTxs[i],
                            isDark: isDark,
                            studio: studio,
                            isFirstInDay: i == 0,
                            isLastInDay: i == dayTxs.length - 1,
                          ),
                        ),
                    ],
                  ),
                );
              },
              childCount: sortedDays.length,
            ),
          ),
        ),
    ];
  }

  Widget _buildDateGroupHeader({
    required DateTime day,
    required List<TransactionModel> dayTxs,
    required bool isDark,
    required ThemeStudioController? studio,
    required bool isFirst,
  }) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    final d = DateTime(day.year, day.month, day.day);

    final isToday = d == today;

    final isYesterday = d == yesterday;

    const weekdaysVi = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];

    final weekday = weekdaysVi[day.weekday - 1];

    final dateStr = DateFormat('dd/MM/yyyy').format(day);

    int dayIncome = 0;

    int dayExpense = 0;

    for (final tx in dayTxs) {
      if (TransactionVisuals.isInflow(tx.type)) {
        dayIncome += tx.amount;
      } else if (TransactionVisuals.isOutflow(tx.type) &&
          !TransactionVisuals.isTransfer(tx.type)) {
        dayExpense += tx.amount;
      }
    }

    final hasIncome = dayIncome > 0;

    final hasExpense = dayExpense > 0;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 14, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Date Badge + Weekday/Date

          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isToday) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F6E56)
                              .withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hôm nay',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F6E56),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (isYesterday) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hôm qua',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      isToday || isYesterday
                          ? '$weekday • $dateStr'
                          : '$weekday, $dateStr',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right: Daily Inflow / Outflow Summary (Always pinned flush right)

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 175),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: FinoraPrivacyMask(
                isMasked: _obscureBalances,
                fallbackDots: '•••• đ',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasIncome)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '+${formatVND(dayIncome)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    if (hasIncome && hasExpense) const SizedBox(width: 4),
                    if (hasExpense)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48)
                              .withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '-${formatVND(dayExpense)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    if (!hasIncome && !hasExpense)
                      Text(
                        '${dayTxs.length} giao dịch',
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
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element

  Widget _buildInlineTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? accentColor,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();

        onTap();
      },
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F6E56)
              : (isDark ? const Color(0xFF141E1A) : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F6E56)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE3EBE7)),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF52665E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWealthTransactionItem({
    required BuildContext context,
    required TransactionModel tx,
    required bool isDark,
    required ThemeStudioController? studio,
    bool isFirstInDay = false,
    bool isLastInDay = false,
  }) {
    if (studio?.freshAppearance == true) {
      return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(isFirstInDay ? 22 : 0),
              bottom: Radius.circular(isLastInDay ? 22 : 0)),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                FinoraSwipeableTransactionCard(
                  userId: widget.userId,
                  transaction: tx,
                  borderRadius: 14,
                  child: IgnorePointer(
                    child: TransactionRow(
                      transaction: tx,
                      hidden: _obscureBalances,
                    ),
                  ),
                ),
                if (!isLastInDay)
                  Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4)),
              ])));
    }

    final categories = context.watch<MoreProvider>().categories;

    final txCatId = tx.categoryId?.trim().toLowerCase();

    final txCatName = tx.categoryName?.trim().toLowerCase();

    final matchingCategory = categories.cast<dynamic>().firstWhere(
      (c) {
        if (c == null) return false;

        final cId = c.id?.toString().trim().toLowerCase();

        final cName = c.name?.toString().trim().toLowerCase();

        if (txCatId != null && txCatId.isNotEmpty && cId == txCatId) {
          return true;
        }

        if (txCatName != null && txCatName.isNotEmpty && cName == txCatName) {
          return true;
        }

        return false;
      },
      orElse: () => null,
    );

    final resolvedCategoryIcon = matchingCategory?.icon ?? tx.categoryIcon;

    final resolvedCategoryName = matchingCategory?.name ?? tx.categoryName;

    final resolvedCategoryColor = matchingCategory?.color ?? tx.categoryColor;

    final wallets = context.watch<WalletProvider>().wallets;

    final wId = tx.walletId ?? tx.fromWalletId;

    final wName = tx.walletName ?? tx.fromWalletName;

    final matchingWallet = wallets.cast<Wallet?>().firstWhere(
          (w) =>
              (wId?.isNotEmpty == true && w?.id == wId) ||
              (wName?.isNotEmpty == true && w?.name == wName),
          orElse: () => null,
        );

    final walletDisplayName = matchingWallet?.name ?? wName ?? 'Ví chính';

    var effectiveCode = matchingWallet?.bankCode ?? matchingWallet?.type;

    if (effectiveCode == null || effectiveCode.isEmpty) {
      final clean =
          walletDisplayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (clean.contains('tietkiem') ||
          clean.contains('tiếtkiệm') ||
          clean.contains('mb')) {
        effectiveCode = 'mbbank';
      } else if (clean.contains('tcb') || clean.contains('techcom')) {
        effectiveCode = 'tcb';
      }
    }

    final brand = BankIconRegistry.resolve(
      effectiveCode ?? matchingWallet?.bankName,
      bankName: walletDisplayName,
    );

    final isFlowIn = TransactionVisuals.isInflow(tx.type);

    final isTransfer = TransactionVisuals.isTransfer(tx.type);

    final txDate = _parseTxDate(tx.date);

    final dateStr = DateFormat('HH:mm').format(txDate);

    final amountColor = TransactionVisuals.colorFor(tx.type);

    final amountPrefix = isTransfer ? '' : (isFlowIn ? '+' : '-');

    final statusLabel = switch (tx.type.toLowerCase()) {
      'lending' || 'loan' || 'lent' => 'Cho vay',
      'borrowing' || 'borrow' || 'debt' => 'Đi vay',
      'debt_repayment' || 'repayment' || 'debt_repayment_paid' => 'Trả nợ',
      'loan_repayment_received' || 'debt_collection' => 'Thu nợ',
      'investment' || 'invest' => 'Đầu tư',
      'saving' || 'savings' => 'Tiết kiệm',
      'credit_card_payment' => 'Trả thẻ',
      'transfer' => 'Chuyển tiền',
      'income' => 'Thu nhập',
      _ => isFlowIn ? 'Thu nhập' : 'Chi tiêu',
    };

    final style = studio?.transactionListStyle ??
        AppTransactionListStyle.modernStreamlined;

    final isLedger = style == AppTransactionListStyle.magazineLedger;

    final isBento = style == AppTransactionListStyle.bentoCards;

    final displayTitle = tx.note?.isNotEmpty == true
        ? tx.note!
        : (resolvedCategoryName ?? 'Giao dịch');

    Widget buildAmountBlock({bool compact = false, bool monospace = false}) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: FinoraPrivacyMask(
                isMasked: _obscureBalances,
                fallbackDots: '•••••••• đ',
                child: Text(
                  '$amountPrefix${formatVND(tx.amount)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: amountColor,
                    fontFamily: monospace ? 'monospace' : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2.5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final shortWallet = formatShortWalletName(walletDisplayName);
    final rawTagOwner = tx.tags?.firstWhere(
      (t) => FinoraMemberAvatar.normalizeMember(t) != null,
      orElse: () => '',
    );
    final ownerRole = FinoraMemberAvatar.normalizeMember(
          tx.owner ??
              tx.fromOwner ??
              tx.toOwner ??
              tx.ownerName ??
              tx.creatorTag ??
              (rawTagOwner != null && rawTagOwner.isNotEmpty
                  ? rawTagOwner
                  : null) ??
              matchingWallet?.owner ??
              walletDisplayName,
        ) ??
        'all';
    final ownerLabel = switch (ownerRole) {
      'husband' => 'Chồng',
      'wife' => 'Vợ',
      _ => 'Chung',
    };
    final bankCode = tx.bankTransactionCode?.trim();

    Widget buildIconWithSpenderBadge({
      double size = 40,
      double avatarSize = 15,
    }) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          TransactionIconWidget(
            type: tx.type,
            categoryIcon: resolvedCategoryIcon,
            categoryName: resolvedCategoryName ?? tx.note,
            categoryColor: resolvedCategoryColor,
            merchantId: tx.merchantId,
            merchantName: tx.merchantName,
            bankBrand: brand,
            showBankBadge: false,
            showBorder: false,
            size: size,
          ),
        ],
      );
    }

    Widget buildShortWalletPill({bool compact = false}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5.5 : 7,
          vertical: compact ? 1.5 : 2,
        ),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.09 : 0.055),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              if (brand.assetPath != null && brand.assetPath!.isNotEmpty) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3.5),
                    child: ClipOval(
                      child: Image.asset(
                        brand.assetPath!,
                        width: compact ? 10 : 11.5,
                        height: compact ? 10 : 11.5,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
              TextSpan(text: shortWallet),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 9.5 : 10.2,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      );
    }

    Widget buildOwnerPill({bool compact = false}) {
      final isWife = ownerLabel == 'Vợ';
      final isHusband = ownerLabel == 'Chồng';
      final pillColor = isWife
          ? const Color(0xFFEC4899)
          : isHusband
              ? const Color(0xFF0EA5E9)
              : const Color(0xFF10B981);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6.5,
          vertical: compact ? 1 : 1.8,
        ),
        decoration: BoxDecoration(
          color: pillColor.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: pillColor.withValues(alpha: 0.28),
            width: 0.7,
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 3.5),
                  child: FinoraMemberAvatar(
                    role: ownerRole,
                    size: compact ? 11 : 12.5,
                    studio: studio,
                  ),
                ),
              ),
              TextSpan(text: ownerLabel),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 9 : 9.8,
            fontWeight: FontWeight.w800,
            color: pillColor,
          ),
        ),
      );
    }

    Widget buildRedesignedDetails({
      bool compact = false,
      int maxLines = 1,
      bool showOwnerChip = false,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayTitle,
              style: TextStyle(
                fontSize: compact ? 13 : 14.5,
                fontWeight:
                    isBento || isLedger ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.2,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                height: 1.22,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 2.5 : 4.5),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 3,
              children: [
                buildShortWalletPill(compact: compact),
                if (showOwnerChip) buildOwnerPill(compact: compact),
                if (resolvedCategoryName != null &&
                    resolvedCategoryName.isNotEmpty &&
                    resolvedCategoryName != displayTitle)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.07 : 0.04),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      resolvedCategoryName,
                      style: TextStyle(
                        fontSize: compact ? 9.5 : 10.2,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFA3B4D4)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                if (bankCode != null && bankCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$bankCode',
                      style: const TextStyle(
                        fontSize: 9.2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: compact ? 9.8 : 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget cardBody;
    final cardAlpha = (studio?.glassOpacity ?? 0.90).clamp(0.18, 0.99);
    final baseCardColor = isDark
        ? const Color(0xFF142033).withValues(alpha: cardAlpha)
        : Colors.white.withValues(alpha: cardAlpha);

    switch (style) {
      // STYLE 6: Lụa Phẳng Tinh Khiết (Pure Silk Hairline)
      case AppTransactionListStyle.minimalDivided:
        cardBody = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : const Color(0xFFE2E8F0),
                width: 0.9,
              ),
            ),
          ),
          child: Row(
            children: [
              buildIconWithSpenderBadge(size: 38, avatarSize: 15),
              const SizedBox(width: 12),
              buildRedesignedDetails(showOwnerChip: true),
              const SizedBox(width: 8),
              buildAmountBlock(),
            ],
          ),
        );
        break;

      // STYLE 4: Sổ Cái Hoàng Gia (Editorial Ribbon Ledger)
      case AppTransactionListStyle.magazineLedger:
        cardBody = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  amountColor.withValues(alpha: isDark ? 0.12 : 0.06),
                  baseCardColor,
                ),
                baseCardColor,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: amountColor.withValues(alpha: isDark ? 0.28 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: (isDark ? 0.20 : 0.03) * cardAlpha),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          amountColor,
                          amountColor.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                      child: Row(
                        children: [
                          buildIconWithSpenderBadge(size: 40, avatarSize: 15),
                          const SizedBox(width: 12),
                          buildRedesignedDetails(showOwnerChip: true),
                          const SizedBox(width: 8),
                          buildAmountBlock(monospace: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      // STYLE 5: Bảng Vi Mạch (Micro Matrix Row)
      case AppTransactionListStyle.compactTable:
        cardBody = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
          decoration: BoxDecoration(
            color: baseCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.07 : 0.05),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              buildIconWithSpenderBadge(size: 30, avatarSize: 12.5),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    buildShortWalletPill(compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              buildAmountBlock(compact: true),
            ],
          ),
        );
        break;

      // STYLE 2: Hộp Ngọc Bento (Luxury Bento Box)
      case AppTransactionListStyle.bentoCards:
        cardBody = Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: baseCardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: amountColor.withValues(alpha: isDark ? 0.38 : 0.24),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: amountColor.withValues(
                    alpha: (isDark ? 0.14 : 0.06) * cardAlpha),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              buildIconWithSpenderBadge(size: 42, avatarSize: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.8,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        buildOwnerPill(compact: true),
                        buildShortWalletPill(compact: true),
                        if (bankCode != null && bankCode.isNotEmpty)
                          Text(
                            '#$bankCode',
                            style: const TextStyle(
                              fontSize: 9.2,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              buildAmountBlock(),
            ],
          ),
        );
        break;

      // STYLE 3: Trục Thời Gian (Chrono Pulse Rail)
      case AppTransactionListStyle.timelineRail:
        final bentoBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10.5),
          decoration: BoxDecoration(
            color: baseCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: amountColor.withValues(alpha: isDark ? 0.22 : 0.14),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              buildIconWithSpenderBadge(size: 38, avatarSize: 14.5),
              const SizedBox(width: 11),
              buildRedesignedDetails(showOwnerChip: true),
              const SizedBox(width: 8),
              buildAmountBlock(),
            ],
          ),
        );

        cardBody = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 38,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: amountColor,
                      boxShadow: [
                        BoxShadow(
                          color: amountColor.withValues(alpha: 0.45),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(child: bentoBox),
          ],
        );
        break;

      // STYLE 1: Pha lê Zenvest (Crystal Pill Deck)
      case AppTransactionListStyle.modernStreamlined:
        cardBody = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
          decoration: BoxDecoration(
            color: baseCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.08 : 0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: (isDark ? 0.18 : 0.03) * cardAlpha),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              buildIconWithSpenderBadge(size: 40, avatarSize: 15),
              const SizedBox(width: 12),
              buildRedesignedDetails(showOwnerChip: false),
              const SizedBox(width: 8),
              buildAmountBlock(),
            ],
          ),
        );
        break;
    }

    return FinoraSwipeableTransactionCard(
      userId: widget.userId,
      transaction: tx,
      borderRadius: 18,
      child: cardBody,
    );
  }

  DateTime _parseTxDate(dynamic raw) {
    if (raw == null) return DateTime.now();

    if (raw is DateTime) return raw;

    if (raw is int) {
      if (raw <= 0) return DateTime.now();

      if (raw > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }

      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }

    if (raw is String) {
      final asInt = int.tryParse(raw);

      if (asInt != null) {
        return _parseTxDate(asInt);
      }

      try {
        return DateTime.parse(raw);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parse(raw);
        } catch (_) {}
      }
    }

    return DateTime.now();
  }

  // --- 4. SECTION 2: ASSETS & INVESTMENTS SLIVERS ---

  List<Widget> _buildAssetsSlivers({
    required BuildContext context,
    required List<Asset> assets,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH MỤC ĐẦU TƯ (${assets.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFA3B4D4)
                      : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              FinoraAddButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddTransactionPage(
                      userId: widget.userId,
                      initialType: 'investment',
                    ),
                  ),
                ),
                tooltip: 'Ghi nhận đầu tư',
                size: 30,
                color: const Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ),
      if (assets.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: _buildEmptySectionCard(
              icon: Icons.trending_up_rounded,
              title: 'Chưa có tài sản tích luỹ',
              subtitle:
                  'Theo dõi vàng miếng, bất động sản, cổ phiếu, sổ tiết kiệm hoặc dây hụi.',
              buttonLabel: 'Ghi chép đầu tư',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionPage(
                    userId: widget.userId,
                    initialType: 'investment',
                  ),
                ),
              ),
              isDark: isDark,
              accentColor: const Color(0xFFD97706),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final asset = assets[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildAssetTile(context, asset, isDark),
                );
              },
              childCount: assets.length,
            ),
          ),
        ),
    ];
  }

  Widget _buildAssetTile(BuildContext context, Asset asset, bool isDark) {
    final value = asset.marketValue > 0 ? asset.marketValue : asset.costBasis;

    final diff = asset.marketValue > 0 && asset.costBasis > 0
        ? asset.marketValue - asset.costBasis
        : 0;

    final diffPercent =
        asset.costBasis > 0 ? (diff / asset.costBasis) * 100 : 0.0;

    final isProfitable = diff >= 0;

    final visual = _resolveAssetVisual(asset.type);

    return AdaptiveGlassSurface(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();

            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) =>
                    AddAssetPage(userId: widget.userId, asset: asset),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Modern squircle asset badge with dual-tone gradient

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        visual.gradient[0]
                            .withValues(alpha: isDark ? 0.25 : 0.15),
                        visual.gradient[1]
                            .withValues(alpha: isDark ? 0.35 : 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: visual.gradient[0]
                          .withValues(alpha: isDark ? 0.40 : 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      visual.icon,
                      color: visual.gradient[0],
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Asset Info

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        asset.name,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Giá vốn: ${formatVND(asset.costBasis)}',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Market Value & Profit Pill

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FinoraPrivacyMask(
                      child: Text(
                        formatVND(value),
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (diff != 0) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isProfitable
                                  ? const Color(0xFF00866A)
                                  : const Color(0xFFE11D48))
                              .withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: (isProfitable
                                    ? const Color(0xFF00866A)
                                    : const Color(0xFFE11D48))
                                .withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isProfitable
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              size: 14,
                              color: isProfitable
                                  ? const Color(0xFF00866A)
                                  : const Color(0xFFE11D48),
                            ),
                            Text(
                              (isProfitable ? '+' : '') +
                                  diffPercent.toStringAsFixed(1) +
                                  '%',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isProfitable
                                    ? const Color(0xFF00866A)
                                    : const Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(width: 4),

                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  elevation: 10,
                  shadowColor:
                      Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 17,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) =>
                              AddAssetPage(userId: widget.userId, asset: asset),
                        ),
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteAsset(context, asset);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 42,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 15, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Chỉnh sửa',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem(
                      value: 'delete',
                      height: 42,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Color(0xFFE11D48)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Xóa',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({IconData icon, List<Color> gradient, String categoryName})
      _resolveAssetVisual(String type) {
    switch (type.toLowerCase()) {
      case 'gold':
        return (
          icon: LucideIcons.coins,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          categoryName: 'Vàng & Kim loại quý',
        );

      case 'real_estate':
        return (
          icon: LucideIcons.building_2,
          gradient: const [Color(0xFF0D9488), Color(0xFF059669)],
          categoryName: 'Bất động sản',
        );

      case 'stock':
        return (
          icon: LucideIcons.trending_up,
          gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          categoryName: 'Cổ phiếu & Quỹ',
        );

      case 'savings':
        return (
          icon: LucideIcons.landmark,
          gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
          categoryName: 'Tiết kiệm / Trái phiếu',
        );

      case 'crypto':
        return (
          icon: LucideIcons.zap,
          gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
          categoryName: 'Tài sản số',
        );

      case 'hui_phuong':
        return (
          icon: LucideIcons.users,
          gradient: const [Color(0xFFEA580C), Color(0xFFC2410C)],
          categoryName: 'Hụi / Phường',
        );

      default:
        return (
          icon: LucideIcons.gem,
          gradient: const [Color(0xFF0284C7), Color(0xFF2563EB)],
          categoryName: 'Tài sản đầu tư',
        );
    }
  }

  void _confirmDeleteAsset(BuildContext context, Asset asset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa tài sản "${asset.name}"?'),
        content: const Text(
            'Tài sản này sẽ bị xóa khỏi danh mục đầu tư và trừ ra khỏi Tài sản ròng.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
              foregroundColor:
                  isDark ? Colors.white70 : const Color(0xFF64748B),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await context
                  .read<MoreProvider>()
                  .deleteAsset(widget.userId, asset.id);
            },
            child: const Text('Xóa',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- 5. SECTION 3: LOANS & DEBTS SLIVERS ---

  List<Widget> _buildLoansSlivers({
    required BuildContext context,
    required List<Loan> loans,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final filtered = loans.where((l) => l.type == _loanSubTab).toList();

    final isLent = _loanSubTab == 'lent';

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isLent ? "DANH SÁCH CHO VAY" : "DANH SÁCH VAY NỢ"} (${filtered.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFA3B4D4)
                      : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: _buildEmptySectionCard(
              icon: Icons.handshake_outlined,
              title: isLent
                  ? 'Chưa có khoản cho vay'
                  : 'Bạn không có khoản nợ nào',
              subtitle: isLent
                  ? 'Ghi nhận các khoản bạn cho người thân, bạn bè vay để nhắc nhở thu hồi.'
                  : 'Ghi nhận các khoản vay ngân hàng hoặc cá nhân để lên kế hoạch trả nợ.',
              buttonLabel: isLent ? 'Thêm khoản cho vay' : 'Thêm khoản vay nợ',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => GlassBottomSheet(
                  radius: 30,
                  child: AddLoanSheet(
                      userId: widget.userId, initialType: _loanSubTab),
                ),
              ),
              isDark: isDark,
              accentColor:
                  isLent ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final loan = filtered[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildLoanTile(context, loan, isDark),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
    ];
  }

  Widget _buildLoanTile(BuildContext context, Loan loan, bool isDark) {
    final lent = loan.type == 'lent';

    final progress = loan.principalAmount > 0
        ? (loan.paidAmount / loan.principalAmount).clamp(0.0, 1.0)
        : 0.0;

    final accent = lent ? const Color(0xFF059669) : const Color(0xFFE11D48);

    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);

    final secondaryText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    DateTime? dueDt;

    if (loan.dueDate != null && loan.dueDate! > 0) {
      final dVal = loan.dueDate!;

      dueDt = DateTime.fromMillisecondsSinceEpoch(
        dVal > 100000000000 ? dVal : dVal * 1000,
      );
    }

    final rawNote = (loan.note ?? '').trim();

    final walletLabel = (loan.walletName ?? '').trim();

    String bottomSummary = '';

    if (dueDt != null && rawNote.isNotEmpty) {
      bottomSummary =
          'Hạn: ${DateFormat('dd/MM/yyyy').format(dueDt)} • $rawNote';
    } else if (dueDt != null) {
      bottomSummary =
          'Hạn trả dự kiến: ${DateFormat('dd/MM/yyyy').format(dueDt)}';
    } else if (rawNote.isNotEmpty) {
      bottomSummary = rawNote;
    } else {
      bottomSummary =
          lent ? 'Khoản cho vay đang theo dõi' : 'Khoản nợ đang theo dõi';
    }

    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final glassOpacity = studio?.glassOpacity ?? 0.88;
    return AdaptiveGlassSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
            alpha: isDark
                ? (0.65 * glassOpacity).clamp(0.2, 0.95)
                : (0.88 * glassOpacity).clamp(0.2, 0.95)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Avatar + Full Person Name & Badges + Right-Pinned Remaining Principal + Menu

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.38 : 0.25),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    lent
                        ? LucideIcons.arrow_up_right
                        : LucideIcons.arrow_down_left,
                    color: accent,
                    size: 21,
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
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lent ? 'Cho vay' : 'Vay nợ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        if (walletLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              walletLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right-pinned remaining principal

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: FinoraPrivacyMask(
                        isMasked: _obscureBalances,
                        fallbackDots: '•••••••• đ',
                        child: Text(
                          formatVND(loan.remainingPrincipal),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        lent ? 'Cần thu về' : 'Cần phải trả',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                elevation: 10,
                shadowColor:
                    Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 17,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                onSelected: (val) {
                  if (val == 'repay') {
                    _showRepayDialog(context, loan);
                  } else if (val == 'delete') {
                    _confirmDeleteLoan(context, loan);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'repay',
                    height: 42,
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            lent
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 15,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          lent ? 'Thu nợ' : 'Trả nợ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    height: 42,
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE11D48).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Color(0xFFE11D48)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Xóa khoản nợ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Clean 2-Column Metric Box (Tiền gốc | Đã thu/trả %)

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.55)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiền gốc',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatVND(loan.principalAmount),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.10),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tiến độ hoàn trả',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Đã ${lent ? "thu" : "trả"}: ${formatVND(loan.paidAmount)} (${(progress * 100).round()}%)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Smooth 7px Rounded Progress Bar

          Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. Bottom Row: Full Note & Due Date (maxLines: 2) + Solid Stadium-Pill Action Button

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                dueDt != null ? Icons.event_note_rounded : Icons.notes_rounded,
                size: 14,
                color: secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bottomSummary,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showRepayDialog(context, loan),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        lent ? 'Thu nợ' : 'Trả nợ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLoan(BuildContext context, Loan loan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa khoản vay "${loan.personName}"?'),
        content: const Text('Khoản nợ này sẽ bị xóa vĩnh viễn khỏi sổ nợ.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
              foregroundColor:
                  isDark ? Colors.white70 : const Color(0xFF64748B),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await context
                  .read<MoreProvider>()
                  .deleteLoan(widget.userId, loan.id);
            },
            child: const Text('Xóa',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- EMPTY CARD WIDGET ---

  Widget _buildEmptySectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.08 : 0.06),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          const FinoraMascotImage(
            pose: FinoraMascotPose.happy,
            size: 72,
            withGlow: true,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFFA3B4D4) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          FinoraButton(
            onPressed: onTap,
            variant: FinoraButtonVariant.compact,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16),
                const SizedBox(width: 4),
                Text(buttonLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zenvest Wealth Bloom Painter

/// Vẽ dải hào quang theo màu chủ đạo của từng tab trên Hero Card Tài sản & Dòng tiền

class _ZenvestWealthBloomPainter extends CustomPainter {
  final Color themeColor;

  final bool isDark;

  const _ZenvestWealthBloomPainter({
    required this.themeColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.42);

    final highlight = Color.lerp(themeColor, Colors.white, 0.35)!;

    // 1. Vầng sáng theo màu chủ đạo của tab

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          highlight.withValues(alpha: isDark ? 0.24 : 0.30),
          themeColor.withValues(alpha: isDark ? 0.12 : 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: size.height * 0.85,
      ));

    canvas.drawCircle(center, size.height * 0.85, paint1);

    // 2. Vầng phản quang trắng nhẹ ở góc trên phải

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.80],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.92, size.height * 0.18),
        radius: size.height * 0.55,
      ));

    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.18),
        size.height * 0.55, paint2);

    // 3. Subtle concentric watermark arcs for premium fintech depth

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.05 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, size.height * 0.45, arcPaint);

    canvas.drawCircle(center, size.height * 0.68, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ZenvestWealthBloomPainter oldDelegate) {
    return oldDelegate.themeColor != themeColor || oldDelegate.isDark != isDark;
  }
}
