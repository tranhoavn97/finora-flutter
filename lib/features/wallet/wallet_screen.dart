import '../../core/widgets/finora_summary_card.dart';
import 'web_wallet_card.dart';
import '../../core/widgets/ai_context_button.dart';
import '../../core/design_system/credit_card_palette.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../data/models/wallet.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/wallet_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../transaction/transaction_history_sheet.dart';
import '../transaction/add_transaction_page.dart';
import 'add_wallet_page.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/finora_bank_card_surface.dart';

class _AuditMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _AuditMetric(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatVND(value),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      );
}

class WalletScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final bool isRoot;
  const WalletScreen(
      {super.key, required this.userId, this.familyId, this.isRoot = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  StreamSubscription<String>? _eventsSub;
  String _accountTab = 'all';
  bool _showBalances = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WalletProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.load(widget.userId, familyId: widget.familyId);
    });
    _eventsSub = provider.events.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  void didUpdateWidget(covariant WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.familyId != widget.familyId) {
      context
          .read<WalletProvider>()
          .load(widget.userId, familyId: widget.familyId);
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAddWallet({Wallet? wallet}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddWalletPage(userId: widget.userId, wallet: wallet),
      ),
    );
  }

  void _showHistory(Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _showBalanceReconciliation() {
    final provider = context.read<WalletProvider>();
    final wallets = provider.wallets;
    final transactions = provider.transactions;

    showFinoraGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      title: 'Đối soát số dư',
      subtitle: 'Số dư gốc + biến động = hiện tại',
      icon: Icons.fact_check_rounded,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: wallets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final wallet = wallets[index];
            var incoming = 0;
            var outgoing = 0;
            for (final tx in transactions) {
              final single =
                  WalletRepository.computeWalletsWithBalances([wallet], [tx])
                      .first;
              final signed = wallet.isCreditCard
                  ? -(single.currentDebt - wallet.initialDebt)
                  : single.balance - wallet.initialBalance;
              if (signed > 0) incoming += signed;
              if (signed < 0) outgoing += -signed;
            }
            final baseline = wallet.isCreditCard
                ? wallet.initialDebt
                : wallet.initialBalance;
            // Compare against the same aggregate ledger calculation
            // used by WalletProvider. Rebuilding each transaction in
            // isolation is incorrect for credit-card repayments
            // because the debt clamp would be applied once per item.
            final reconciled = WalletRepository.computeWalletsWithBalances(
                    [wallet], transactions)
                .first;
            final expected = wallet.isCreditCard
                ? reconciled.currentDebt
                : reconciled.balance;
            final current =
                wallet.isCreditCard ? wallet.currentDebt : wallet.balance;
            final difference = current - expected;
            final matched = difference == 0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: matched
                      ? const Color(0xFF10B981).withValues(alpha: 0.22)
                      : const Color(0xFFEF4444).withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(wallet.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: (matched
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          matched ? 'Khớp' : 'Lệch ${formatVND(difference)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: matched
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AuditMetric('Ban đầu', baseline),
                      _AuditMetric(wallet.isCreditCard ? 'Giảm nợ' : 'Tiền vào',
                          incoming,
                          color: const Color(0xFF059669)),
                      _AuditMetric(
                          wallet.isCreditCard ? 'Tăng nợ' : 'Tiền ra', outgoing,
                          color: const Color(0xFFDC2626)),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(wallet.isCreditCard
                          ? 'Dư nợ hiện tại'
                          : 'Số dư hiện tại'),
                      Text(formatVND(current),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context, {bool isCredit = false}) {
    return FinoraAddButton(
      tooltip: isCredit ? 'Thêm thẻ tín dụng' : 'Thêm ví mới',
      size: 34,
      onPressed: () => _openAddWallet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final wallets = context.watch<WalletProvider>().wallets;

    final totalAssets = wallets
        .where((w) => !w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.balance);
    final totalDebt = wallets
        .where((w) => w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.currentDebt);

    final creditCards = wallets.where((w) => w.isCreditCard).toList();
    final normalWallets = wallets.where((w) => !w.isCreditCard).toList();

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardRadius = studio?.cardCornerRadius ?? 22.0;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Ví & Tài khoản',
        actions: [AiContextButton(userId: widget.userId, screen: 'Ví tiền')],
        showBottomDivider: false,
        onBack: (!widget.isRoot && Navigator.of(context).canPop())
            ? () => Navigator.of(context).pop()
            : null,
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                GlassScaffold.topInset(context, 8),
                12,
                8,
              ),
              child: _buildNetBalanceSummaryCard(
                cardRadius: cardRadius,
                studio: studio,
                isDark: isDark,
                totalAssets: totalAssets,
                totalDebt: totalDebt,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAccountTabs(wallets, studio, isDark),
                  ),
                  const SizedBox(width: 8),
                  _buildViewModeSelector(studio, isDark),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 120),
            sliver: SliverToBoxAdapter(
              child: wallets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.account_balance_wallet,
                        title: 'Chưa có ví tài khoản nào',
                        subtitle: 'Hãy thêm ví đầu tiên để quản lý.',
                        actionText: '+ Thêm ví',
                        onAction: () => _openAddWallet(),
                      ),
                    )
                  : _buildWalletsContentByStyle(
                      studio: studio,
                      creditCards:
                          _accountTab == 'all' || _accountTab == 'credit'
                              ? creditCards
                              : const [],
                      normalWallets: normalWallets
                          .where((wallet) =>
                              _accountTab == 'all' ||
                              (_accountTab == 'cash' &&
                                  (wallet.type == 'cash' ||
                                      wallet.type == 'ewallet')) ||
                              (_accountTab == 'bank' &&
                                  wallet.type != 'cash' &&
                                  wallet.type != 'ewallet'))
                          .toList(),
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceSummaryCard({
    required double cardRadius,
    required ThemeStudioController? studio,
    required bool isDark,
    required int totalAssets,
    required int totalDebt,
  }) {
    final masked = (studio?.isPrivacyShieldActive ?? false) || !_showBalances;
    return FinoraSummaryCard(
        title: 'TỔNG TÀI SẢN THANH KHOẢN',
        amount: totalAssets - totalDebt,
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF007AFF),
        masked: masked,
        subtitle: 'Tài sản ròng sau khi trừ dư nợ thẻ',
        badgeText: 'Khả dụng thực',
        badgeColor: const Color(0xFF34C759),
        metricColors: const [Color(0xFF34C759), Color(0xFFFF3B30)],
        metrics: [('Tiền khả dụng', totalAssets), ('Dư nợ thẻ', totalDebt)],
        actions: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              tooltip: masked ? 'Hiện số dư' : 'Ẩn số dư',
              onPressed: () => setState(() => _showBalances = !_showBalances),
              icon: Icon(
                  masked
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19)),
          IconButton(
              tooltip: 'Đối soát số dư',
              onPressed: _showBalanceReconciliation,
              icon: const Icon(Icons.fact_check_outlined, size: 19))
        ]));
  }

  Widget _buildCreditHealthBanner({
    required List<Wallet> creditCards,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    if (creditCards.isEmpty) return const SizedBox.shrink();

    final totalLimit =
        creditCards.fold<int>(0, (sum, w) => sum + w.creditLimit);
    final totalDebt = creditCards.fold<int>(0, (sum, w) => sum + w.currentDebt);
    final ratio = totalLimit > 0 ? (totalDebt / totalLimit) : 0.0;
    final ratioPercent = (ratio * 100).toStringAsFixed(0);

    Color healthColor;
    String healthStatus;
    IconData healthIcon;

    if (ratio <= 0.30) {
      healthColor = const Color(0xFF10B981);
      healthStatus = 'Tỷ lệ an toàn ($ratioPercent%)';
      healthIcon = Icons.verified_user_rounded;
    } else if (ratio <= 0.70) {
      healthColor = const Color(0xFFF59E0B);
      healthStatus = 'Tỷ lệ trung bình ($ratioPercent%)';
      healthIcon = Icons.info_outline_rounded;
    } else {
      healthColor = const Color(0xFFEF4444);
      healthStatus = 'Cảnh báo nợ cao ($ratioPercent%)';
      healthIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: isDark ? 0.75 : 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: healthColor.withValues(alpha: isDark ? 0.30 : 0.20),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: healthColor.withValues(alpha: 0.08),
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
              Row(
                children: [
                  Icon(healthIcon, size: 15, color: healthColor),
                  const SizedBox(width: 6),
                  Text(
                    'SỨC KHỎE HẠN MỨC TÍN DỤNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  healthStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng dư nợ: ${formatVND(totalDebt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: healthColor,
                ),
              ),
              Text(
                'Tổng hạn mức: ${formatVND(totalLimit)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector(ThemeStudioController? studio, bool isDark) {
    if (studio == null) return const SizedBox.shrink();
    final currentStyle = studio.walletViewStyle;
    final primary = studio.resolvedPrimary;

    final options = [
      (AppWalletViewStyle.webCards, 'Thẻ ngân hàng', Icons.credit_card),
      (AppWalletViewStyle.stackedDeck, 'Xếp 3D', Icons.view_carousel_rounded),
      (AppWalletViewStyle.verticalList, 'Dọc', Icons.view_agenda_rounded),
      (AppWalletViewStyle.gridBento, 'Bento', Icons.grid_view_rounded),
      (
        AppWalletViewStyle.compactList,
        'Gọn',
        Icons.format_list_bulleted_rounded
      ),
    ];

    final currentOpt =
        options.firstWhere((option) => option.$1 == currentStyle);

    return PopupMenuButton<AppWalletViewStyle>(
      tooltip: 'Đổi kiểu hiển thị ví',
      onSelected: studio.setWalletViewStyle,
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option.$1,
                child: Row(children: [
                  Icon(option.$3, size: 18, color: primary),
                  const SizedBox(width: 10),
                  Text(option.$2),
                  if (currentStyle == option.$1) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: primary, size: 18),
                  ],
                ]),
              ))
          .toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: isDark ? 0.65 : 0.88),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentOpt.$3, size: 16, color: primary),
            const SizedBox(width: 5),
            Text(
              currentOpt.$2,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTabs(
      List<Wallet> wallets, ThemeStudioController? studio, bool isDark) {
    final options = [
      ('all', 'Tất cả', wallets.length),
      ('credit', 'Thẻ tín dụng', wallets.where((w) => w.isCreditCard).length),
      (
        'cash',
        'Ví tiền',
        wallets
            .where((w) =>
                !w.isCreditCard && (w.type == 'cash' || w.type == 'ewallet'))
            .length
      ),
      (
        'bank',
        'Ngân hàng',
        wallets
            .where((w) =>
                !w.isCreditCard && w.type != 'cash' && w.type != 'ewallet')
            .length
      ),
    ];
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: isDark ? 0.65 : 0.88),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = _accountTab == option.$1;
          return GestureDetector(
            onTap: () {
              studio?.performHaptic();
              setState(() => _accountTab = option.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const [
                        Color(0xFF0066ff),
                        Color(0xFF008e91),
                        Color(0xFF009e60),
                        Color(0xFF007fc4)
                      ][index]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                boxShadow: const [],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.$2,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${option.$3}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletsContentByStyle({
    required ThemeStudioController? studio,
    required List<Wallet> creditCards,
    required List<Wallet> normalWallets,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final style = studio?.walletViewStyle ?? AppWalletViewStyle.webCards;
    final showCreditBanner = creditCards.isNotEmpty &&
        (_accountTab == 'all' || _accountTab == 'credit');

    Widget content;
    switch (style) {
      case AppWalletViewStyle.webCards:
        final rows = [...normalWallets, ...creditCards];
        content = LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
          return Wrap(
              spacing: 14,
              runSpacing: 10,
              children: rows
                  .map((w) => SizedBox(
                      width: width,
                      child: WebWalletCard(
                          wallet: w,
                          masked: !_showBalances ||
                              (studio?.isPrivacyShieldActive ?? false),
                          onHistory: () => _showHistory(w),
                          onEdit: () => _openAddWallet(wallet: w),
                          onDelete: () => _deleteWallet(w),
                          onPay: w.isCreditCard
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => AddTransactionPage(
                                          userId: widget.userId,
                                          initialType: 'credit_card_payment',
                                          initialWalletId: w.id)))
                              : null)))
                  .toList());
        });
        break;
      case AppWalletViewStyle.verticalList:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (creditCards.isNotEmpty) ...[
              _buildSectionTitle(
                  'Thẻ tín dụng (${creditCards.length})', primaryTextColor),
              const SizedBox(height: 10),
              for (final c in creditCards) ...[
                _buildCreditCardItem(c),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 10),
            ],
            if (normalWallets.isNotEmpty) ...[
              _buildSectionTitle(
                  'Ví tiền & Ngân hàng (${normalWallets.length})',
                  primaryTextColor),
              const SizedBox(height: 10),
              for (final w in normalWallets) ...[
                _buildVerticalWalletCard(
                    w, isDark, primaryTextColor, secondaryTextColor),
                const SizedBox(height: 10),
              ],
            ],
          ],
        );
        break;

      case AppWalletViewStyle.gridBento:
        final allWallets = [...creditCards, ...normalWallets];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Tất cả tài khoản (${allWallets.length})', primaryTextColor),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.18,
              ),
              itemCount: allWallets.length,
              itemBuilder: (context, index) {
                final w = allWallets[index];
                return _buildBentoWalletTile(
                    w, isDark, primaryTextColor, secondaryTextColor);
              },
            ),
          ],
        );
        break;

      case AppWalletViewStyle.compactList:
        final allWallets = [...creditCards, ...normalWallets];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Bảng kê tài khoản (${allWallets.length})', primaryTextColor),
            const SizedBox(height: 10),
            for (final w in allWallets)
              _buildCompactWalletRow(
                  w, isDark, primaryTextColor, secondaryTextColor),
          ],
        );
        break;

      case AppWalletViewStyle.stackedDeck:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (creditCards.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thẻ tín dụng (${creditCards.length})',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _buildHeaderButton(context),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _WalletCardDeck(
                cards: creditCards,
                cardHeight: 204.0,
                builder: (context, w) => _buildCreditCardItem(w),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (normalWallets.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ví tiền & Tài khoản ngân hàng (${normalWallets.length})',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _buildHeaderButton(context),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _WalletCardDeck(
                cards: normalWallets,
                cardHeight: 174.0,
                builder: (context, w) => _buildVerticalWalletCard(
                  w,
                  isDark,
                  primaryTextColor,
                  secondaryTextColor,
                ),
              ),
            ],
          ],
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCreditBanner)
          _buildCreditHealthBanner(
            creditCards: creditCards,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
        content,
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        _buildHeaderButton(context),
      ],
    );
  }

  Widget _buildCreditCardItem(Wallet w) {
    return _CreditCardRow(
      wallet: w,
      onDelete: () => _deleteWallet(w),
      onTap: () => _showHistory(w),
      onEdit: () => _openAddWallet(wallet: w),
      onPay: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(
              userId: widget.userId,
              initialType: 'credit_card_payment',
              initialWalletId: w.id,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalWalletCard(
    Wallet wallet,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return _NormalWalletCard(
      wallet: wallet,
      isExpanded: true,
      onDelete: () => _deleteWallet(wallet),
      onTap: () => _showHistory(wallet),
      onEdit: () => _openAddWallet(wallet: wallet),
    );
  }

  Widget _buildBentoWalletTile(
    Wallet w,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showHistory(w),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BankIcon(
                  bankCode: w.bankCode ?? w.type,
                  bankName: w.bankName ?? w.name,
                  size: 26,
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openAddWallet(wallet: w);
                    } else if (val == 'delete') {
                      _deleteWallet(w);
                    }
                  },
                  icon: Icon(Icons.more_horiz_rounded,
                      size: 16, color: secondaryTextColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child:
                            Text('Chỉnh sửa', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa',
                            style: TextStyle(fontSize: 13, color: Colors.red))),
                  ],
                ),
              ],
            ),
            Text(
              w.name,
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            FinoraAnimatedAmount(
              amount: (w.isCreditCard ? w.currentDebt : w.balance).toDouble(),
              style: TextStyle(
                color: w.isCreditCard
                    ? const Color(0xFFF87171)
                    : (isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF059669)),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWalletRow(
    Wallet w,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          BankIcon(
            bankCode: w.bankCode ?? w.type,
            bankName: w.bankName ?? w.name,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  w.isCreditCard
                      ? 'Thẻ tín dụng'
                      : (w.type == 'cash' ? 'Tiền mặt' : 'Ngân hàng'),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FinoraAnimatedAmount(
                amount: (w.isCreditCard ? w.currentDebt : w.balance).toDouble(),
                style: TextStyle(
                  color: w.isCreditCard
                      ? const Color(0xFFF87171)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                w.isCreditCard ? 'Dư nợ' : 'Khả dụng',
                style: TextStyle(color: secondaryTextColor, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                _openAddWallet(wallet: w);
              } else if (val == 'delete') {
                _deleteWallet(w);
              }
            },
            icon: Icon(Icons.more_vert, size: 16, color: secondaryTextColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Text('Chỉnh sửa', style: TextStyle(fontSize: 13))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa',
                      style: TextStyle(fontSize: 13, color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet(Wallet w) async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa ví / tài khoản?',
      content: 'Bạn có chắc chắn muốn xóa "${w.name}" không?',
    );
    if (confirm && mounted) {
      context.read<WalletProvider>().deleteWallet(widget.userId, w.id);
    }
  }
}

class _WalletCardDeck extends StatefulWidget {
  final List<Wallet> cards;
  final Widget Function(BuildContext context, Wallet wallet) builder;
  final double cardHeight;

  const _WalletCardDeck({
    required this.cards,
    required this.builder,
    this.cardHeight = 204.0,
  });

  @override
  State<_WalletCardDeck> createState() => _WalletCardDeckState();
}

class _WalletCardDeckState extends State<_WalletCardDeck>
    with TickerProviderStateMixin {
  int _current = 0;
  bool _isFannedOut = false;
  double _dragX = 0.0;
  double _dragY = 0.0;

  late final AnimationController _fanAnimController;
  late final Animation<double> _fanAnimation;

  late final AnimationController _swipeAnimController;
  late Animation<double> _swipeOffsetAnim;
  late Animation<double> _swipeTiltAnim;
  int _targetDelta = 0;

  @override
  void initState() {
    super.initState();
    _fanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fanAnimation = CurvedAnimation(
      parent: _fanAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _swipeOffsetAnim = const AlwaysStoppedAnimation(0.0);
    _swipeTiltAnim = const AlwaysStoppedAnimation(0.0);

    _swipeAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_targetDelta != 0 && widget.cards.isNotEmpty) {
          setState(() {
            _current = (_current + _targetDelta) % widget.cards.length;
            if (_current < 0) _current += widget.cards.length;
            _dragX = 0.0;
            _dragY = 0.0;
            _targetDelta = 0;
          });
        } else {
          setState(() {
            _dragX = 0.0;
            _dragY = 0.0;
          });
        }
        _swipeAnimController.reset();
      }
    });
  }

  @override
  void dispose() {
    _fanAnimController.dispose();
    _swipeAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WalletCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.isEmpty) {
      _current = 0;
    } else if (_current >= widget.cards.length) {
      _current = 0;
    }
  }

  void _move(int delta) {
    if (widget.cards.length < 2) return;
    if (_swipeAnimController.isAnimating) return;
    _triggerSwipe(delta, 0.0, delta * 500.0);
  }

  void _triggerSwipe(int delta, double startX, double velocity) {
    if (widget.cards.length < 2) {
      _snapBack(startX);
      return;
    }

    HapticFeedback.selectionClick();
    _targetDelta = delta;
    final screenW = MediaQuery.of(context).size.width;
    final endX = delta > 0 ? -screenW * 1.05 : screenW * 1.05;

    _swipeOffsetAnim = Tween<double>(begin: startX, end: endX).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutCubic),
    );
    _swipeTiltAnim = Tween<double>(begin: _dragY, end: 0.0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutCubic),
    );

    _swipeAnimController.forward(from: 0.0);
  }

  void _snapBack(double startX) {
    _targetDelta = 0;
    _swipeOffsetAnim = Tween<double>(begin: startX, end: 0.0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutBack),
    );
    _swipeTiltAnim = Tween<double>(begin: _dragY, end: 0.0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutBack),
    );

    _swipeAnimController.forward(from: 0.0);
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= widget.cards.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _current = index;
      _dragX = 0.0;
      _dragY = 0.0;
      if (_isFannedOut) {
        _isFannedOut = false;
        _fanAnimController.reverse();
      }
    });
  }

  void _toggleFan() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFannedOut = !_isFannedOut;
      if (_isFannedOut) {
        _fanAnimController.forward();
      } else {
        _fanAnimController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF64748B);

    final cardWidth = (screenWidth - 24.0).clamp(280.0, 440.0);
    final baseCardHeight = widget.cardHeight;

    if (count == 1) {
      return Center(
        child: SizedBox(
          width: cardWidth,
          child: widget.builder(context, widget.cards[0]),
        ),
      );
    }

    final visible = count.clamp(1, 4);
    final stackedHeight = baseCardHeight + 58.0;
    final cascadeHeight = (count - 1) * 68.0 + baseCardHeight + 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_fanAnimation, _swipeAnimController]),
          builder: (context, _) {
            final fanVal = _fanAnimation.value;
            final isSwiping = _swipeAnimController.isAnimating;
            final currentOffset = isSwiping ? _swipeOffsetAnim.value : _dragX;
            final currentTiltY = isSwiping ? _swipeTiltAnim.value : _dragY;
            final currentDeckHeight =
                ui.lerpDouble(stackedHeight, cascadeHeight, fanVal)!;

            // Generate card indices sorted for proper z-order
            final renderIndices = List.generate(count, (i) => i);
            renderIndices.sort((a, b) {
              final relA = (a - _current) % count;
              final relB = (b - _current) % count;
              return relB.compareTo(relA);
            });

            return SizedBox(
              width: cardWidth,
              height: currentDeckHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _isFannedOut
                    ? null
                    : (details) {
                        setState(() {
                          _dragX += details.delta.dx;
                          _dragY =
                              (_dragY + details.delta.dy).clamp(-40.0, 40.0);
                        });
                      },
                onHorizontalDragEnd: _isFannedOut
                    ? null
                    : (details) {
                        final velocity = details.primaryVelocity ?? 0.0;
                        if (_dragX < -45.0 || velocity < -350.0) {
                          _triggerSwipe(1, _dragX, velocity);
                        } else if (_dragX > 45.0 || velocity > 350.0) {
                          _triggerSwipe(-1, _dragX, velocity);
                        } else {
                          _snapBack(_dragX);
                        }
                      },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    for (final cardIndex in renderIndices)
                      _buildDeckCard(
                        context: context,
                        cardIndex: cardIndex,
                        count: count,
                        visible: visible,
                        cardWidth: cardWidth,
                        baseCardHeight: baseCardHeight,
                        fanVal: fanVal,
                        currentOffset: currentOffset,
                        currentTiltY: currentTiltY,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildFloatingControlBar(
          context: context,
          count: count,
          isDark: isDark,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildDeckCard({
    required BuildContext context,
    required int cardIndex,
    required int count,
    required int visible,
    required double cardWidth,
    required double baseCardHeight,
    required double fanVal,
    required double currentOffset,
    required double currentTiltY,
    required bool isDark,
  }) {
    final relDepth = (cardIndex - _current) % count;

    // Stack mode parameters
    final double stackedTop;
    final double stackedScale;
    final double stackedOpacity;
    final double stackedRotX;
    final double stackedRotY;
    final double stackedRotZ;
    final double stackedTransX;
    final double stackedTransZ;
    final double stackedDimAlpha;

    if (relDepth == 0) {
      // Front card
      final dragFraction = (currentOffset / cardWidth).clamp(-1.2, 1.2);
      stackedTop = 54.0 - (currentOffset.abs() * 0.03);
      stackedScale = 1.0;
      stackedOpacity = currentOffset.abs() > cardWidth * 0.45
          ? (1.0 -
                  (currentOffset.abs() - cardWidth * 0.45) / (cardWidth * 0.55))
              .clamp(0.0, 1.0)
          : 1.0;
      stackedRotX = -0.035 + (currentTiltY * 0.0003).clamp(-0.05, 0.05);
      stackedRotY = -dragFraction * 0.16;
      stackedRotZ = dragFraction * 0.12;
      stackedTransX = currentOffset;
      stackedTransZ = 0.0;
      stackedDimAlpha = 0.0;
    } else if (relDepth < visible) {
      // Visible rear cards
      stackedTop = 54.0 - (relDepth * 18.0);
      stackedScale = math.pow(0.942, relDepth).toDouble();
      stackedOpacity = 1.0;
      stackedRotX = -0.045 - (relDepth * 0.022);
      stackedRotY = 0.0;
      stackedRotZ = 0.0;
      stackedTransX = 0.0;
      stackedTransZ = -relDepth * 32.0;
      stackedDimAlpha = (0.12 * relDepth).clamp(0.0, 0.44);
    } else {
      // Hidden behind furthest card
      stackedTop = 54.0 - ((visible - 1) * 18.0);
      stackedScale = 0.82;
      stackedOpacity = 0.0;
      stackedRotX = -0.10;
      stackedRotY = 0.0;
      stackedRotZ = 0.0;
      stackedTransX = 0.0;
      stackedTransZ = -visible * 32.0;
      stackedDimAlpha = 0.55;
    }

    // Cascade mode parameters
    final double cascadeTop = cardIndex * 68.0 + 8.0;
    const double cascadeScale = 1.0;
    const double cascadeOpacity = 1.0;
    const double cascadeRotX = -0.025;
    const double cascadeRotY = 0.0;
    const double cascadeRotZ = 0.0;
    const double cascadeTransX = 0.0;
    const double cascadeTransZ = 0.0;
    final double cascadeDimAlpha = cardIndex == _current ? 0.0 : 0.08;

    // Interpolate with fanVal
    final top = ui.lerpDouble(stackedTop, cascadeTop, fanVal)!;
    final scale = ui.lerpDouble(stackedScale, cascadeScale, fanVal)!;
    final opacity =
        ui.lerpDouble(stackedOpacity, cascadeOpacity, fanVal)!.clamp(0.0, 1.0);
    final rotX = ui.lerpDouble(stackedRotX, cascadeRotX, fanVal)!;
    final rotY = ui.lerpDouble(stackedRotY, cascadeRotY, fanVal)!;
    final rotZ = ui.lerpDouble(stackedRotZ, cascadeRotZ, fanVal)!;
    final transX = ui.lerpDouble(stackedTransX, cascadeTransX, fanVal)!;
    final transZ = ui.lerpDouble(stackedTransZ, cascadeTransZ, fanVal)!;
    final dimAlpha = ui.lerpDouble(stackedDimAlpha, cascadeDimAlpha, fanVal)!;

    if (opacity <= 0.005) {
      return const SizedBox.shrink();
    }

    final card = widget.cards[cardIndex];
    final isTopCardInStack = !_isFannedOut && relDepth == 0;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..setTranslationRaw(transX, 0.0, transZ)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    return Positioned(
      top: top,
      width: cardWidth,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: matrix,
          child: Transform.scale(
            alignment: Alignment.topCenter,
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                    spreadRadius: -2,
                  ),
                  if (isTopCardInStack)
                    BoxShadow(
                      color: AppColors.accent
                          .withValues(alpha: isDark ? 0.14 : 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The card widget
                  IgnorePointer(
                    ignoring: !_isFannedOut && relDepth != 0,
                    child: widget.builder(context, card),
                  ),

                  // Ambient Occlusion / Darkening Overlay for rear cards
                  if (dimAlpha > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(
                                    alpha: (dimAlpha * 0.35).clamp(0.0, 0.9)),
                                Colors.black.withValues(
                                    alpha: dimAlpha.clamp(0.0, 0.9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Rear card tap detector to bring to front
                  if (!_isFannedOut && relDepth != 0)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _jumpTo(cardIndex),
                      ),
                    ),

                  // Cascade mode tap detector
                  if (_isFannedOut)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _jumpTo(cardIndex),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingControlBar({
    required BuildContext context,
    required int count,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final activeCard = widget.cards[_current];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 20,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: primaryTextColor,
                    tooltip: 'Thẻ trước',
                    onPressed: () => _move(-1),
                  ),
                  const SizedBox(width: 4),
                  // Dots
                  for (int i = 0; i < count; i++) ...[
                    GestureDetector(
                      onTap: () => _jumpTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        width: i == _current ? 22 : 6.5,
                        height: 6.5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.accent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.18)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  // Next button
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: 20,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: primaryTextColor,
                    tooltip: 'Thẻ kế tiếp',
                    onPressed: () => _move(1),
                  ),
                  Container(
                    height: 16,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.12),
                  ),
                  // Fan out toggle button
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _toggleFan,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFannedOut
                                ? Icons.layers_clear_rounded
                                : Icons.style_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isFannedOut ? 'Gom 3D' : 'Xòe thẻ',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Thẻ ${_current + 1}/$count: ${activeCard.name}',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (!_isFannedOut) ...[
              Text(
                '  •  Vuốt lật 3D',
                style: TextStyle(
                  color: secondaryTextColor.withValues(alpha: 0.65),
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _NormalWalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool isExpanded;

  const _NormalWalletCard({
    required this.wallet,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final gradient = studio?.getBankCardGradient(
          walletId: wallet.id,
          bankCode: wallet.bankCode,
          name: wallet.name,
          themeColor: wallet.themeColor,
        ) ??
        CreditCardPalette.gradient(
          wallet.themeColor,
          wallet.bankCode,
          wallet.name,
        );

    final cardRadius = studio?.cardCornerRadius ?? 22.0;
    final skin = studio?.resolveWalletCardSkinStyle(wallet.id) ??
        AppCardSkinStyle.brandClassic;

    final isCash = wallet.type == 'cash';
    final cardHolder = (wallet.owner == 'wife' ||
            wallet.ownerName.toLowerCase() == 'vợ' ||
            wallet.name.toLowerCase().contains('vợ'))
        ? 'VỢ'
        : 'CHỒNG';

    final dateLabel = (() {
      try {
        final d = DateTime.fromMillisecondsSinceEpoch(wallet.updatedAt);
        final hour = d.hour.toString().padLeft(2, '0');
        final min = d.minute.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        final month = d.month.toString().padLeft(2, '0');
        return '$hour:$min $day/$month';
      } catch (_) {
        return '';
      }
    })();

    final cleanAccount = wallet.accountNumber != null &&
            wallet.accountNumber!.length >= 4
        ? '•••• ${wallet.accountNumber!.substring(wallet.accountNumber!.length - 4)}'
        : (isCash ? 'TIỀN MẶT' : '•••• 8888');

    final bool isLightSurface = skin == AppCardSkinStyle.whiteCeramic ||
        skin == AppCardSkinStyle.titaniumFrost ||
        (!isDark &&
            (gradient.isEmpty ||
                ThemeData.estimateBrightnessForColor(gradient.first) ==
                    Brightness.light));
    final cardTextColor =
        isLightSurface ? const Color(0xFF0F172A) : Colors.white;
    final cardSubTextColor = isLightSurface
        ? const Color(0xFF475569)
        : Colors.white.withValues(alpha: 0.78);
    final cardBadgeBg = isLightSurface
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.22);
    final cardBadgeBorder = isLightSurface
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);

    return FinoraBankCardSurface(
      skin: skin,
      gradientColors: gradient,
      borderRadius: cardRadius,
      width: isExpanded ? double.infinity : 290,
      height: 172,
      bankCode: isCash ? null : wallet.bankCode,
      bankName: wallet.bankName ?? wallet.name,
      cardName: wallet.name,
      accountNumber: wallet.accountNumber,
      cardHolder: cardHolder,
      cardNetwork: isCash ? null : 'napas',
      isDark: isDark,
      preserveBankColors: studio?.preserveBankCardColors ?? true,
      onTap: onTap,
      topTrailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'edit') {
            onEdit();
          } else if (val == 'delete') {
            onDelete();
          }
        },
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: cardTextColor,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Xóa', style: TextStyle(fontSize: 13, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SỐ DƯ KHẢ DỤNG',
                      style: TextStyle(
                        color: cardSubTextColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FinoraAnimatedAmount(
                      amount: wallet.balance.toDouble(),
                      style: TextStyle(
                        color: cardTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cardBadgeBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  cleanAccount,
                  style: TextStyle(
                    color: cardTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cardHolder,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
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
}

class _CreditCardRow extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPay;

  const _CreditCardRow({
    required this.wallet,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final usedPercent = wallet.creditLimit > 0
        ? (wallet.currentDebt / wallet.creditLimit)
        : 0.0;
    final displayPercent = (usedPercent * 100).toStringAsFixed(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final gradient = studio?.getBankCardGradient(
          walletId: wallet.id,
          bankCode: wallet.bankCode,
          name: wallet.name,
          themeColor: wallet.themeColor,
        ) ??
        CreditCardPalette.gradient(
            wallet.themeColor, wallet.bankCode, wallet.name);

    final cardRadius = studio?.cardCornerRadius ?? 24.0;
    final skin = studio?.resolveWalletCardSkinStyle(wallet.id) ??
        AppCardSkinStyle.brandClassic;

    final bool isLightSurface = skin == AppCardSkinStyle.whiteCeramic ||
        skin == AppCardSkinStyle.titaniumFrost ||
        (!isDark &&
            (gradient.isEmpty ||
                ThemeData.estimateBrightnessForColor(gradient.first) ==
                    Brightness.light));
    final cardTextColor =
        isLightSurface ? const Color(0xFF0F172A) : Colors.white;
    final cardSubTextColor = isLightSurface
        ? const Color(0xFF475569)
        : Colors.white.withValues(alpha: 0.85);

    return FinoraBankCardSurface(
      skin: skin,
      gradientColors: gradient,
      borderRadius: cardRadius,
      height: 202,
      bankCode: wallet.bankCode,
      bankName: wallet.bankName ?? wallet.name,
      cardName: wallet.name,
      accountNumber: wallet.accountNumber,
      cardHolder: (wallet.owner == 'wife' ||
              wallet.ownerName.toLowerCase() == 'vợ' ||
              wallet.name.toLowerCase().contains('vợ'))
          ? 'VỢ'
          : 'CHỒNG',
      cardNetwork: 'visa',
      isDark: isDark,
      preserveBankColors: studio?.preserveBankCardColors ?? true,
      onTap: onTap,
      topTrailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'edit') {
            onEdit();
          } else if (val == 'delete') {
            onDelete();
          }
        },
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: cardTextColor,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Xóa', style: TextStyle(fontSize: 13, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hạn mức: ${formatVND(wallet.creditLimit)}',
                style: TextStyle(
                  color: cardSubTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Khả dụng: ${formatVND(wallet.creditLimit - wallet.currentDebt)}',
                style: TextStyle(
                  color: cardSubTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: usedPercent.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: isLightSurface
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                usedPercent > 0.85
                    ? const Color(0xFFF87171)
                    : (isLightSurface ? const Color(0xFF0F172A) : Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onPay,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLightSurface
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isLightSurface
                          ? Colors.black.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payment_rounded,
                          size: 12, color: cardTextColor),
                      const SizedBox(width: 4),
                      Text(
                        'Thanh toán thẻ',
                        style: TextStyle(
                          color: cardTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Đã dùng: $displayPercent%',
                        style: TextStyle(
                          color: cardSubTextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FinoraAnimatedAmount(
                        amount: wallet.currentDebt.toDouble(),
                        style: TextStyle(
                          color: cardTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Authentic VISA badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VISA',
                      style: TextStyle(
                        color: Color(0xFF1A1F71),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
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
}
