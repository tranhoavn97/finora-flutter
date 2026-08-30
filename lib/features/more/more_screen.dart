import 'package:flutter/material.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../report/report_screen.dart';
import '../budget/budget_screen.dart';
import '../asset/asset_screen.dart';
import '../loan/loan_screen.dart';
import '../category/category_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../goal/goal_screen.dart';

/// Personal hub. The previous settings-style list is replaced by an account
/// header, an insights feature card and a scannable two-column tool grid.
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

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final tools = <_MenuEntry>[
      _MenuEntry(
          Icons.savings_outlined,
          AppColors.success,
          'Ngân sách',
          'Lập hạn mức chi tiêu',
          () => _push(context, BudgetScreen(userId: userId))),
      _MenuEntry(
          Icons.show_chart_rounded,
          AppColors.info,
          'Tài sản',
          'Đầu tư và tích lũy',
          () => _push(context, AssetScreen(userId: userId))),
      _MenuEntry(
          Icons.handshake_outlined,
          AppColors.warning,
          'Vay & Nợ',
          'Theo dõi nghĩa vụ',
          () => _push(context, LoanScreen(userId: userId))),
      _MenuEntry(
          Icons.category_outlined,
          AppColors.accent,
          'Danh mục',
          'Cá nhân hóa thu chi',
          () => _push(context, CategoryScreen(userId: userId))),
      _MenuEntry(
          Icons.flag_rounded,
          AppColors.success,
          'Mục tiêu',
          'Tích lũy cho kế hoạch',
          () => _push(context, GoalScreen(userId: userId))),
      _MenuEntry(
          Icons.notifications_none_rounded,
          AppColors.warning,
          'Thông báo',
          'Nhắc việc tài chính',
          () => _push(context, NotificationScreen(userId: userId))),
      _MenuEntry(Icons.tune_rounded, muted, 'Cài đặt', 'Giao diện và dữ liệu',
          () => _push(context, SettingsScreen(userId: userId))),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 130),
        children: [
          Text('Cá nhân',
              style: AppTypography.largeTitle.copyWith(
                  color: text, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 18),
          Row(children: [
            _Avatar(url: userPhotoUrl, name: userName),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(userName.trim().isEmpty ? 'Tài khoản Finora' : userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title2
                          .copyWith(color: text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.footnote.copyWith(color: muted)),
                ])),
            IconButton.filledTonal(
              onPressed: () => _push(
                  context,
                  ProfileScreen(
                      userId: userId,
                      userEmail: userEmail,
                      userName: userName,
                      userPhotoUrl: userPhotoUrl,
                      onSignOut: onSignOut)),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ]),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _push(context, ReportScreen(userId: userId)),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                    colors: [Color(0xFF5D79A8), Color(0xFF243F73)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.accent.withOpacity(.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12))
                ],
              ),
              child: const Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('BỨC TRANH TÀI CHÍNH',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      SizedBox(height: 9),
                      Text('Xem báo cáo chuyên sâu',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.4)),
                      SizedBox(height: 7),
                      Text('Dòng tiền, xu hướng và cơ cấu chi tiêu',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                SizedBox(width: 16),
                CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0x24FFFFFF),
                    child: Icon(Icons.insights_rounded,
                        color: Colors.white, size: 27)),
              ]),
            ),
          ),
          const SizedBox(height: 28),
          Text('Công cụ quản lý',
              style: AppTypography.title3
                  .copyWith(color: text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 142,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemBuilder: (_, i) => _ToolCard(entry: tools[i]),
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuEntry(this.icon, this.tint, this.title, this.subtitle, this.onTap);
}

class _ToolCard extends StatelessWidget {
  final _MenuEntry entry;
  const _ToolCard({required this.entry});
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: entry.onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBadge(icon: entry.icon, tint: entry.tint, size: 38),
        const Spacer(),
        Text(entry.title,
            style: AppTypography.headline
                .copyWith(color: c.textPrimary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(entry.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(color: c.textSecondary)),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({this.url, required this.name});
  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'F' : name.trim()[0].toUpperCase();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withOpacity(.12),
          border: Border.all(color: AppColors.accent.withOpacity(.3))),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url != null && url!.isNotEmpty
          ? Image.network(url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(initial,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)))
          : Text(initial,
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
    );
  }
}
