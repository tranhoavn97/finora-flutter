import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/finora_summary_card.dart';
import 'web_wallet_card.dart';
import 'wallet_controls.dart';
import '../../domain/finance/transaction_member.dart';
import '../../core/widgets/ai_context_button.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../data/models/wallet.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/wallet_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../transaction/transaction_history_sheet.dart';
import '../transaction/add_transaction_page.dart';
import '../../state/transaction_provider.dart';
import 'add_wallet_page.dart';
import 'swipeable_bank_card_deck.dart';

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
  final bool isTab;
  final bool hideSummaryCard;
  const WalletScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.isRoot = false,
    this.isTab = false,
    this.hideSummaryCard = false,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  StreamSubscription<String>? _eventsSub;
  String _accountTab = 'all';
  String _ownerFilter = 'all';
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
      FinoraNotice.of(context)
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
      size: 48,
      onPressed: () => _openAddWallet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final provider = context.watch<WalletProvider>();
    final wallets = provider.wallets;
    if (!provider.hasLoadedBalances) {
      return GlassScaffold(
        appBar: const GlassTopBar(title: 'Ví & Tài khoản'),
        body: Center(
            child: provider.error == null
                ? const Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải ví và giao dịch…'),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Chưa tải đủ dữ liệu để tính số dư.'),
                    TextButton(
                        onPressed: () => provider.load(widget.userId,
                            familyId: widget.familyId, force: true),
                        child: const Text('Thử lại')),
                  ])),
      );
    }

    final totalAssets = wallets
        .where((w) => !w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.balance);
    final totalDebt = wallets
        .where((w) => w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.currentDebt);

    final filteredWallets = wallets.where((w) {
      if (_ownerFilter == 'husband') {
        return resolveWalletMember(w) == TransactionMember.husband;
      }
      if (_ownerFilter == 'wife') {
        return resolveWalletMember(w) == TransactionMember.wife;
      }
      return true;
    }).toList();

    final creditCards = filteredWallets.where((w) => w.isCreditCard).toList();
    final normalWallets =
        filteredWallets.where((w) => !w.isCreditCard).toList();

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardRadius = studio?.cardCornerRadius ?? 22.0;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: widget.isTab
          ? null
          : GlassTopBar(
              title: 'Ví & Tài khoản',
              actions: [
                AiContextButton(userId: widget.userId, screen: 'Ví tiền')
              ],
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
          if (!widget.hideSummaryCard)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  widget.isTab ? 8 : GlassScaffold.topInset(context, 8),
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
              child: Column(children: [
                if (provider.error != null)
                  Row(children: [
                    const Expanded(
                        child: Text(
                            'Số dư chưa cập nhật. Đang giữ dữ liệu lần tải trước.')),
                    TextButton(
                        onPressed: () => provider.load(widget.userId,
                            familyId: widget.familyId, force: true),
                        child: const Text('Thử lại')),
                  ]),
                _buildUnifiedToolbarRow(wallets, studio, isDark),
              ]),
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
    final walletGradient = isDark
        ? const [Color(0xFF071E3D), Color(0xFF0B3C68), Color(0xFF007AFF)]
        : const [Color(0xFF0A2540), Color(0xFF0D47A1), Color(0xFF007AFF)];
    return FinoraSummaryCard(
        title: 'TỔNG TÀI SẢN THANH KHOẢN',
        amount: totalAssets - totalDebt,
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF007AFF),
        gradientColors: walletGradient,
        masked: masked,
        subtitle: 'Tài sản ròng sau khi trừ dư nợ thẻ',
        badgeText: null,
        metricColors: const [Color(0xFF34C759), Color(0xFFFF453A)],
        metrics: [('Tiền khả dụng', totalAssets), ('Dư nợ thẻ', totalDebt)],
        actions: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: IconButton(
              tooltip: masked ? 'Hiện số dư' : 'Ẩn số dư',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => setState(() => _showBalances = !_showBalances),
              icon: Icon(
                masked
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Đối soát số dư',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _showBalanceReconciliation,
              icon: const Icon(
                Icons.published_with_changes_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ]));
  }

  Widget _buildViewModeSelector(ThemeStudioController? studio, bool isDark) {
    if (studio == null) return const SizedBox.shrink();
    final currentStyle =
        (studio.walletViewStyle == AppWalletViewStyle.verticalList ||
                studio.walletViewStyle == AppWalletViewStyle.gridBento)
            ? AppWalletViewStyle.webCards
            : studio.walletViewStyle;
    final primary = studio.resolvedPrimary;

    final options = [
      (AppWalletViewStyle.webCards, 'Thẻ ngân hàng', Icons.credit_card_rounded),
      (AppWalletViewStyle.stackedDeck, 'Xếp 3D', Icons.view_carousel_rounded),
      (
        AppWalletViewStyle.compactList,
        'Gọn',
        Icons.format_list_bulleted_rounded
      ),
    ];

    final currentOpt = options.firstWhere((option) => option.$1 == currentStyle,
        orElse: () => options.first);

    return PopupMenuButton<AppWalletViewStyle>(
      tooltip: 'Kiểu hiển thị: ${currentOpt.$2}',
      initialValue: currentStyle,
      onSelected: studio.setWalletViewStyle,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option.$1,
                child: Row(children: [
                  Icon(option.$3, size: 18, color: primary),
                  const SizedBox(width: 10),
                  Text(option.$2,
                      style: TextStyle(
                        fontWeight: currentStyle == option.$1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                  if (currentStyle == option.$1) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: primary, size: 18),
                  ],
                ]),
              ))
          .toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
            Icon(currentOpt.$3, size: 18, color: primary),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedToolbarRow(
    List<Wallet> wallets,
    ThemeStudioController? studio,
    bool isDark,
  ) {
    return WalletAdaptiveToolbar(
      tabs: _buildAccountTabs(wallets, studio, isDark),
      actions: [
        _buildOwnerSelector(wallets, isDark),
        _buildViewModeSelector(studio, isDark),
        _buildHeaderButton(context),
      ],
      ownerLabel: _ownerFilter == 'all'
          ? null
          : (_ownerFilter == 'husband' ? 'Chồng' : 'Vợ'),
      onClearOwner: () => setState(() => _ownerFilter = 'all'),
    );
  }

  Widget _buildOwnerSelector(List<Wallet> wallets, bool isDark) {
    final husbandCount = wallets
        .where((w) => resolveWalletMember(w) == TransactionMember.husband)
        .length;
    final wifeCount = wallets
        .where((w) => resolveWalletMember(w) == TransactionMember.wife)
        .length;

    final isHusband = _ownerFilter == 'husband';
    final isWife = _ownerFilter == 'wife';

    final Color activeColor = isHusband
        ? const Color(0xFF007AFF)
        : (isWife ? const Color(0xFFFF2D55) : const Color(0xFF007AFF));

    final IconData currentIcon = isHusband
        ? Icons.male_rounded
        : (isWife ? Icons.female_rounded : Icons.people_alt_rounded);

    final options = [
      (
        'all',
        'Tất cả (${wallets.length})',
        Icons.people_alt_rounded,
        const Color(0xFF007AFF)
      ),
      (
        'husband',
        'Chồng ($husbandCount)',
        Icons.male_rounded,
        const Color(0xFF007AFF)
      ),
      (
        'wife',
        'Vợ ($wifeCount)',
        Icons.female_rounded,
        const Color(0xFFFF2D55)
      ),
    ];

    return PopupMenuButton<String>(
      tooltip:
          'Thành viên: ${isHusband ? 'Chồng' : (isWife ? 'Vợ' : 'Tất cả')}',
      initialValue: _ownerFilter,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() => _ownerFilter = val);
      },
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option.$1,
                child: Row(children: [
                  Icon(option.$3, size: 18, color: option.$4),
                  const SizedBox(width: 10),
                  Text(
                    option.$2,
                    style: TextStyle(
                      fontWeight: _ownerFilter == option.$1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (_ownerFilter == option.$1) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: option.$4, size: 18),
                  ],
                ]),
              ))
          .toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: isDark ? 0.65 : 0.88),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: (_ownerFilter != 'all'
                    ? activeColor
                    : (isDark ? Colors.white : Colors.black))
                .withValues(alpha: _ownerFilter != 'all' ? 0.6 : 0.08),
            width: _ownerFilter != 'all' ? 1.4 : 0.8,
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
            Icon(currentIcon, size: 18, color: activeColor),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
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
    const values = ['all', 'credit', 'cash', 'bank'];
    return FinoraSegmentedTabs(
      labels: const ['Tất cả', 'Thẻ tín dụng', 'Ví tiền', 'Ngân hàng'],
      selectedIndex: values.indexOf(_accountTab),
      height: 38,
      onChanged: (index) => setState(() => _accountTab = values[index]),
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
    final rawStyle = studio?.walletViewStyle ?? AppWalletViewStyle.webCards;
    final style = (rawStyle == AppWalletViewStyle.verticalList ||
            rawStyle == AppWalletViewStyle.gridBento)
        ? AppWalletViewStyle.webCards
        : rawStyle;

    final allWallets = [...normalWallets, ...creditCards];

    switch (style) {
      case AppWalletViewStyle.webCards:
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            final txProv = context.watch<TransactionProvider?>();
            return SwipeableBankCardDeck(
              wallets: allWallets,
              transactions: txProv?.transactions ?? const [],
              userId: widget.userId,
              familyId: widget.familyId,
              isDark: isDark,
              isMasked:
                  !_showBalances || (studio?.isPrivacyShieldActive ?? false),
              onHistory: (w) => _showHistory(w),
              onEdit: (w) => _openAddWallet(wallet: w),
              onDelete: (w) => _deleteWallet(w),
              onPay: (w) => w.isCreditCard
                  ? Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddTransactionPage(
                          userId: widget.userId,
                          initialType: 'credit_card_payment',
                          initialWalletId: w.id,
                        ),
                      ),
                    )
                  : null,
              onAddTransaction: (w) => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionPage(
                    userId: widget.userId,
                    initialWalletId: w.id,
                  ),
                ),
              ),
              onAddWallet: () => _openAddWallet(),
            );
          }
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
          return Wrap(
              spacing: 14,
              runSpacing: 10,
              children: allWallets
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

      case AppWalletViewStyle.stackedDeck:
        return WalletCardDeck(
          cards: allWallets,
          cardHeight: 204.0,
          builder: (context, w) => WebWalletCard(
            wallet: w,
            aspectRatio: 1.72,
            masked: !_showBalances || (studio?.isPrivacyShieldActive ?? false),
            onHistory: () => _showHistory(w),
            onEdit: () => _openAddWallet(wallet: w),
            onDelete: () => _deleteWallet(w),
            onPay: w.isCreditCard
                ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AddTransactionPage(
                        userId: widget.userId,
                        initialType: 'credit_card_payment',
                        initialWalletId: w.id)))
                : null,
          ),
        );

      case AppWalletViewStyle.compactList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in allWallets)
              _buildCompactWalletRow(
                  w, isDark, primaryTextColor, secondaryTextColor),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  ({
    List<Color> gradient,
    Color borderColor,
    Color brandAccent,
    Color badgeBg,
  }) _getBankCompactColors(Wallet w, bool isDark) {
    final brand =
        BankIconRegistry.resolve(w.bankCode, bankName: w.bankName ?? w.name);
    final cash = w.type == 'cash';
    final name = w.name.toLowerCase();
    var skin = (w.themeColor ?? '').toLowerCase();
    if (skin.isEmpty) {
      if (RegExp('gold|vàng').hasMatch(name)) {
        skin = 'gold';
      } else if (RegExp('silver|sliver|bạc|platinum').hasMatch(name)) {
        skin = 'silver';
      } else if (['mbbank', 'bidv', 'acb', 'vtb'].contains(brand.code)) {
        skin = 'blue';
      } else if (['vcb', 'vpb'].contains(brand.code)) {
        skin = 'emerald';
      } else if (['tcb', 'cake', 'hdb'].contains(brand.code)) {
        skin = 'rose';
      } else if (['tpb', 'timo'].contains(brand.code)) {
        skin = 'purple';
      }
    }

    if (cash) {
      return (
        gradient: isDark
            ? [const Color(0xFF04241A), const Color(0xFF021710)]
            : [const Color(0xFFE8FDF3), const Color(0xFFD1FAE5)],
        borderColor:
            const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.45),
        brandAccent: const Color(0xFF10B981),
        badgeBg: isDark ? const Color(0xFF053526) : Colors.white,
      );
    }

    switch (skin) {
      case 'rose':
        return (
          gradient: isDark
              ? [const Color(0xFF330B14), const Color(0xFF20050B)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
          borderColor:
              const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.38 : 0.45),
          brandAccent: const Color(0xFFE11D48),
          badgeBg: isDark ? const Color(0xFF450A17) : Colors.white,
        );
      case 'blue':
        return (
          gradient: isDark
              ? [const Color(0xFF082245), const Color(0xFF04142B)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          borderColor:
              const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.38 : 0.45),
          brandAccent: const Color(0xFF2563EB),
          badgeBg: isDark ? const Color(0xFF0D3261) : Colors.white,
        );
      case 'emerald':
        return (
          gradient: isDark
              ? [const Color(0xFF052B1E), const Color(0xFF021A11)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          borderColor:
              const Color(0xFF10B981).withValues(alpha: isDark ? 0.38 : 0.45),
          brandAccent: const Color(0xFF059669),
          badgeBg: isDark ? const Color(0xFF063A27) : Colors.white,
        );
      case 'purple':
        return (
          gradient: isDark
              ? [const Color(0xFF280C42), const Color(0xFF170526)]
              : [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
          borderColor:
              const Color(0xFFA855F7).withValues(alpha: isDark ? 0.38 : 0.45),
          brandAccent: const Color(0xFF9333EA),
          badgeBg: isDark ? const Color(0xFF37105B) : Colors.white,
        );
      case 'gold':
        return (
          gradient: isDark
              ? [const Color(0xFF332306), const Color(0xFF211603)]
              : [const Color(0xFFFEFCE8), const Color(0xFFFEF08A)],
          borderColor:
              const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.40 : 0.50),
          brandAccent: const Color(0xFFD97706),
          badgeBg: isDark ? const Color(0xFF453009) : Colors.white,
        );
      case 'silver':
        return (
          gradient: isDark
              ? [const Color(0xFF1E2633), const Color(0xFF131922)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          borderColor:
              const Color(0xFF94A3B8).withValues(alpha: isDark ? 0.35 : 0.45),
          brandAccent: const Color(0xFF64748B),
          badgeBg: isDark ? const Color(0xFF273142) : Colors.white,
        );
      default:
        if (['tcb', 'cake', 'hdb'].contains(brand.code)) {
          return (
            gradient: isDark
                ? [const Color(0xFF330B14), const Color(0xFF20050B)]
                : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
            borderColor:
                const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.38 : 0.45),
            brandAccent: const Color(0xFFE11D48),
            badgeBg: isDark ? const Color(0xFF450A17) : Colors.white,
          );
        }
        if (['vtb', 'mbbank', 'bidv', 'acb'].contains(brand.code)) {
          return (
            gradient: isDark
                ? [const Color(0xFF082245), const Color(0xFF04142B)]
                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
            borderColor:
                const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.38 : 0.45),
            brandAccent: const Color(0xFF2563EB),
            badgeBg: isDark ? const Color(0xFF0D3261) : Colors.white,
          );
        }
        return (
          gradient: isDark
              ? [const Color(0xFF1B2332), const Color(0xFF0F1520)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
          borderColor:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
          brandAccent: const Color(0xFF007AFF),
          badgeBg: isDark ? const Color(0xFF222C3D) : Colors.white,
        );
    }
  }

  Widget _buildCompactWalletRow(
    Wallet w,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final masked = (studio?.isPrivacyShieldActive ?? false) || !_showBalances;
    final isCredit = w.isCreditCard;
    final amount = isCredit ? w.currentDebt : w.balance;
    final bankTheme = _getBankCompactColors(w, isDark);

    final limit = w.creditLimit;
    final debt = w.currentDebt;
    final available = math.max(0, limit - debt);

    final stacked = MediaQuery.sizeOf(context).width < 420 ||
        MediaQuery.textScalerOf(context).scale(12) > 16;
    final amountWidget = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: isCredit
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        masked ? '•••••• ₫' : formatVND(available),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'còn lại',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    masked
                        ? 'Nợ: ••••'
                        : 'Nợ: ${formatVND(debt)}${limit > 0 ? ' / ${formatVND(limit)}' : ''}',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    masked ? '•••••• ₫' : formatVND(amount),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Khả dụng',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showHistory(w);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bankTheme.gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: bankTheme.borderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Full round bank icon with surrounding ring border (no squircle)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bankTheme.badgeBg,
                  border: Border.all(
                    color: bankTheme.brandAccent
                        .withValues(alpha: isDark ? 0.65 : 0.45),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bankTheme.brandAccent
                          .withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: BankIcon(
                      bankCode: w.bankCode ?? w.type,
                      bankName: w.bankName ?? w.name,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Account Name & Metadata chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: bankTheme.brandAccent
                                .withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCredit
                                ? 'Tín dụng'
                                : (w.type == 'cash' ? 'Tiền mặt' : 'Ngân hàng'),
                            style: TextStyle(
                              color: bankTheme.brandAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SpenderBadgeWidget(
                          member: resolveWalletMember(w),
                          tag: w.owner,
                          ownerName: w.ownerName,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    if (stacked) ...[
                      const SizedBox(height: 6),
                      amountWidget,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Balance / Credit Card amounts
              if (!stacked) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 112),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1.0,
                    child: amountWidget,
                  ),
                ),
              ],
              // Compact 3-dot button pushed to far right edge
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    _openAddWallet(wallet: w);
                  } else if (val == 'delete') {
                    _deleteWallet(w);
                  }
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 36),
                splashRadius: 18,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa',
                            style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class WalletCardDeck extends StatefulWidget {
  final List<Wallet> cards;
  final Widget Function(BuildContext context, Wallet wallet) builder;
  final double cardHeight;

  const WalletCardDeck({
    super.key,
    required this.cards,
    required this.builder,
    this.cardHeight = 204.0,
  });

  @override
  State<WalletCardDeck> createState() => WalletCardDeckState();
}

class WalletCardDeckState extends State<WalletCardDeck>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  double _drag = 0.0;
  late final AnimationController _animController;
  Animation<double>? _dragAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_dragAnimation != null) {
          setState(() {
            _drag = _dragAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WalletCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.cards.length != widget.cards.length ||
        List.generate(oldWidget.cards.length,
            (i) => oldWidget.cards[i].id != widget.cards[i].id).any((v) => v);
    if (changed) {
      final oldId = oldWidget.cards.isEmpty
          ? null
          : oldWidget.cards[_current.clamp(0, oldWidget.cards.length - 1)].id;
      _animController.stop();
      _dragAnimation = null;
      _animController.reset();
      _drag = 0.0;
      final index = widget.cards.indexWhere((card) => card.id == oldId);
      _current = index < 0 ? 0 : index;
    }
    if (widget.cards.isEmpty) {
      _current = 0;
      _drag = 0.0;
    } else if (_current >= widget.cards.length) {
      _current = 0;
      _drag = 0.0;
    }
  }

  void _move(int delta) {
    if (widget.cards.length < 2) return;
    setState(() {
      _current = (_current + delta) % widget.cards.length;
      if (_current < 0) _current += widget.cards.length;
      _drag = 0.0;
    });
    _animController.reset();
  }

  void _animateSnapBack() {
    _dragAnimation = Tween<double>(begin: _drag, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0).then((_) {
      _drag = 0.0;
      _animController.reset();
    });
  }

  void _animateFling(double target, int delta) {
    HapticFeedback.selectionClick();
    _dragAnimation = Tween<double>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );
    _animController.forward(from: 0.0).then((_) {
      _move(delta);
    });
  }

  void _animateToDelta(int delta) {
    if (widget.cards.length < 2 || delta == 0) return;
    if (_animController.isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final target = delta > 0 ? -screenWidth * 0.9 : screenWidth * 0.9;
    _animateFling(target, delta);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = math.min(count, 3);
    const double stepOffset = 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(constraints.maxWidth, 400.0);
        // Aspect ratio of the card is 1.72
        final computedCardHeight = math.max(
            cardWidth / 1.72,
            WebWalletCard.minimumHeight(context,
                credit: widget.cards.any((card) => card.isCreditCard)));
        final stackHeight = computedCardHeight +
            (visible > 1 ? (visible - 1) * stepOffset : 0.0);

        final dragProgress = (_drag.abs() / (cardWidth * 0.45)).clamp(0.0, 1.0);

        return Center(
          child: SizedBox(
            width: cardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    if (_animController.isAnimating) {
                      _animController.stop();
                      _animController.reset();
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (count < 2) return;
                    setState(() => _drag += details.delta.dx);
                  },
                  onHorizontalDragEnd: (details) {
                    if (count < 2) return;
                    final velocity = details.primaryVelocity ?? 0.0;
                    if (_drag < -45.0 || velocity < -400.0) {
                      _animateFling(-cardWidth * 1.05, 1);
                    } else if (_drag > 45.0 || velocity > 400.0) {
                      _animateFling(cardWidth * 1.05, -1);
                    } else {
                      _animateSnapBack();
                    }
                  },
                  onHorizontalDragCancel: () {
                    if (_drag != 0.0) _animateSnapBack();
                  },
                  child: SizedBox(
                    width: cardWidth,
                    height: stackHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int depth = visible - 1; depth >= 0; depth--)
                          _buildCardLayer(
                            depth: depth,
                            visible: visible,
                            count: count,
                            stepOffset: stepOffset,
                            cardWidth: cardWidth,
                            computedCardHeight: computedCardHeight,
                            dragProgress: dragProgress,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
                ),
                if (count > 1) _buildIndicatorRow(count, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardLayer({
    required int depth,
    required int visible,
    required int count,
    required double stepOffset,
    required double cardWidth,
    required double computedCardHeight,
    required double dragProgress,
    required bool isDark,
  }) {
    final index = (_current + depth) % count;
    final card = widget.cards[index];

    if (depth == 0) {
      // Front active card
      final top = (visible - 1) * stepOffset;
      final dragFactor = (_drag / cardWidth).clamp(-1.0, 1.0);
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateZ(dragFactor * 0.09)
        ..rotateY(-dragFactor * 0.16);

      final opacity =
          (1.0 - (_drag.abs() / (cardWidth * 1.2))).clamp(0.25, 1.0);

      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: computedCardHeight,
        child: Transform.translate(
          offset: Offset(_drag, 0),
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: widget.builder(context, card),
              ),
            ),
          ),
        ),
      );
    }

    // Background cards in 3D stack (depth 1, depth 2)
    final baseTop = (visible - 1 - depth) * stepOffset;
    final animatedTop = baseTop + (stepOffset * dragProgress);

    final baseScale = 1.0 - (depth * 0.05);
    final animatedScale = baseScale + (0.05 * dragProgress);

    final baseOpacity = 1.0 - (depth * 0.14);
    final animatedOpacity =
        (baseOpacity + (0.14 * dragProgress)).clamp(0.0, 1.0);

    final overlayDarkness =
        (0.18 * depth * (1.0 - 0.5 * dragProgress)).clamp(0.0, 0.5);

    return Positioned(
      top: animatedTop,
      left: 0,
      right: 0,
      height: computedCardHeight,
      child: Transform.scale(
        scale: animatedScale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: animatedOpacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _animateToDelta(depth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  widget.builder(context, card),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.black.withValues(alpha: overlayDarkness),
                      ),
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

  Widget _buildIndicatorRow(int count, bool isDark) => WalletDeckIndicator(
        count: count,
        current: _current,
        onSelect: (index) => _animateToDelta(index - _current),
      );
}
