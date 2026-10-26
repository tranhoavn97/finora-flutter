import '../../core/design_system/credit_card_palette.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/wallet.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/wallet_provider.dart';
import '../transaction/transaction_history_sheet.dart';
import '../transaction/add_transaction_page.dart';
import 'add_wallet_page.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/design_system/v8/finora_v8_controls.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.88,
        child: GlassBottomSheet(
          radius: 30,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đối soát số dư',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900)),
                            SizedBox(height: 3),
                            Text('Số dư gốc + biến động = hiện tại',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final wallet = wallets[index];
                      var incoming = 0;
                      var outgoing = 0;
                      for (final tx in transactions) {
                        final single =
                            WalletRepository.computeWalletsWithBalances(
                                [wallet], [tx]).first;
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
                      final reconciled =
                          WalletRepository.computeWalletsWithBalances(
                                  [wallet], transactions)
                              .first;
                      final expected = wallet.isCreditCard
                          ? reconciled.currentDebt
                          : reconciled.balance;
                      final current = wallet.isCreditCard
                          ? wallet.currentDebt
                          : wallet.balance;
                      final difference = current - expected;
                      final matched = difference == 0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: matched
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.22)
                                : const Color(0xFFEF4444)
                                    .withValues(alpha: 0.32),
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
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
                                    matched
                                        ? 'Khớp'
                                        : 'Lệch ${formatVND(difference)}',
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
                                _AuditMetric(
                                    wallet.isCreditCard
                                        ? 'Giảm nợ'
                                        : 'Tiền vào',
                                    incoming,
                                    color: const Color(0xFF059669)),
                                _AuditMetric(
                                    wallet.isCreditCard ? 'Tăng nợ' : 'Tiền ra',
                                    outgoing,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context) {
    return FinoraSectionAddButton(
      onTap: _openAddWallet,
      label: 'Thêm',
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

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Ví & Tài khoản',
        onBack: (!widget.isRoot && Navigator.of(context).canPop())
            ? () => Navigator.of(context).pop()
            : null,
        actions: [
          FinoraHeaderIconButton(
            tooltip: 'Đối soát số dư',
            onTap: _showBalanceReconciliation,
            icon: Icons.fact_check_rounded,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          10,
          AppSpacing.xs,
          10,
          120,
        ),
        children: [
          // Net balance summary card: Sleek dark gradient card with emerald accents
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng số dư tài sản',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FinoraAnimatedAmount(
                  amount: (totalAssets - totalDebt).toDouble(),
                  style: AppTypography.largeTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng tiền mặt/Ngân hàng',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        FinoraAnimatedAmount(
                          amount: totalAssets.toDouble(),
                          style: AppTypography.footnote.copyWith(
                            color: const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Tổng nợ thẻ tín dụng',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        FinoraAnimatedAmount(
                          amount: totalDebt.toDouble(),
                          style: AppTypography.footnote.copyWith(
                            color: const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.account_balance_wallet,
                title: 'Chưa có ví tài khoản nào',
                subtitle: 'Hãy thêm ví đầu tiên để quản lý.',
                actionText: '+ Thêm ví',
                onAction: () => _openAddWallet(),
              ),
            )
          else ...[
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
                builder: (context, w) => _CreditCardRow(
                  wallet: w,
                  onDelete: () async {
                    final confirm = await showConfirmDeleteDialog(
                      context: context,
                      title: 'Xóa thẻ tín dụng?',
                      content:
                          'Bạn có chắc chắn muốn xóa thẻ "${w.name}" không?',
                    );
                    if (confirm && context.mounted) {
                      context.read<WalletProvider>().deleteWallet(
                            widget.userId,
                            w.id,
                          );
                    }
                  },
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
                ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < normalWallets.length; i++) ...[
                      FinoraStaggeredItem(
                        index: i,
                        child: _NormalWalletCard(
                          wallet: normalWallets[i],
                          onDelete: () async {
                            final confirm = await showConfirmDeleteDialog(
                              context: context,
                              title: 'Xóa ví / tài khoản?',
                              content:
                                  'Bạn có chắc chắn muốn xóa "${normalWallets[i].name}" không?',
                            );
                            if (confirm && context.mounted) {
                              context.read<WalletProvider>().deleteWallet(
                                    widget.userId,
                                    normalWallets[i].id,
                                  );
                            }
                          },
                          onTap: () => _showHistory(normalWallets[i]),
                          onEdit: () =>
                              _openAddWallet(wallet: normalWallets[i]),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WalletCardDeck extends StatefulWidget {
  final List<Wallet> cards;
  final Widget Function(BuildContext context, Wallet wallet) builder;

  const _WalletCardDeck({required this.cards, required this.builder});

  @override
  State<_WalletCardDeck> createState() => _WalletCardDeckState();
}

class _WalletCardDeckState extends State<_WalletCardDeck> {
  int _current = 0;
  double _drag = 0;

  @override
  void didUpdateWidget(covariant _WalletCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_current >= widget.cards.length) _current = 0;
  }

  void _move(int delta) {
    if (widget.cards.length < 2) return;
    setState(() {
      _current = (_current + delta) % widget.cards.length;
      if (_current < 0) _current += widget.cards.length;
      _drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width - 20;
    final visible = count.clamp(1, 3);

    return Column(
      children: [
        SizedBox(
          width: width,
          height: 224,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) =>
                setState(() => _drag += details.delta.dx),
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_drag < -42 || velocity < -450) {
                _move(1);
              } else if (_drag > 42 || velocity > 450) {
                _move(-1);
              } else {
                setState(() => _drag = 0);
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int depth = visible - 1; depth >= 0; depth--)
                  AnimatedPositioned(
                    key: ValueKey(
                      '${widget.cards[(_current + depth) % count].id}-$depth',
                    ),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: depth == 0 ? _drag.clamp(-width, width) : 6.0 * depth,
                    right:
                        depth == 0 ? -_drag.clamp(-width, width) : 6.0 * depth,
                    top: 12.0 * (visible - 1 - depth),
                    child: Transform.scale(
                      alignment: Alignment.topCenter,
                      scale: 1 - depth * .035,
                      child: SizedBox(
                        width: width,
                        child: IgnorePointer(
                          ignoring: depth != 0,
                          child: widget.builder(
                            context,
                            widget.cards[(_current + depth) % count],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (count > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              final selected = index == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent
                      : AppColors.accent.withOpacity(.18),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
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

  const _NormalWalletCard({
    required this.wallet,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isCash = wallet.type == 'cash';
    final label = isCash ? 'TIỀN MẶT' : 'TÀI KHOẢN';
    final hasBank = wallet.bankCode != null;

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

    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          width: 240,
          height: 115,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasBank || wallet.type == 'ewallet')
                    BankIcon(
                      bankCode: wallet.bankCode ?? wallet.type,
                      bankName: wallet.bankName ?? wallet.name,
                      size: 28,
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE0F2FE),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💵', style: TextStyle(fontSize: 14)),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                wallet.owner == 'wife' ||
                                        wallet.ownerName.toLowerCase() ==
                                            'vợ' ||
                                        wallet.name.toLowerCase().contains('vợ')
                                    ? 'Vợ'
                                    : 'Chồng',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        onEdit();
                      } else if (val == 'delete') {
                        onDelete();
                      }
                    },
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: primaryTextColor.withOpacity(0.5),
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
                            Text(
                              'Xóa',
                              style: TextStyle(fontSize: 13, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                            color: secondaryTextColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FinoraAnimatedAmount(
                          amount: wallet.balance.toDouble(),
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
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
    final gradient = CreditCardPalette.gradient(
        wallet.themeColor, wallet.bankCode, wallet.name);

    return Container(
      width: double.infinity,
      height: 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BankIcon(
                      bankCode: wallet.bankCode,
                      bankName: wallet.bankName ?? wallet.name,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'THẺ TÍN DỤNG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  wallet.owner == 'wife' ||
                                          wallet.ownerName.toLowerCase() ==
                                              'vợ' ||
                                          wallet.name
                                              .toLowerCase()
                                              .contains('vợ')
                                      ? 'Vợ'
                                      : 'Chồng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•• ${wallet.accountNumber != null && wallet.accountNumber!.length >= 4 ? wallet.accountNumber!.substring(wallet.accountNumber!.length - 4) : '1234'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        } else if (val == 'delete') {
                          onDelete();
                        }
                      },
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.white,
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
                              Text(
                                'Xóa',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1C40F).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFD4AC0D),
                              width: 1,
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF39C12), Color(0xFFF1C40F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color:
                                      const Color(0xFFD4AC0D).withOpacity(0.4),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color:
                                      const Color(0xFFD4AC0D).withOpacity(0.4),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 7,
                                child: Container(
                                  height: 1,
                                  color:
                                      const Color(0xFFD4AC0D).withOpacity(0.4),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 14,
                                child: Container(
                                  height: 1,
                                  color:
                                      const Color(0xFFD4AC0D).withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.rotate(
                          angle: 1.5708,
                          child: const Icon(
                            Icons.wifi,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -1.0,
                        ),
                        children: [
                          TextSpan(
                            text: 'V',
                            style: TextStyle(color: Color(0xFFF1C40F)),
                          ),
                          TextSpan(
                            text: 'ISA',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hạn mức: ${formatVND(wallet.creditLimit)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Khả dụng: ${formatVND(wallet.creditLimit - wallet.currentDebt)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: usedPercent.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPay,
                          borderRadius: BorderRadius.circular(15),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text(
                                'Thanh toán thẻ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Đã dùng: $displayPercent%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FinoraAnimatedAmount(
                          amount: wallet.currentDebt.toDouble(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
