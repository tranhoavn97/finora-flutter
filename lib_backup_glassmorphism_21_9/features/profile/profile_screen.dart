import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/v8/finora_v8.dart';
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
import '../catalog/catalog_hub_screen.dart';
import '../../core/widgets/finora_motion.dart';

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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final displayName = userName.isNotEmpty ? userName : 'Hòa Trần (Louis XX)';
    final displayEmail =
        userEmail.isNotEmpty ? userEmail : 'tranhoavn97@gmail.com';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 136),
          children: [
            FinoraPageHeader(
              title: 'Hồ sơ & Tiện ích',
              onBack: !isRoot && Navigator.of(context).canPop()
                  ? () => Navigator.of(context).pop()
                  : null,
            ),
            const SizedBox(height: 16),

            // 2. User Info Card Liquid Glass
            FinoraStaggeredItem(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: isDark ? 0.82 : 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _Avatar(userName: displayName, userPhotoUrl: userPhotoUrl),
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
                              color: primaryTextColor,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
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
            ),
            const SizedBox(height: 16),

            // VIP BANNER: SCREEN CATALOG 2.0
            GestureDetector(
              onTap: () => _push(context, const CatalogHubScreen()),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.5 : 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Screen Catalog 2.0',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '22 MÀN HÌNH',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trải nghiệm 22 trang demo phong cách Glassmorphism 2.0',
                            style: TextStyle(fontSize: 12, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: QUẢN LÝ TÀI CHÍNH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'QUẢN LÝ TÀI CHÍNH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: isDark ? 0.80 : 0.90),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.10 : 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                      icon: Icons.insights_rounded,
                      iconBg: const Color(0xFFFFF7D6),
                      iconColor: const Color(0xFFD97706),
                      title: 'Báo cáo & phân tích',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, ReportScreen(userId: userId))),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                      icon: Icons.trending_up_rounded,
                      iconBg: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF059669),
                      title: 'Tài sản & Đầu tư (Vàng, BĐS, Sổ, Hụi)',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () => _push(context, AssetScreen(userId: userId))),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                      icon: Icons.pie_chart_outline_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Ngân sách chi tiêu',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, BudgetScreen(userId: userId))),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                      icon: Icons.flag_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF059669),
                      title: 'Mục tiêu tài chính',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () => _push(context, GoalScreen(userId: userId))),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                      icon: Icons.handshake_rounded,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFE11D48),
                      title: 'Khoản vay & Sổ nợ',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () => _push(context, LoanScreen(userId: userId))),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),

                  _buildMenuItem(
                      icon: Icons.category_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Danh mục thu chi',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, CategoryScreen(userId: userId))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: NHẬT KÝ & HOẠT ĐỘNG
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'KIỂM TOÁN & DỮ LIỆU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: isDark ? 0.80 : 0.90),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.10 : 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Nhật ký kiểm toán hoạt động',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () =>
                        _push(context, ActivityLogsScreen(userId: userId)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: THÔNG MINH & HỆ THỐNG
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'CÔNG CỤ & HỆ THỐNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: isDark ? 0.80 : 0.90),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.10 : 0.06),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.auto_awesome_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Trợ lý AI Finora (Tư vấn & Phân tích)',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () =>
                        _push(context, AiAdvisorScreen(userId: userId)),
                  ),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                    icon: Icons.delete_sweep_rounded,
                    iconBg: const Color(0xFFFFE4E6),
                    iconColor: const Color(0xFFE11D48),
                    title: 'Thùng rác phục hồi 30 ngày',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, TrashScreen(userId: userId)),
                  ),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Thông báo nhắc nhở',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () =>
                        _push(context, NotificationScreen(userId: userId)),
                  ),
                  Divider(
                      height: 1,
                      indent: 64,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05)),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF475569),
                    title: 'Cài đặt hệ thống & Giao diện',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. Logout Button Stadium Pill
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: 0.85),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required bool isDark,
    required Color primaryTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                size: 20),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  const _Avatar({required this.userName, this.userPhotoUrl});

  @override
  Widget build(BuildContext context) {
    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: userPhotoUrl!,
        imageBuilder: (_, provider) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: provider, fit: BoxFit.cover),
            border: Border.all(color: const Color(0xFF0284C7), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        placeholder: (_, __) => _initials(),
        errorWidget: (_, __, ___) => _initials(),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'H';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
