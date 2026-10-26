import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Hồ sơ',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 40),
        children: [
          // Avatar & info
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  _Avatar(userName: userName, userPhotoUrl: userPhotoUrl),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    userName.isEmpty ? 'Người dùng Finora' : userName,
                    style: AppTypography.title2.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Options
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _options.length; i++) ...[
                  _OptionItem(option: _options[i]),
                  if (i != _options.length - 1)
                    Divider(height: 1, thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sign out
          GlassCard(
            onTap: () {
              onSignOut();
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.exit_to_app, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Text('Đăng xuất',
                      style: AppTypography.buttonLabel.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _options = <_ProfileOption>[
  _ProfileOption(Icons.person_outline, AppColors.accent, 'Thông tin cá nhân'),
  _ProfileOption(Icons.lock_outline, Color(0xFF34D399), 'Bảo mật'),
  _ProfileOption(Icons.dark_mode_outlined, Color(0xFFF5B942), 'Chủ đề'),
  _ProfileOption(Icons.attach_money, AppColors.accentLight, 'Tiền tệ'),
  _ProfileOption(Icons.language, Color(0xFF8B5CF6), 'Ngôn ngữ'),
];

class _ProfileOption {
  final IconData icon;
  final Color tint;
  final String title;
  const _ProfileOption(this.icon, this.tint, this.title);
}

class _OptionItem extends StatelessWidget {
  final _ProfileOption option;
  const _OptionItem({required this.option});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () {},
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.sm),
        child: Row(
          children: [
            IconBadge(icon: option.icon, tint: option.tint, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Text(option.title,
                  style: AppTypography.body.copyWith(color: primaryTextColor)),
            ),
            Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 14),
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
    final initial =
        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFC084FC), Color(0xFFF472B6)]),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: userPhotoUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initials(initial),
            )
          : _initials(initial),
    );
  }

  Widget _initials(String initial) => Text(
        initial,
        style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      );
}
