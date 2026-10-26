import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/wallet.dart';
import '../../state/wallet_provider.dart';
import '../transaction/transaction_history_sheet.dart';
import 'add_wallet_page.dart';

/// FINORA Pure — Wallet & Accounts Screen
/// Quản lý nguồn tiền thuần khiết, 100% dữ liệu thực, không dữ liệu ảo.
class WalletScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final bool isRoot;

  const WalletScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.isRoot = false,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  StreamSubscription<String>? _eventsSub;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WalletProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();
    context.read<WalletProvider>().load(widget.userId, familyId: widget.familyId, force: true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  void _openAddWallet({Wallet? wallet}) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddWalletPage(userId: widget.userId, wallet: wallet),
      ),
    );
  }

  void _showHistory(Wallet wallet) {
    HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WalletProvider>();
    final wallets = provider.wallets;

    // Tính toán số dư thực tế
    int totalAvailable = 0;
    int totalCreditDebt = 0;

    for (final w in wallets) {
      final isCredit = w.type.toLowerCase().contains('credit') ||
          w.type.toLowerCase().contains('thẻ tín dụng') ||
          w.type.toLowerCase().contains('tín dụng');
      if (isCredit && w.balance < 0) {
        totalCreditDebt += w.balance.abs();
      } else {
        totalAvailable += w.balance;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!widget.isRoot && Navigator.canPop(context))
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              LucideIcons.arrow_left,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ví & Tài khoản',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${wallets.length} nguồn tiền đang quản lý',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _refreshData,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                LucideIcons.rotate_cw,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        tooltip: 'Làm mới',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _openAddWallet(),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.plus,
                              color: Colors.white, size: 20),
                        ),
                        tooltip: 'Thêm ví mới',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Thẻ Tóm tắt Tài sản Thực (FinoraClayCard)
              FinoraClayCard(
                radius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG TIỀN KHẢ DỤNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatVND(totalAvailable),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131C2C)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dư nợ tín dụng:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatVND(totalCreditDebt),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: totalCreditDebt > 0
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Danh sách Ví Thực Tế
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách nguồn tiền',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddWallet(),
                    icon: const Icon(LucideIcons.plus, size: 15),
                    label: const Text(
                      'Thêm ví',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (wallets.isEmpty)
                FinoraSoftGlassCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.wallet,
                            size: 26,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Chưa có ví nào được tạo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tạo ví tiền mặt, tài khoản ngân hàng hoặc thẻ tín dụng để bắt đầu theo dõi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openAddWallet(),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Tạo ví đầu tiên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: wallets.map((wallet) {
                    final isCredit =
                        wallet.type.toLowerCase().contains('credit') ||
                            wallet.type.toLowerCase().contains('tín dụng');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _showHistory(wallet),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131A26).withValues(alpha: 0.6) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              FinoraBankLogo(
                                wallet: wallet,
                                size: 44,
                                radius: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            wallet.name,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceElevated
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            wallet.type,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Chạm để xem lịch sử dòng tiền',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatVND(wallet.balance),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isCredit && wallet.balance < 0
                                          ? AppColors.error
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : const Color(0xFF0F172A)),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _openAddWallet(wallet: wallet),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        LucideIcons.pencil,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}
