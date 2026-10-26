import 'package:flutter/material.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../wallet/wallet_screen.dart';
import '../report/report_screen.dart';
import '../budget/budget_screen.dart';
import '../asset/asset_screen.dart';
import '../loan/loan_screen.dart';
import '../category/category_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

/// "Thêm" tab — a hub of secondary destinations. Rendered inside the
/// [MainScreen] IndexedStack, so it paints on a transparent Scaffold body.
class MoreScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback onSignOut;

  const MoreScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    required this.onSignOut,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final rows = <_MenuEntry>[
      _MenuEntry(Icons.bar_chart_outlined, AppColors.accent, 'Báo cáo',
          () => _push(context, ReportScreen(userId: userId))),
      _MenuEntry(Icons.savings_outlined, const Color(0xFF34D399), 'Ngân sách',
          () => _push(context, BudgetScreen(userId: userId))),
      _MenuEntry(Icons.show_chart, AppColors.accentLight, 'Tài sản & Đầu tư',
          () => _push(context, AssetScreen(userId: userId))),
      _MenuEntry(Icons.supervisor_account_outlined, const Color(0xFFF5B942), 'Khoản vay & Nợ',
          () => _push(context, LoanScreen(userId: userId))),
      _MenuEntry(Icons.category_outlined, AppColors.accent, 'Danh mục',
          () => _push(context, CategoryScreen(userId: userId))),
      _MenuEntry(Icons.notifications_outlined, AppColors.accentLight, 'Thông báo',
          () => _push(context, NotificationScreen(userId: userId))),
      _MenuEntry(Icons.settings_outlined, secondaryTextColor, 'Cài đặt',
          () => _push(context, SettingsScreen(userId: userId))),
      _MenuEntry(Icons.person_outline, AppColors.accent, 'Hồ sơ',
          () => _push(
                context,
                ProfileScreen(
                  userId: userId,
                  userEmail: userEmail,
                  userName: userName,
                  userPhotoUrl: userPhotoUrl,
                  onSignOut: onSignOut,
                ),
              )),
    ];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('Thêm',
                  style: AppTypography.largeTitle.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.xs),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _MenuItem(entry: rows[i]),
                    if (i != rows.length - 1)
                      Divider(height: 1, thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final Color tint;
  final String title;
  final VoidCallback onTap;
  const _MenuEntry(this.icon, this.tint, this.title, this.onTap);
}

class _MenuItem extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: entry.onTap,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: AppSpacing.xs),
        child: Row(
          children: [
            IconBadge(icon: entry.icon, tint: entry.tint, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Text(entry.title,
                  style: AppTypography.body.copyWith(color: primaryTextColor)),
            ),
            Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 14),
          ],
        ),
      ),
    );
  }
}
