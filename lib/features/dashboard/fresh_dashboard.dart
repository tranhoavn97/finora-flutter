import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/theme/emerald_tokens.dart';
import '../../core/widgets/emerald_components.dart';
import '../../state/dashboard_provider.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_sheet.dart';
import '../qr_pay/qr_scanner_screen.dart';
import '../category/category_screen.dart';

/// FINORA Emerald Dashboard (06 Home - Trang chủ)
/// Nguồn chuẩn: D:\FINORA-\design\emerald-demo-20261027 (screens.js line 51)
class FreshDashboard extends StatelessWidget {
  final String userId;
  final String userName;
  final DashboardProvider provider;
  final Widget scope;
  final bool hidden;
  final VoidCallback onToggleMask;
  final VoidCallback onNotifications;
  final VoidCallback onTransactions;
  final VoidCallback onWallets;
  final VoidCallback onPlanning;
  final VoidCallback onAssistant;
  final VoidCallback onQuickLog;
  final VoidCallback? onScanQr;
  final Future<void> Function() onRefresh;

  const FreshDashboard({
    super.key,
    required this.userId,
    required this.userName,
    required this.provider,
    required this.scope,
    required this.hidden,
    required this.onToggleMask,
    required this.onNotifications,
    required this.onTransactions,
    required this.onWallets,
    required this.onPlanning,
    required this.onAssistant,
    required this.onQuickLog,
    this.onScanQr,
    required this.onRefresh,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'F.';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  IconData _iconForCategory(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('ăn') || c.contains('uống') || c.contains('food') || c.contains('cà phê')) {
      return LucideIcons.utensils;
    }
    if (c.contains('lương') || c.contains('thu') || c.contains('salary') || c.contains('thưởng')) {
      return LucideIcons.briefcase;
    }
    if (c.contains('mua') || c.contains('sắm') || c.contains('shop') || c.contains('chợ') || c.contains('siêu thị')) {
      return LucideIcons.shopping_bag;
    }
    if (c.contains('xe') || c.contains('xăng') || c.contains('đi') || c.contains('grab') || c.contains('travel')) {
      return LucideIcons.car;
    }
    if (c.contains('nhà') || c.contains('điện') || c.contains('nước') || c.contains('house')) {
      return LucideIcons.house;
    }
    return LucideIcons.receipt;
  }

  Color _iconColorForCategory(String? cat, bool isExpense) {
    if (!isExpense) return EmeraldTokens.emerald;
    final c = (cat ?? '').toLowerCase();
    if (c.contains('mua') || c.contains('sắm') || c.contains('shop')) {
      return EmeraldTokens.blue;
    }
    if (c.contains('cà phê') || c.contains('tiện ích')) {
      return EmeraldTokens.gold;
    }
    return EmeraldTokens.coral;
  }

  Color _iconBgForCategory(String? cat, bool isExpense) {
    if (!isExpense) return EmeraldTokens.mintLight;
    final c = (cat ?? '').toLowerCase();
    if (c.contains('mua') || c.contains('sắm') || c.contains('shop')) {
      return EmeraldTokens.blueBg;
    }
    if (c.contains('cà phê') || c.contains('tiện ích')) {
      return EmeraldTokens.goldBg;
    }
    return EmeraldTokens.dangerBg;
  }

  @override
  Widget build(BuildContext context) {
    final data = provider.data;
    final isLoading = provider.isLoading && data.wallets.isEmpty;
    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    // Balance & Month figures
    final totalBalance = data.totalWalletBalance;
    final balanceStr = '${currencyFmt.format(totalBalance)} ₫';
    final monthIncome = data.periodIncome;
    final monthExpense = data.periodExpense;

    void openAdd(String type) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddTransactionPage(
            userId: userId,
            initialType: type,
          ),
        ),
      );
    }

    void openTransfer() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddTransactionPage(
            userId: userId,
            initialType: 'transfer',
          ),
        ),
      );
    }

    void openScan() {
      if (onScanQr != null) {
        onScanQr!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QrScannerScreen(userId: userId)),
        );
      }
    }

    void openCategories() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryScreen(userId: userId)),
      );
    }

    return Container(
      color: EmeraldTokens.ivoryBg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: EmeraldTokens.emerald,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              EmeraldTokens.pagePadding,
              8,
              EmeraldTokens.pagePadding,
              90,
            ),
            children: [
              // 1. Home Top Header (Avatar, Greeting, Name + Dropdown, Bell Icon)
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 19),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment(-0.8, -0.6),
                          end: Alignment(0.9, 0.8),
                          colors: [Color(0xFFDDF0E6), Color(0xFFABD7C4)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(userName),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00684D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              color: EmeraldTokens.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: EmeraldTokens.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.chevron_down, size: 14, color: EmeraldTokens.muted),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onAssistant,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Image.asset(
                          'assets/mascot/expression-01-happy.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: onNotifications,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 36,
                        alignment: Alignment.centerRight,
                        child: const Icon(LucideIcons.bell, size: 20, color: EmeraldTokens.ink),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Balance Card
              if (isLoading)
                Container(
                  height: 146,
                  margin: const EdgeInsets.only(bottom: 21),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(EmeraldTokens.balanceCardRadius),
                    color: EmeraldTokens.mintSoft,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Đang tải tài khoản…',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: EmeraldTokens.muted,
                    ),
                  ),
                )
              else
                EmeraldBalanceCard(
                  title: 'Tổng số dư hiện tại',
                  amountValue: totalBalance,
                  amount: balanceStr,
                  isAmountVisible: !hidden,
                  onToggleMask: onToggleMask,
                  onAddTransaction: () => openAdd('expense'),
                ),

              // 3. Quick Actions (Chuyển ví, Thu nhập, Quét QR, Tiện ích)
              EmeraldQuickActions(
                items: [
                  EmeraldQuickActionItem(
                    icon: LucideIcons.send,
                    label: 'Chuyển ví',
                    onTap: openTransfer,
                  ),
                  EmeraldQuickActionItem(
                    icon: LucideIcons.arrow_down_left,
                    label: 'Thu nhập',
                    onTap: () => openAdd('income'),
                  ),
                  EmeraldQuickActionItem(
                    icon: LucideIcons.qr_code,
                    label: 'Quét QR',
                    onTap: openScan,
                  ),
                  EmeraldQuickActionItem(
                    icon: LucideIcons.layout_grid,
                    label: 'Tiện ích',
                    onTap: openCategories,
                  ),
                ],
              ),

              // 4. Section: Tháng này (Reports ↗)
              EmeraldSectionTitle(
                title: 'Tháng này',
                linkText: 'Báo cáo ↗',
                onLinkTap: onPlanning,
              ),

              // Mini Stats (Thu nhập vs Chi tiêu)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EmeraldTokens.mintTabBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thu nhập',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: EmeraldTokens.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hidden ? '•••• ₫' : '+${currencyFmt.format(monthIncome)} ₫',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                              color: EmeraldTokens.positive,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EmeraldTokens.mintTabBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiêu',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: EmeraldTokens.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hidden ? '•••• ₫' : '${currencyFmt.format(monthExpense)} ₫',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                              color: EmeraldTokens.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 5. Feature Banner (assets/branding/emerald-hero.png)
              GestureDetector(
                onTap: onPlanning,
                child: Container(
                  height: 94,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: EmeraldTokens.featureBannerGrad,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16,
                        top: 12,
                        bottom: 12,
                        right: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Chăm chút hôm nay.\nVững vàng ngày mai.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Flexible(
                                  child: Text(
                                    'Kế hoạch tích lũy ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      color: Color(0xFFC4E8DE),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(LucideIcons.arrow_right, size: 10, color: Color(0xFFC4E8DE)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: -10,
                        width: 114,
                        height: 114,
                        child: IgnorePointer(
                          child: Image.asset(
                            'assets/mascot/animation-keypose-02-saving.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Section: Giao dịch gần đây
              EmeraldSectionTitle(
                title: 'Giao dịch gần đây',
                linkText: 'Xem tất cả',
                onLinkTap: onTransactions,
              ),

              // Recent transactions list
              if (data.recentTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'Chưa có giao dịch gần đây',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: EmeraldTokens.muted,
                    ),
                  ),
                )
              else
                ...data.recentTransactions.take(6).map((tx) {
                  final isIncome = tx.type.toLowerCase() == 'income' || tx.type.toLowerCase() == 'thu';
                  final amountPrefix = isIncome ? '+' : '−';
                  final formattedAmount = '$amountPrefix${currencyFmt.format(tx.amount.abs())} ₫';
                  final txTimestamp = tx.date > 0 ? tx.date : tx.createdAt;
                  final formattedDate = txTimestamp > 0
                      ? DateFormat('dd/MM, HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            txTimestamp < 10000000000 ? txTimestamp * 1000 : txTimestamp,
                          ),
                        )
                      : 'Hôm nay';

                  final cat = tx.categoryName ?? '';
                  final noteStr = (tx.note != null && tx.note!.isNotEmpty) ? tx.note! : 'Chi tiêu sinh hoạt';

                  return EmeraldTransactionRow(
                    title: cat.isNotEmpty ? cat : 'Chi tiêu khác',
                    meta: noteStr,
                    amount: hidden ? '•••• ₫' : formattedAmount,
                    date: formattedDate,
                    icon: _iconForCategory(cat),
                    iconBg: _iconBgForCategory(cat, !isIncome),
                    iconColor: _iconColorForCategory(cat, !isIncome),
                    onTap: () {
                      showTransactionDetailSheet(
                        context,
                        userId: userId,
                        transaction: tx,
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
