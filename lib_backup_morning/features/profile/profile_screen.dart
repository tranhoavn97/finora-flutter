import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../asset/asset_screen.dart';
import '../budget/budget_screen.dart';
import '../category/category_screen.dart';
import '../goal/goal_screen.dart';
import '../loan/loan_screen.dart';
import '../notification/notification_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../family/family_screen.dart';

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

    final displayName = userName.trim().isNotEmpty ? userName.trim() : 'Bạn';
    final displayEmail = userEmail.trim();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // 1. Top Title: Back + "Hồ sơ cá nhân"
            Row(
              children: [
                if (!isRoot && Navigator.of(context).canPop()) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(Icons.chevron_left_rounded,
                          color: primaryTextColor, size: 24),
                    ),
                  ),
                ],
                Text(
                  'Hồ sơ cá nhân',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. User Info Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
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
            const SizedBox(height: 18),

            Text(
              'Quản lý tài chính',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.family_restroom_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Nhóm gia đình (2–3 người)',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, const FamilyScreen()),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Thông báo',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () =>
                        _push(context, NotificationScreen(userId: userId)),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                      icon: Icons.insights_rounded,
                      iconBg: const Color(0xFFFFF7D6),
                      iconColor: const Color(0xFFD97706),
                      title: 'Báo cáo & phân tích',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, ReportScreen(userId: userId))),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Ngân sách',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, BudgetScreen(userId: userId))),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                      icon: Icons.flag_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF059669),
                      title: 'Mục tiêu',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () => _push(context, GoalScreen(userId: userId))),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                      icon: Icons.handshake_rounded,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFE11D48),
                      title: 'Khoản vay & Nợ',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () => _push(context, LoanScreen(userId: userId))),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                      icon: Icons.category_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Danh mục',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onTap: () =>
                          _push(context, CategoryScreen(userId: userId))),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Settings Menu List Card (Matching Screenshot Hồ sơ.jpg)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Thông tin cá nhân',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF10B981),
                    title: 'Bảo mật & Mật khẩu',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.palette_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Giao diện & Chủ đề',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.attach_money_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Đơn vị tiền tệ',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                  const Divider(
                      height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFCFFAFE),
                    iconColor: const Color(0xFF06B6D4),
                    title: 'Ngôn ngữ hiển thị',
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    onTap: () => _push(context, SettingsScreen(userId: userId)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Logout Button (Matching Hồ sơ.jpg)
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                      'Đăng xuất',
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
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
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
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: userPhotoUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initials(context),
          errorWidget: (_, __, ___) => _initials(context),
        ),
      );
    }
    return _initials(context);
  }

  Widget _initials(BuildContext context) {
    final name = userName.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'H';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
