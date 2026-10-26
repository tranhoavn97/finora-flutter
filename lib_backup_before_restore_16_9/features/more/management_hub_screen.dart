import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../ai/ai_advisor_screen.dart';
import '../asset/asset_screen.dart';
import '../audit/activity_logs_screen.dart';
import '../budget/budget_screen.dart';
import '../category/category_screen.dart';
import '../goal/goal_screen.dart';
import '../loan/loan_screen.dart';
import '../notification/notification_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_screen.dart';

/// FINORA Management & Analytics Hub Screen
/// Trung tâm điều phối toàn diện: Quản lý, Phân tích & Tiện ích (Khung Layout chuẩn Web)
class ManagementHubScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback onSignOut;

  const ManagementHubScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    required this.onSignOut,
  });

  void _push(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutConfirm(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Xác nhận đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng tài chính cá nhân Finora không?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onSignOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
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
    final displayEmail = userEmail.isNotEmpty ? userEmail : 'user@finora.app';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F';

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
                    'Tiện ích & Quản lý',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _push(context, NotificationScreen(userId: userId)),
                        icon: Icon(
                          LucideIcons.bell,
                          size: 22,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        tooltip: 'Thông báo',
                      ),
                      IconButton(
                        onPressed: () => _push(context, SettingsScreen(userId: userId)),
                        icon: Icon(
                          LucideIcons.settings_2,
                          size: 22,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        tooltip: 'Cài đặt',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Thẻ Thông tin Người dùng (Soft Glass)
              FinoraSoftGlassCard(
                radius: 24,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                            ? Image.network(
                                userPhotoUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 12.5,
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
                    IconButton(
                      onPressed: () => _showLogoutConfirm(context),
                      icon: const Icon(
                        LucideIcons.log_out,
                        size: 20,
                        color: AppColors.error,
                      ),
                      tooltip: 'Đăng xuất',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Thẻ Chỉ số Thực tế (Real Stats Strip - Soft Glass)
              FinoraSoftGlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Row(
                  children: [
                    _buildStatItem(
                      label: 'Nguồn tiền',
                      value: '${wallets.length} ví',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                    ),
                    _buildStatItem(
                      label: 'Giao dịch',
                      value: '${transactions.length} mục',
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
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

              // 4. Nhóm QUẢN LÝ (Management Group - Khớp Web Soft Glass)
              _buildSectionTitle('QUẢN LÝ TÀI CHÍNH', isDark),
              const SizedBox(height: 10),
              FinoraSoftGlassCard(
                radius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: LucideIcons.layout_grid,
                      iconColor: AppColors.primary,
                      title: 'Danh mục thu chi',
                      subtitle: 'Sắp xếp phân loại các khoản tiền',
                      onTap: () => _push(context, CategoryScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.trending_up,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Tài sản & Đầu tư',
                      subtitle: 'Bất động sản, vàng, chứng khoán & tích lũy',
                      onTap: () => _push(context, AssetScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.piggy_bank,
                      iconColor: AppColors.warning,
                      title: 'Ngân sách & Hạn mức',
                      subtitle: 'Kiểm soát hạn mức chi tiêu mỗi tháng',
                      onTap: () => _push(context, BudgetScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.target,
                      iconColor: AppColors.success,
                      title: 'Mục tiêu tiết kiệm',
                      subtitle: 'Những cột mốc và ước mơ tài chính',
                      onTap: () => _push(context, GoalScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.hand_coins,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Khoản vay & Sổ nợ',
                      subtitle: 'Theo dõi các khoản vay mượn và cho vay',
                      onTap: () => _push(context, LoanScreen(userId: userId)),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Nhóm PHÂN TÍCH (Analytics Group - Khớp Web Soft Glass)
              _buildSectionTitle('PHÂN TÍCH & BÁO CÁO', isDark),
              const SizedBox(height: 10),
              FinoraSoftGlassCard(
                radius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: LucideIcons.chart_pie,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Báo cáo tài chính',
                      subtitle: 'Phân tích dòng tiền & cơ cấu chi tiêu',
                      onTap: () => _push(context, ReportScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.sparkles,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Trợ lý AI Finora',
                      subtitle: 'Tư vấn thông minh & bóc tách hóa đơn NLP',
                      onTap: () => _push(context, AiAdvisorScreen(userId: userId)),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Nhóm HỆ THỐNG & DỮ LIỆU (Soft Glass)
              _buildSectionTitle('HỆ THỐNG & DỮ LIỆU', isDark),
              const SizedBox(height: 10),
              FinoraSoftGlassCard(
                radius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: LucideIcons.bell,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Hộp thư thông báo',
                      subtitle: 'Cảnh báo hạn mức & nhắc nhở giao dịch',
                      onTap: () => _push(context, NotificationScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.clock,
                      iconColor: const Color(0xFF64748B),
                      title: 'Dấu chân tài chính',
                      subtitle: 'Lịch sử thay đổi và nhật ký hoạt động',
                      onTap: () => _push(context, ActivityLogsScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.trash,
                      iconColor: AppColors.error,
                      title: 'Thùng rác phục hồi',
                      subtitle: 'Khôi phục hoặc dọn sạch dữ liệu đã xóa',
                      onTap: () => _push(context, TrashScreen(userId: userId)),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuTile(
                      icon: LucideIcons.settings_2,
                      iconColor: const Color(0xFF475569),
                      title: 'Cài đặt hệ thống',
                      subtitle: 'Tiền tệ, giao diện, bảo mật & sao lưu',
                      onTap: () => _push(context, SettingsScreen(userId: userId)),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
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
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isAccent
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
