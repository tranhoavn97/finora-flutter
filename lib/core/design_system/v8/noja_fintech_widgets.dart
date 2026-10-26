import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../state/theme_studio_controller.dart';
import '../../../state/widget_style_controller.dart';

/// Finora Noja Fintech 2.0 Design System Components
/// Replicating the clean, high-contrast, squircle elevated aesthetic from Noja Designs.

class NojaTopBar extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final String greeting;
  final int unreadCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;

  const NojaTopBar({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    this.greeting = 'Xin chào,',
    this.unreadCount = 0,
    this.onAvatarTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials =
        userName.trim().isEmpty ? 'F' : userName.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(children: [
        InkWell(
          onTap: onAvatarTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)]),
                image: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userPhotoUrl!), fit: BoxFit.cover)
                    : null),
            alignment: Alignment.center,
            child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                ? Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800))
                : null,
          ),
        ),
        Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('FINORA',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary)),
          const SizedBox(height: 2),
          Text(userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
        ])),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: onNotificationTap,
          style: IconButton.styleFrom(
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface),
          icon: Badge(
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_none_rounded)),
        ),
      ]),
    );
  }
}

class NojaBalanceHero extends StatelessWidget {
  final String accountTitle;
  final num balance;
  final num income;
  final num expense;
  final String periodLabel;
  final String ownerLabel;
  final VoidCallback? onOwnerTap;
  final VoidCallback? onPeriodTap;
  final bool obscureBalance;
  final VoidCallback onToggleObscure;
  final String? lastUpdatedText;
  final VoidCallback? onCardTap;
  final VoidCallback? onPaletteTap;

  const NojaBalanceHero({
    super.key,
    required this.accountTitle,
    required this.balance,
    this.income = 0,
    this.expense = 0,
    this.periodLabel = 'Hôm nay',
    this.ownerLabel = 'Tất cả',
    this.onOwnerTap,
    this.onPeriodTap,
    required this.obscureBalance,
    required this.onToggleObscure,
    this.lastUpdatedText = 'Cập nhật 1 phút trước',
    this.onCardTap,
    this.onPaletteTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final amount = formatter.format(balance.abs());
    final selectedStyle = context.watch<WidgetStyleController>().assetStyle;
    final preset = WidgetStyleController.assetPresets.firstWhere(
      (item) => item.id == selectedStyle,
      orElse: () => WidgetStyleController.assetPresets.first,
    );
    final heroColors = preset.gradientColors;
    final foreground = preset.isDark ? Colors.white : const Color(0xFF14213A);
    final secondary = foreground.withValues(alpha: .76);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: heroColors,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: .22),
              blurRadius: 25,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(accountTitle,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: secondary))),
                IconButton(
                  tooltip: obscureBalance ? 'Hiện số dư' : 'Ẩn số dư',
                  onPressed: onToggleObscure,
                  icon: Icon(
                      obscureBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: foreground,
                      size: 20),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                  obscureBalance
                      ? '•••••••• ₫'
                      : '${balance < 0 ? '-' : ''}$amount ₫',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: foreground)),
              const SizedBox(height: 18),
              Row(children: [
                _heroMetric('Thu nhập', income, const Color(0xFF5EEAD4),
                    formatter, obscureBalance, foreground),
                const SizedBox(width: 8),
                _heroMetric('Chi tiêu', expense, const Color(0xFFFDA4AF),
                    formatter, obscureBalance, foreground),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _heroChip(Icons.people_outline_rounded, ownerLabel, onOwnerTap,
                    foreground),
                const SizedBox(width: 8),
                _heroChip(Icons.date_range_rounded, periodLabel, onPeriodTap,
                    foreground),
                const Spacer(),
                if (onPaletteTap != null)
                  IconButton(
                    tooltip: 'Tùy biến chủ đề thẻ',
                    onPressed: onPaletteTap,
                    icon: Icon(Icons.palette_outlined,
                        color: foreground, size: 20),
                  ),
              ]),
            ]),
          ),
        ),
      );
    }

  Widget _heroMetric(String label, num value, Color accent,
      NumberFormat formatter, bool hidden, Color foreground) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: .12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 3, backgroundColor: accent),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: foreground.withValues(alpha: .8)))
        ]),
        const SizedBox(height: 5),
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
                hidden ? '•••• ₫' : '${formatter.format(value.abs())} ₫',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: foreground))),
      ]),
    ));
  }

  Widget _heroChip(
      IconData icon, String label, VoidCallback? onTap, Color foreground) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: foreground.withValues(alpha: .15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foreground)),
          const SizedBox(width: 2),
          Icon(Icons.expand_more_rounded, size: 14, color: foreground),
        ]),
      ),
    );
  }
}

class NojaBentoQuickActions extends StatelessWidget {
  final VoidCallback onSendMoneyTap;
  final VoidCallback onAirtimeTap;
  final VoidCallback onPayBillsTap;
  final VoidCallback onCardsTap;
  final VoidCallback? onMoreTap;
  final int activeCardsCount;

  const NojaBentoQuickActions({
    super.key,
    required this.onSendMoneyTap,
    required this.onAirtimeTap,
    required this.onPayBillsTap,
    required this.onCardsTap,
    this.onMoreTap,
    this.activeCardsCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final actions = [
      (
        Icons.arrow_upward_rounded,
        'Ghi chi',
        onSendMoneyTap,
        const Color(0xFFEF476F)
      ),
      (
        Icons.arrow_downward_rounded,
        'Ghi thu',
        onAirtimeTap,
        const Color(0xFF10B981)
      ),
      (
        Icons.swap_horiz_rounded,
        'Chuyển ví',
        onPayBillsTap,
        const Color(0xFF6366F1)
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Ví & thẻ',
        onCardsTap,
        const Color(0xFF0EA5E9)
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Thao tác nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: scheme.onSurface)),
        const SizedBox(height: 14),
        Row(children: [
          for (final action in actions)
            Expanded(
                child: Semantics(
              button: true,
              label: action.$2,
              child: InkWell(
                onTap: action.$3,
                borderRadius: studio?.getIconBorderRadius(58) ??
                    BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(children: [
                    Container(
                        width: 58,
                        height: 58,
                        decoration: studio != null
                            ? studio.getIconContainerDecoration(
                                color: action.$4,
                                isDark: isDark,
                                size: 58,
                              )
                            : BoxDecoration(
                                color: action.$4.withValues(alpha: .16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: action.$4.withValues(alpha: .35),
                                    width: 1.4)),
                        child: Icon(action.$1, size: 24, color: action.$4)),
                    const SizedBox(height: 8),
                    Text(action.$2,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                  ]),
                ),
              ),
            )),
        ]),
      ]),
    );
  }
}

class NojaTransactionTile extends StatelessWidget {
  final String title;
  final String time;
  final num amount;
  final String categoryName;
  final bool isIncome;
  final String? memberTag;
  final String? walletName;
  final IconData? iconData;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const NojaTransactionTile({
    super.key,
    required this.title,
    required this.time,
    required this.amount,
    required this.categoryName,
    required this.isIncome,
    this.memberTag,
    this.walletName,
    this.iconData,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formattedAmount =
        '${isIncome ? '+' : '-'}${formatter.format(amount.abs())} ₫';

    final isHusband = memberTag == 'husband';
    final isWife = memberTag == 'wife';
    final studio = Provider.of<ThemeStudioController?>(context);
    final cardBg = studio != null
        ? studio.getWhiteCardBg(isDark)
        : (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: .78);

    final effectiveRadius =
        studio?.getCardRadius(studio.transactionDensity) ?? 18.0;
    final effectiveBorder = studio?.getCardBorder(isDark) ??
        Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF1F5F9),
          width: 1,
        );
    final effectiveMargin = margin ??
        switch (studio?.transactionDensity) {
          CardDensity.compact =>
            const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          CardDensity.standard =>
            const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          CardDensity.spacious =>
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          null => const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        };
    final effectivePadding = switch (studio?.transactionDensity) {
      CardDensity.compact =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      CardDensity.standard =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      CardDensity.spacious =>
        const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      null => const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: effectiveMargin,
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: effectiveBorder,
          boxShadow: [
            if (studio != null) ...studio.getGlowShadows(isDark),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Tinted Icon Badge (Noja arrow or custom category icon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: studio?.getIconBorderRadius(40) ??
                    BorderRadius.circular(20),
                color: isIncome
                    ? (isDark
                        ? const Color(0xFF064E3B).withOpacity(0.5)
                        : const Color(0xFFE8F8F0))
                    : (isDark
                        ? const Color(0xFF7F1D1D).withOpacity(0.4)
                        : const Color(0xFFFEECEB)),
              ),
              child: Center(
                child: Icon(
                  iconData ??
                      (isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded),
                  size: 19,
                  color: isIncome
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Title, Member Tag and Subtitle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (isHusband || isWife) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isHusband
                                ? const Color(0xFF0284C7).withOpacity(0.12)
                                : const Color(0xFFDB2777).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isHusband ? 'Chồng' : 'Vợ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isHusband
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFDB2777),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (walletName != null && walletName!.isNotEmpty)
                        walletName!,
                      time,
                    ].join(' • '),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Amount and Category Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isIncome
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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
    );
  }
}

class NojaStackedCardView extends StatelessWidget {
  final String cardTitle;
  final num balance;
  final String? maskedNumber;
  final String? cardHolder;
  final String? expires;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const NojaStackedCardView({
    super.key,
    required this.cardTitle,
    required this.balance,
    this.maskedNumber,
    this.cardHolder,
    this.expires,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formattedBalance = '${formatter.format(balance.abs())} ₫';
    final heroColors =
        context.watch<ThemeStudioController>().currentPaletteMeta.heroGradient;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Layered back cards peeking out from top
          Positioned(
            top: -6,
            left: 20,
            right: 20,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: heroColors.last.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            top: -3,
            left: 10,
            right: 10,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: heroColors[1].withValues(alpha: .75),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),

          // Main 3D Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: heroColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: heroColors[1].withValues(alpha: .22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Label + Eye button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (onToggleObscure != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onToggleObscure!();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Balance
                const Text(
                  'Số dư khả dụng',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  obscure ? '•••••••• ₫' : formattedBalance,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                // Masked number
                if (maskedNumber != null && maskedNumber!.isNotEmpty)
                  Text(
                    maskedNumber!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                if (maskedNumber != null && maskedNumber!.isNotEmpty)
                  const SizedBox(height: 16),

                // Bottom row: Holder + Expires + Card Logo
                if ((cardHolder != null && cardHolder!.isNotEmpty) ||
                    (expires != null && expires!.isNotEmpty))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (cardHolder != null && cardHolder!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHỦ THẺ',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cardHolder!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      if (expires != null && expires!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HẾT HẠN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expires!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NojaSquircleActionRow extends StatelessWidget {
  final VoidCallback onFreezeTap;
  final VoidCallback onLimitsTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onTopUpTap;

  const NojaSquircleActionRow({
    super.key,
    required this.onFreezeTap,
    required this.onLimitsTap,
    required this.onDetailsTap,
    required this.onTopUpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquircleAction(
            context,
            icon: Icons.lock_outline_rounded,
            label: 'Khóa thẻ',
            onTap: onFreezeTap,
          ),
          _buildSquircleAction(
            context,
            icon: Icons.speed_rounded,
            label: 'Hạn mức',
            onTap: onLimitsTap,
          ),
          _buildSquircleAction(
            context,
            icon: Icons.info_outline_rounded,
            label: 'Chi tiết',
            onTap: onDetailsTap,
          ),
          _buildSquircleAction(
            context,
            icon: Icons.add_card_rounded,
            label: 'Nạp tiền',
            onTap: onTopUpTap,
          ),
        ],
      ),
    );
  }

  Widget _buildSquircleAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final cardBg = studio != null
        ? studio.getWhiteCardBg(isDark)
        : (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: .78);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class NojaSegmentedProgressWidget extends StatelessWidget {
  final num spent;
  final num limit;

  const NojaSegmentedProgressWidget({
    super.key,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final cardBg = studio != null
        ? studio.getWhiteCardBg(isDark)
        : (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: .78);
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formattedSpent = '${formatter.format(spent.abs())} ₫';
    final formattedLimit = '${formatter.format(limit.abs())} ₫';

    final effectiveLimit = limit <= 0 ? 1 : limit;
    final percent = (spent / effectiveLimit).clamp(0.0, 1.0);
    final percentInt = (percent * 100).toInt();

    const totalBars = 22;
    final filledBars = (percent * totalBars).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Spent this month | Value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã chi tiêu tháng này',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: formattedSpent,
                        style: const TextStyle(color: Color(0xFF10B981)),
                      ),
                      TextSpan(
                        text: ' / $formattedLimit',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Progress Bar
            Row(
              children: List.generate(totalBars, (index) {
                final isFilled = index < filledBars;
                return Expanded(
                  child: Container(
                    height: 9,
                    margin: EdgeInsets.only(
                      right: index == totalBars - 1 ? 0 : 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? const Color(0xFF10B981)
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Bottom percentage labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentInt% hạn mức tháng này',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
    );
  }
}
