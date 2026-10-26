import 'dart:async';
import 'dart:ui';

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
import '../../state/wallet_provider.dart';
import '../transaction/transaction_history_sheet.dart';
import '../transaction/add_transaction_page.dart';
import 'add_wallet_page.dart';

class WalletScreen extends StatefulWidget {
  final String userId;
  const WalletScreen({super.key, required this.userId});

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
      provider.load(widget.userId);
    });
    _eventsSub = provider.events.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAddWallet({Wallet? wallet}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddWalletPage(userId: widget.userId, wallet: wallet),
    ));
  }

  void _showHistory(Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: TransactionHistorySheet(
          userId: widget.userId,
          walletId: wallet.id,
          walletName: wallet.name,
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openAddWallet(),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: AppColors.accent),
                SizedBox(width: 4),
                Text(
                  'Thêm',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 120),
        children: [
          // Net balance summary card: Sleek dark gradient card with emerald accents
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                const Text('Tổng số dư tài sản',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(formatVND(totalAssets - totalDebt),
                    style: AppTypography.largeTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng tiền mặt/Ngân hàng',
                            style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(formatVND(totalAssets),
                            style: AppTypography.footnote.copyWith(
                                color: const Color(0xFF34D399),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tổng nợ thẻ tín dụng',
                            style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(formatVND(totalDebt),
                            style: AppTypography.footnote.copyWith(
                                color: const Color(0xFFF87171),
                                fontWeight: FontWeight.bold)),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final w in creditCards) ...[
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 48).clamp(280.0, 360.0),
                        child: _CreditCardRow(
                          wallet: w,
                          onDelete: () async {
                            final confirm = await showConfirmDeleteDialog(
                              context: context,
                              title: 'Xóa thẻ tín dụng?',
                              content: 'Bạn có chắc chắn muốn xóa thẻ "${w.name}" không?',
                            );
                            if (confirm && context.mounted) {
                              context.read<WalletProvider>().deleteWallet(widget.userId, w.id);
                            }
                          },
                          onTap: () => _showHistory(w),
                          onEdit: () => _openAddWallet(wallet: w),
                          onPay: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AddTransactionPage(
                                userId: widget.userId,
                                initialType: 'credit_card_payment',
                                initialWalletId: w.id,
                              ),
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ],
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
                    for (final w in normalWallets) ...[
                      _NormalWalletCard(
                        wallet: w,
                        onDelete: () async {
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa ví / tài khoản?',
                            content: 'Bạn có chắc chắn muốn xóa "${w.name}" không?',
                          );
                          if (confirm && context.mounted) {
                            context.read<WalletProvider>().deleteWallet(widget.userId, w.id);
                          }
                        },
                        onTap: () => _showHistory(w),
                        onEdit: () => _openAddWallet(wallet: w),
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
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                    BankIcon(bankCode: wallet.bankCode ?? wallet.type, size: 28)
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
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
                                wallet.ownerName,
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
                    icon: Icon(Icons.more_vert, size: 16, color: primaryTextColor.withOpacity(0.5)),
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
                        Text(
                          formatVND(wallet.balance),
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  List<Color> _gradientFor(String? theme) {
    switch (theme) {
      case 'purple':
        return const [Color(0xFF4C1D95), Color(0xFF3B0764)];
      case 'rose':
        return const [Color(0xFFB91C1C), Color(0xFF7F1D1D)];
      case 'emerald':
        return const [Color(0xFF059669), Color(0xFF064E3B)];
      case 'dark':
        return const [Color(0xFF1A1A1A), Color(0xFF111111)];
      default:
        return const [Color(0xFF0B3A82), Color(0xFF1E57A8)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedPercent = wallet.creditLimit > 0
        ? (wallet.currentDebt / wallet.creditLimit)
        : 0.0;
    final displayPercent = (usedPercent * 100).toStringAsFixed(1);
    final gradient = _gradientFor(wallet.themeColor);

    return Container(
      width: double.infinity,
      height: 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: BankIcon(bankCode: wallet.bankCode, size: 28),
                      ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  wallet.ownerName,
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
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
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
                            border: Border.all(color: const Color(0xFFD4AC0D), width: 1),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF39C12), Color(0xFFF1C40F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10, top: 0, bottom: 0,
                                child: Container(width: 1, color: const Color(0xFFD4AC0D).withOpacity(0.4)),
                              ),
                              Positioned(
                                left: 20, top: 0, bottom: 0,
                                child: Container(width: 1, color: const Color(0xFFD4AC0D).withOpacity(0.4)),
                              ),
                              Positioned(
                                left: 0, right: 0, top: 7,
                                child: Container(height: 1, color: const Color(0xFFD4AC0D).withOpacity(0.4)),
                              ),
                              Positioned(
                                left: 0, right: 0, top: 14,
                                child: Container(height: 1, color: const Color(0xFFD4AC0D).withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.rotate(
                          angle: 1.5708,
                          child: const Icon(Icons.wifi, color: Colors.white70, size: 14),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                        Text(
                          formatVND(wallet.currentDebt),
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
