import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/app_shadows.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../../state/budget_provider.dart' show BudgetSpentData;
import '../budget/budget_screen.dart';
import '../loan/loan_screen.dart';
import '../notification/notification_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_history_sheet.dart';
import '../wallet/wallet_screen.dart';
import '../ai/ai_advisor_screen.dart';

/// Dashboard ("Tổng quan") — premium liquid glass home screen.
class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.onViewAllTransactions,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load(widget.userId);
    });
  }

  void _push(Widget screen, {bool fullscreenDialog = false}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: fullscreenDialog,
      builder: (_) => screen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final c = context.fc;
    final data = provider.data;

    return Scaffold(
      key: const ValueKey('dashboard_scaffold'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: _buildBody(context, provider, data, c),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DashboardProvider provider,
    DashboardData data,
    FinoraColors c,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isEmpty = data.recentTransactions.isEmpty &&
        data.wallets.isEmpty &&
        data.totalWalletBalance == 0;

    if (provider.isLoading && isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không thể tải dữ liệu',
                textAlign: TextAlign.center,
                style: AppTypography.title3.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Vui lòng kiểm tra kết nối mạng.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 140,
                child: GradientButton(
                  onPressed: () =>
                      context.read<DashboardProvider>().load(widget.userId),
                  radius: AppRadius.sm,
                  colors: const [AppColors.accent, AppColors.accentLight],
                  child: Text(
                    'Thử lại',
                    style: AppTypography.buttonLabel.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final netAssets = data.netWorth > 0 || (data.totalAssets - data.totalDebts) != 0
        ? data.netWorth
        : (data.totalWalletBalance +
            data.totalAssetsValue +
            data.totalLent -
            data.totalCreditCardDebt -
            data.totalBorrowed);

    final firstName = widget.userName.trim().isEmpty
        ? widget.userName
        : widget.userName.trim().split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, 120),
      children: [
        _Header(
          firstName: firstName,
          photoUrl: widget.userPhotoUrl,
          onNotifications: () =>
              _push(NotificationScreen(userId: widget.userId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _HeroBalanceCard(
          data: data,
          netAssets: netAssets,
          showBalance: _showBalance,
          onToggleBalance: () => setState(() => _showBalance = !_showBalance),
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickActionsRow(
          onAdd: () => _push(
            AddTransactionPage(userId: widget.userId),
            fullscreenDialog: true,
          ),
          onTransfer: () => _push(
            AddTransactionPage(userId: widget.userId, initialType: 'transfer'),
            fullscreenDialog: true,
          ),
          onAi: () => _push(
            AiAdvisorScreen(userId: widget.userId),
          ),
          onBudget: () => _push(
            BudgetScreen(userId: widget.userId),
          ),
          onWallet: () => _push(WalletScreen(userId: widget.userId)),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Horizontal list of wallets
        if (data.wallets.isNotEmpty) ...[
          const _DashboardSectionHeader(title: 'Ví & Tài khoản'),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 102,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.wallets.length,
              itemBuilder: (context, idx) {
                return _WalletCardItem(
                  wallet: data.wallets[idx],
                  userId: widget.userId,
                  allTransactions: data.allTransactions,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Sức khỏe tài chính AI
        _AiHealthCard(
          metrics: data.aiMetrics,
          onConsultAi: () => _push(AiAdvisorScreen(userId: widget.userId)),
        ),
        const SizedBox(height: AppSpacing.md),

        // Widget Ngân sách chi tiêu
        _BudgetOverviewCard(
          budgets: data.budgetsWithSpent,
          userId: widget.userId,
          onManage: () => _push(BudgetScreen(userId: widget.userId)),
        ),
        const SizedBox(height: AppSpacing.md),

        // Khoản vay & Cho vay
        if (data.totalLent > 0 || data.totalBorrowed > 0 || data.activeLoans.isNotEmpty) ...[
          _LoansOverviewCard(
            data: data,
            onManage: () => _push(LoanScreen(userId: widget.userId)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Dòng tiền tháng này (Cashflow)
        _CashFlowCard(data: data, userId: widget.userId),
        const SizedBox(height: AppSpacing.md),

        // Giao dịch gần đây
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giao dịch gần đây',
              style: AppTypography.title3.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAllTransactions ?? () {},
              child: Text(
                'Xem tất cả',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _RecentTransactionsCard(
          transactions: data.recentTransactions.take(5).toList(),
        ),
      ],
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  final String title;
  const _DashboardSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Text(
      title,
      style: AppTypography.title3.copyWith(
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final VoidCallback onNotifications;
  const _Header({required this.firstName, this.photoUrl, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, AppSpacing.xxs),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, $firstName 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hôm nay tài chính thế nào?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption2.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // Glass notification button with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                _GlassCircleButton(
                  icon: Icons.notifications_outlined,
                  tint: primaryTextColor,
                  onTap: onNotifications,
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            // User profile avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                      style: AppTypography.caption1.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  final DashboardData data;
  final int netAssets;
  final bool showBalance;
  final VoidCallback onToggleBalance;

  const _HeroBalanceCard({
    required this.data,
    required this.netAssets,
    required this.showBalance,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate month-over-month expense diff
    double? expenseDiffPercent;
    bool isExpenseIncreased = false;
    if (data.previousMonthExpenses > 0) {
      expenseDiffPercent = ((data.currentMonthExpenses - data.previousMonthExpenses) /
              data.previousMonthExpenses) *
          100;
      isExpenseIncreased = expenseDiffPercent > 0;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(isDark ? 0.85 : 1.0),
            AppColors.accentLight.withOpacity(isDark ? 0.65 : 1.0),
          ],
        ),
        boxShadow: isDark ? null : AppShadows.glowingActiveShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tài sản ròng',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleBalance,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            showBalance ? 'Ẩn' : 'Hiện',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                showBalance ? formatVND(netAssets) : '•••••••• ₫',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.largeTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: showBalance ? -0.5 : 2.0,
                ),
              ),
              if (expenseDiffPercent != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpenseIncreased ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: isExpenseIncreased ? const Color(0xFFFFC2CC) : const Color(0xFFB7F4D8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isExpenseIncreased ? '+' : ''}${expenseDiffPercent.toStringAsFixed(1)}% chi tiêu so với tháng trước',
                        style: TextStyle(
                          color: isExpenseIncreased ? const Color(0xFFFFC2CC) : const Color(0xFFB7F4D8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _SubBalanceCard(
                      title: 'Tiền mặt',
                      value: showBalance ? formatVND(data.totalWalletBalance) : '•••••• ₫',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _SubBalanceCard(
                      title: 'Đầu tư',
                      value: showBalance ? formatVND(data.totalAssetsValue) : '•••••• ₫',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _SubBalanceCard(
                      title: 'Dư nợ',
                      value: showBalance ? formatVND(data.totalDebts) : '•••••• ₫',
                      valueColor: const Color(0xFFFFC2CC),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _SubBalanceCard(
                      title: 'Cho vay',
                      value: showBalance ? formatVND(data.totalLent) : '•••••• ₫',
                      valueColor: const Color(0xFFFFE0A3),
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
}

class _SubBalanceCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  const _SubBalanceCard({
    required this.title,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: AppRadius.radiusSM,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.footnote.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onTransfer;
  final VoidCallback onAi;
  final VoidCallback onBudget;
  final VoidCallback onWallet;

  const _QuickActionsRow({
    required this.onAdd,
    required this.onTransfer,
    required this.onAi,
    required this.onBudget,
    required this.onWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickAction(icon: Icons.add, label: 'Giao dịch', onTap: onAdd, color: AppColors.accent),
          _QuickAction(icon: Icons.swap_horiz, label: 'Chuyển', onTap: onTransfer, color: AppColors.accent),
          _QuickAction(icon: Icons.auto_awesome, label: 'Gemini AI', onTap: onAi, color: AppColors.accent, isSpecial: true),
          _QuickAction(icon: Icons.savings_outlined, label: 'Ngân sách', onTap: onBudget, color: AppColors.accent),
          _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Ví tiền', onTap: onWallet, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isSpecial;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassCircleButton(
            icon: icon,
            tint: isSpecial ? Colors.white : color,
            size: 50,
            onTap: onTap,
            isSpecial: isSpecial,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption2.copyWith(
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final double size;
  final VoidCallback onTap;
  final bool isSpecial;

  const _GlassCircleButton({
    required this.icon,
    required this.tint,
    required this.onTap,
    this.size = 44,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSpecial 
                ? const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight], // Brand gradient
                  )
                : null,
            color: isSpecial 
                ? null 
                : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
            border: Border.all(
              color: isSpecial 
                  ? Colors.white.withOpacity(0.2) 
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1.2,
            ),
            boxShadow: isSpecial
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: tint, size: size * 0.46),
        ),
      ),
    );
  }
}

class _WalletCardItem extends StatelessWidget {
  final Wallet wallet;
  final String userId;
  final List<TransactionModel> allTransactions;

  const _WalletCardItem({
    required this.wallet,
    required this.userId,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    
    // Calculate sparkline data
    final history = _getBalanceHistory(wallet, allTransactions);
    final sparkColor = _getSparklineColor(history);

    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.85,
              child: TransactionHistorySheet(
                userId: userId,
                walletId: wallet.id,
                walletName: wallet.name,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (wallet.type == 'bank' && wallet.bankCode != null)
                  BankIconAvatar(bankCode: wallet.bankCode, size: 22)
                else
                  Icon(
                    wallet.type == 'credit_card' ? Icons.credit_card : Icons.account_balance_wallet,
                    size: 16,
                    color: AppColors.accent,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SparklinePainter(history, sparkColor),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatVND(wallet.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

List<double> _getBalanceHistory(Wallet wallet, List<TransactionModel> allTxs) {
  final wTxs = allTxs.where((t) {
    return t.walletId == wallet.id ||
        t.fromWalletId == wallet.id ||
        t.toWalletId == wallet.id ||
        t.creditCardId == wallet.id;
  }).toList();

  wTxs.sort((a, b) => b.date.compareTo(a.date));

  final List<double> history = [];
  double current = wallet.balance.toDouble();
  history.add(current);

  final limit = wTxs.length > 8 ? 8 : wTxs.length;

  for (int i = 0; i < limit; i++) {
    final tx = wTxs[i];
    final amount = tx.amount.toDouble();

    if (tx.type == 'transfer') {
      if (tx.fromWalletId == wallet.id) {
        current += amount;
      } else if (tx.toWalletId == wallet.id) {
        current -= amount;
      }
    } else if (tx.type == 'credit_card_payment') {
      if (tx.fromWalletId == wallet.id) {
        current += amount;
      } else if (tx.toWalletId == wallet.id || tx.creditCardId == wallet.id) {
        current -= amount;
      }
    } else {
      final isIncome = {'income', 'borrowing', 'loan_repayment_received'}.contains(tx.type);
      if (isIncome) {
        current -= amount;
      } else {
        current += amount;
      }
    }
    history.add(current);
  }

  if (history.length < 2) {
    history.add(wallet.balance.toDouble());
  }

  return history.reversed.toList();
}

Color _getSparklineColor(List<double> history) {
  if (history.length < 2) return AppColors.accent;
  final first = history.first;
  final last = history.last;
  if (last > first) {
    return const Color(0xFF34D399);
  } else if (last < first) {
    return const Color(0xFFF87171);
  } else {
    return AppColors.accent.withOpacity(0.5);
  }
}

class _AiHealthCard extends StatelessWidget {
  final AiFinancialMetrics metrics;
  final VoidCallback onConsultAi;

  const _AiHealthCard({
    required this.metrics,
    required this.onConsultAi,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Color badgeColor;
    Color badgeBg;
    if (metrics.healthScore >= 85) {
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFD1FAE5);
    } else if (metrics.healthScore >= 70) {
      badgeColor = const Color(0xFF0284C7);
      badgeBg = const Color(0xFFE0F2FE);
    } else if (metrics.healthScore >= 50) {
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    } else {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
    }

    return GlassCard(
      onTap: onConsultAi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Sức khỏe tài chính AI',
                    style: AppTypography.subhead.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${metrics.healthScore}/100',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${metrics.healthTier}',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 3 key financial metrics row
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Dự phòng',
                  value: '${metrics.runwayMonths} tháng',
                  subtitle: metrics.runwayMonths >= 6 ? 'Rất an toàn' : (metrics.runwayMonths >= 3 ? 'Khá ổn' : 'Cần tăng'),
                  color: metrics.runwayMonths >= 3 ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MetricPill(
                  label: 'Tiết kiệm',
                  value: '${metrics.savingsRate}%',
                  subtitle: metrics.savingsRate >= 20 ? 'Chuẩn 50/30/20' : 'Dưới mức 20%',
                  color: metrics.savingsRate >= 20 ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MetricPill(
                  label: 'Tỷ lệ nợ',
                  value: '${metrics.debtToIncomeRatio}%',
                  subtitle: metrics.debtToIncomeRatio <= 30 ? 'An toàn' : 'Cần giảm nợ',
                  color: metrics.debtToIncomeRatio <= 30 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 50/30/20 rule breakdown mini bar
          Text(
            'Phân bổ chi tiêu (Mục tiêu 50 / 30 / 20)',
            style: AppTypography.caption2.copyWith(
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: metrics.needsPercent.clamp(1, 100),
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: metrics.wantsPercent.clamp(1, 100),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: metrics.savingsPercent.clamp(1, 100),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(color: const Color(0xFF3B82F6), label: 'Thiết yếu: ${metrics.needsPercent}%'),
              _LegendItem(color: const Color(0xFFF59E0B), label: 'Linh hoạt: ${metrics.wantsPercent}%'),
              _LegendItem(color: const Color(0xFF10B981), label: 'Tiết kiệm: ${metrics.savingsPercent}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption2.copyWith(color: secondaryTextColor, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.footnote.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryTextColor, fontSize: 9)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  final List<BudgetSpentData> budgets;
  final String userId;
  final VoidCallback onManage;

  const _BudgetOverviewCard({
    required this.budgets,
    required this.userId,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (budgets.isEmpty) {
      return GlassCard(
        onTap: onManage,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_outlined, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chưa có ngân sách tháng này',
                      style: AppTypography.subhead.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tạo hạn mức chi tiêu để AI cảnh báo kịp thời',
                      style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      );
    }

    final totalLimit = budgets.fold<int>(0, (s, b) => s + b.budget.limitAmount);
    final totalSpent = budgets.fold<int>(0, (s, b) => s + b.spentAmount);
    final overallProgress = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final isOver = totalLimit > 0 && totalSpent > totalLimit;

    Color progressColor;
    if (overallProgress > 0.9) {
      progressColor = const Color(0xFFF87171);
    } else if (overallProgress > 0.7) {
      progressColor = const Color(0xFFFBBF24);
    } else {
      progressColor = const Color(0xFF34D399);
    }

    final sorted = [...budgets]..sort((a, b) => b.progress.compareTo(a.progress));
    final displayBudgets = sorted.take(3).toList();

    return GlassCard(
      onTap: onManage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ngân sách chi tiêu',
                    style: AppTypography.subhead.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDEF7EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOver ? 'Vượt hạn mức' : 'Đang an toàn',
                  style: TextStyle(
                    color: isOver ? const Color(0xFFB91C1C) : const Color(0xFF03543F),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi ${formatVND(totalSpent)}',
                style: AppTypography.footnote.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              Text(
                'Mục tiêu ${formatVND(totalLimit)}',
                style: AppTypography.caption2.copyWith(color: secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: progressColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: AppSpacing.xs),
          for (final item in displayBudgets) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      CategoryIconHelper.resolveIcon(item.budget.categoryIcon ?? item.budget.categoryName),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.budget.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${formatVND(item.spentAmount)} / ${formatVND(item.budget.limitAmount)}',
                    style: AppTypography.caption2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.spentAmount > item.budget.limitAmount ? AppColors.error : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoansOverviewCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback onManage;

  const _LoansOverviewCard({
    required this.data,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      onTap: onManage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_outlined, color: Color(0xFFD97706), size: 18),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Khoản vay & Cho vay',
                    style: AppTypography.subhead.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.activeLoans.length} khoản',
                    style: AppTypography.caption2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, color: Color(0xFF059669), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Cho vay (Thu về)',
                            style: AppTypography.caption2.copyWith(
                              color: const Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVND(data.totalLent),
                        style: AppTypography.subhead.copyWith(
                          color: const Color(0xFF047857),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: Color(0xFFDC2626), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Đi vay (Cần trả)',
                            style: AppTypography.caption2.copyWith(
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVND(data.totalBorrowed),
                        style: AppTypography.subhead.copyWith(
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w800,
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
}

class _CashFlowCard extends StatelessWidget {
  final DashboardData data;
  final String userId;
  const _CashFlowCard({required this.data, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final maxVal = [
      data.currentMonthIncome,
      data.currentMonthExpenses,
      1,
    ].reduce((a, b) => a > b ? a : b).toDouble();
    final incomeProgress = (data.currentMonthIncome / maxVal).clamp(0.0, 1.0);
    final expenseProgress = (data.currentMonthExpenses / maxVal).clamp(0.0, 1.0);

    return GlassCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FractionallySizedBox(
            heightFactor: 0.85,
            child: TransactionHistorySheet(
              userId: userId,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dòng tiền tháng này',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FlowBar(
            label: 'Thu nhập',
            value: data.currentMonthIncome,
            progress: incomeProgress,
            color: const Color(0xFF34D399), // Emerald Green
          ),
          const SizedBox(height: AppSpacing.sm),
          _FlowBar(
            label: 'Chi tiêu',
            value: data.currentMonthExpenses,
            progress: expenseProgress,
            color: const Color(0xFFF87171), // Rose Red
          ),
        ],
      ),
    );
  }
}

class _FlowBar extends StatelessWidget {
  final String label;
  final int value;
  final double progress;
  final Color color;
  const _FlowBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.footnote.copyWith(
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
            Text(
              formatVND(value),
              style: AppTypography.subhead.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _RecentTransactionsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    if (transactions.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Center(
            child: Text(
              'Chưa có giao dịch nào',
              style: AppTypography.footnote.copyWith(color: secondaryTextColor),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _TransactionRow(tx: transactions[i]),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionRow({required this.tx});

  static const _inflowTypes = {
    'income',
    'borrowing',
    'loan_repayment_received',
  };

  Color _parseColor(String? hex, {required Color fallback}) {
    if (hex == null) return fallback;
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return fallback;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isInflow = _inflowTypes.contains(tx.type);
    final amountColor = isInflow ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final sign = isInflow ? '+' : '-';

    final iconColor = _parseColor(tx.categoryColor, fallback: const Color(0xFF60A5FA));
    final emoji = CategoryIconHelper.resolveIcon(
      tx.categoryIcon ??
          ((tx.categoryName?.isNotEmpty ?? false)
              ? tx.categoryName!.substring(0, 1)
              : null),
    );

    final title = (tx.note?.trim().isNotEmpty ?? false)
        ? tx.note!.trim()
        : (tx.categoryName ?? 'Giao dịch');
    final subtitle = tx.walletName ?? tx.fromWalletName ?? 'Tài khoản';

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subhead.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$sign${formatVND(tx.amount)}',
            style: AppTypography.subhead.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
