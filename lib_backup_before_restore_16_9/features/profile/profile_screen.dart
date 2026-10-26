import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../ai/ai_advisor_screen.dart';
import '../audit/activity_logs_screen.dart';
import '../budget/budget_screen.dart';
import '../category/category_screen.dart';
import '../goal/goal_screen.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_screen.dart';

/// FINORA Pure — Profile & Space Screen
/// Hồ sơ & Tiện ích thuần khiết, tinh gọn, không phân mảnh.
class ProfileScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final bool isRoot;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    this.isRoot = false,
    required this.onSignOut,
  });

  void _push(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProv = context.watch<WalletProvider>();
    final txProv = context.watch<TransactionProvider>();

    final wallets = walletProv.wallets;
    final transactions = txProv.transactions;
    final totalBalance = wallets.fold<int>(0, (sum, w) => sum + w.balance);

    final displayName = userName.isNotEmpty ? userName : 'Người dùng Finora';
    final displayEmail =
        userEmail.isNotEmpty ? userEmail : 'user@finora.app';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F';

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
                  Text(
                    'Không gian cá nhân',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _push(context, SettingsScreen(userId: userId)),
                    icon: Icon(
                      LucideIcons.settings_2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Thẻ Thông tin Người dùng (User Card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Thẻ Chỉ số Thực tế (Real Stats Strip)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      label: 'Nguồn tiền',
                      value: '${wallets.length} ví',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    _buildStatItem(
                      label: 'Giao dịch',
                      value: '${transactions.length} mục',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    _buildStatItem(
                      label: 'Tổng số dư',
                      value: formatVND(totalBalance),
                      isDark: isDark,
                      isAccent: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Nhóm Quản lý Tài chính
              Text(
                'QUẢN LÝ TÀI CHÍNH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: LucideIcons.layers,
                      iconColor: AppColors.primary,
                      title: 'Danh mục thu chi',
                      subtitle: 'Sắp xếp phân loại giao dịch',
                      onTap: () => _push(context, CategoryScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.target,
                      iconColor: AppColors.warning,
                      title: 'Ngân sách & Hạn mức',
                      subtitle: 'Kiểm soát chi tiêu mỗi tháng',
                      onTap: () => _push(context, BudgetScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.flag,
                      iconColor: AppColors.success,
                      title: 'Mục tiêu tiết kiệm',
                      subtitle: 'Những cột mốc bạn hướng tới',
                      onTap: () => _push(context, GoalScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.sparkles,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Trợ lý AI Finora',
                      subtitle: 'Ghi nhanh & phân tích thông minh',
                      onTap: () => _push(context, AiAdvisorScreen(userId: userId)),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Nhóm Hệ thống & Dữ liệu
              Text(
                'HỆ THỐNG & DỮ LIỆU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: LucideIcons.palette,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Cài đặt giao diện',
                      subtitle: 'Chế độ Sáng / Tối, màu chủ đạo',
                      onTap: () => _push(context, SettingsScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.clock,
                      iconColor: const Color(0xFF64748B),
                      title: 'Lịch sử hoạt động',
                      subtitle: 'Dấu chân thay đổi dữ liệu',
                      onTap: () => _push(context, ActivityLogsScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.trash,
                      iconColor: AppColors.error,
                      title: 'Thùng rác',
                      subtitle: 'Khôi phục các mục đã xóa',
                      onTap: () => _push(context, TrashScreen(userId: userId)),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 6. Nút Đăng xuất
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSignOut();
                },
                icon: const Icon(LucideIcons.log_out, size: 18, color: AppColors.error),
                label: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required bool isDark,
    bool isAccent = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isAccent
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
    );
  }
}
