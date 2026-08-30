import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../settings/settings_screen.dart';

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
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Hồ sơ cá nhân',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // Avatar & info
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Avatar(userName: userName, userPhotoUrl: userPhotoUrl),
                  const SizedBox(height: 14),
                  Text(
                    userName.isEmpty ? 'Người dùng Finora' : userName,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Options
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    _OptionItem(
                      option: _options[i],
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SettingsScreen(userId: userId),
                      )),
                    ),
                    if (i != _options.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? const Color(0xFF202D4E)
                            : const Color(0xFFE8EEF8),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sign out
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () async {
                HapticFeedback.selectionClick();
                final confirm = await showConfirmDeleteDialog(
                  context: context,
                  title: 'Đăng xuất?',
                  content:
                      'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Finora này?',
                );
                if (confirm && context.mounted) {
                  onSignOut();
                  Navigator.of(context).pop();
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _options = <_ProfileOption>[
  _ProfileOption(
      Icons.person_outline_rounded, AppColors.primary, 'Thông tin cá nhân'),
  _ProfileOption(
      Icons.lock_outline_rounded, AppColors.success, 'Bảo mật & Mật khẩu'),
  _ProfileOption(
      Icons.palette_outlined, AppColors.warning, 'Giao diện & Chủ đề'),
  _ProfileOption(Icons.payments_outlined, AppColors.accent, 'Đơn vị tiền tệ'),
  _ProfileOption(
      Icons.language_rounded, Color(0xFF0891B2), 'Ngôn ngữ hiển thị'),
];

class _ProfileOption {
  final IconData icon;
  final Color tint;
  final String title;
  const _ProfileOption(this.icon, this.tint, this.title);
}

class _OptionItem extends StatelessWidget {
  final _ProfileOption option;
  final VoidCallback onTap;
  const _OptionItem({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconBadge(
                icon: option.icon, tint: option.tint, size: 38, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: c.textTertiary, size: 14),
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
        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'F';
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF075985), Color(0xFF22B8CF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: userPhotoUrl!,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initials(initial),
            )
          : _initials(initial),
    );
  }

  Widget _initials(String initial) => Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      );
}
