import '../family/family_screen.dart';
import '../../core/widgets/fresh_design.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/theme/finora_tokens.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/theme_studio_controller.dart';
import '../ai/ai_advisor_screen.dart';
import '../audit/activity_logs_screen.dart';
import '../category/category_screen.dart';
import '../notification/notification_screen.dart';
import '../settings/bank_sync_settings_sheet.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_screen.dart';

/// Trang Cá Nhân & Thiết Lập Hệ Thống Finora
/// Thiết kế tinh giản, loại bỏ hoàn toàn các liên kết trùng lặp với thanh Dock
/// và các số liệu ảo, tập trung vào Quản lý tài khoản, AI Advisor và Cài đặt dữ liệu.
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

  void _confirmSignOut(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Đăng xuất tài khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này trên thiết bị không?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onSignOut();
            },
            child: const Text('Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final cardBg = studio?.getCardFillColor(isDark) ??
        (isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.80)
            : Colors.white.withValues(alpha: 0.90));
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final displayName = userName.isNotEmpty ? userName : 'Hòa Trần';
    final displayEmail =
        userEmail.isNotEmpty ? userEmail : 'tranhoavn97@gmail.com';
    final primaryAccent = studio?.primaryColor ?? const Color(0xFF2563EB);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Cá nhân & Cài đặt',
        onBack: !isRoot && Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          GlassScaffold.topInset(context, 10),
          16,
          136,
        ),
        physics: const BouncingScrollPhysics(),
        children: [

          // 1. USER CARD (Apple Minimalist Aesthetic)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.10 : 0.06),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _Avatar(
                  userName: displayName,
                  userPhotoUrl: userPhotoUrl,
                  accentColor: primaryAccent,
                  studio: studio,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: FinoraTokens.text(isDark),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: FinoraTokens.surface2(isDark),
                              borderRadius: BorderRadius.circular(100),
                              border:
                                  Border.all(color: FinoraTokens.line(isDark)),
                            ),
                            child: Text(
                              'Gia đình',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: FinoraTokens.textSub(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayEmail,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: FinoraTokens.textMuted(isDark),
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
          const SizedBox(height: 14),

          // 2. SPOTLIGHT: TRỢ LÝ TÀI CHÍNH FINORA & SỨC KHỎE TÀI CHÍNH (Emerald Fintech)
          InkWell(
            onTap: () => _push(context, AiAdvisorScreen(userId: userId)),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: FinoraTokens.emeraldCardDecoration(
                isDark: isDark,
                radius: 20,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trợ lý tài chính FINORA',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sức khỏe tài chính 92% · Tư vấn chi tiêu thông minh',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Radial Gauge 92%
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: 0.92,
                            strokeWidth: 4.5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF34D399),
                            ),
                          ),
                        ),
                        const Text(
                          '92%',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. SECTION: QUẢN LÝ
          _buildSectionHeader('QUẢN LÝ',
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
          const SizedBox(height: 8),
          Container(
            decoration: FinoraTokens.calmCardDecoration(isDark: isDark),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: LucideIcons.users,
                  iconBg: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                  iconColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                  title: 'Quản lý gia đình',
                  subtitle: 'Thành viên, lời mời và quyền truy cập',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () => _push(context, const FamilyScreen()),
                ),
                _buildDivider(isDark),
                _buildMenuItem(
                  icon: LucideIcons.layout_grid,
                  iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                  title: 'Danh mục thu chi',
                  subtitle: 'Tùy chỉnh nhóm chi, biểu tượng & màu sắc',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () => _push(context, CategoryScreen(userId: userId)),
                ),
                _buildDivider(isDark),
                _buildMenuItem(
                  icon: LucideIcons.bell,
                  iconBg: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                  iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  title: 'Thông báo',
                  subtitle: 'Hoạt động và cập nhật của bạn',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () =>
                      _push(context, NotificationScreen(userId: userId)),
                ),
                _buildDivider(isDark),
                _buildMenuItem(
                  icon: LucideIcons.palette,
                  iconBg: isDark ? const Color(0xFF164E63) : const Color(0xFFECFEFF),
                  iconColor: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
                  title: 'Chế độ hiển thị & Giao diện',
                  subtitle: 'Tùy chỉnh chế độ sáng, tối & bảng màu',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () => _push(context, SettingsScreen(userId: userId)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. SECTION: DỮ LIỆU & BẢO MẬT
          _buildSectionHeader('DỮ LIỆU & BẢO MẬT',
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
          const SizedBox(height: 8),
          Container(
            decoration: FinoraTokens.calmCardDecoration(isDark: isDark),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.history_rounded,
                  iconBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFF0FDFA),
                  iconColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                  title: 'Lịch sử thay đổi',
                  subtitle: 'Lịch sử thay đổi & đối soát thao tác',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () =>
                      _push(context, ActivityLogsScreen(userId: userId)),
                ),
                _buildDivider(isDark),
                _buildMenuItem(
                  icon: LucideIcons.bell_ring,
                  iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                  title: 'Đọc biến động ngân hàng (BETA)',
                  subtitle: 'Tự động nhận diện số dư 30+ ngân hàng (Cách A)',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () => BankSyncSettingsSheet.show(context, userId: userId),
                ),
                _buildDivider(isDark),
                _buildMenuItem(
                  icon: Icons.delete_outline_rounded,
                  iconBg: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2),
                  iconColor: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                  title: 'Thùng rác phục hồi 30 ngày',
                  subtitle: 'Khôi phục giao dịch đã xóa',
                  isDark: isDark,
                  primaryTextColor: FinoraTokens.text(isDark),
                  secondaryTextColor: FinoraTokens.textMuted(isDark),
                  studio: studio,
                  onTap: () => _push(context, TrashScreen(userId: userId)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. NÚT ĐĂNG XUẤT (Clean Notebook Style)
          GestureDetector(
            onTap: () => _confirmSignOut(context),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: FinoraTokens.surface(isDark),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: FinoraTokens.neg(isDark).withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.log_out,
                      color: FinoraTokens.neg(isDark), size: 17),
                  const SizedBox(width: 8),
                  Text(
                    'Đăng xuất tài khoản',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: FinoraTokens.neg(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. FOOTER
          Center(
            child: Text(
              'Finora Finance · Quản lý tài chính cá nhân thông minh',
              style: TextStyle(
                fontSize: 11,
                color: secondaryTextColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
    ThemeStudioController? studio,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(studio?.getButtonRadius() ?? 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: studio?.getIconContainerDecoration(
                    color: iconColor,
                    isDark: isDark,
                    size: 40,
                  ) ??
                  BoxDecoration(
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
              child: Icon(
                icon,
                color: (studio != null &&
                        (studio.iconStyle == AppIconStyle.round ||
                            studio.iconStyle == AppIconStyle.glassGlow))
                    ? iconColor
                    : (studio != null &&
                            studio.iconStyle == AppIconStyle.dimensional
                        ? Colors.white
                        : iconColor),
                size: 20,
              ),
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
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
  final Color accentColor;
  final ThemeStudioController? studio;

  const _Avatar({
    required this.userName,
    this.userPhotoUrl,
    required this.accentColor,
    this.studio,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = studio?.getAvatarGlowColor();
    final List<BoxShadow> shadows = [
      if (glowColor != null) ...[
        BoxShadow(
          color: glowColor.withValues(alpha: 0.55),
          blurRadius: 16,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.28),
          blurRadius: 28,
          spreadRadius: 6,
        ),
      ] else ...[
        BoxShadow(
          color: accentColor.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ];

    final effectiveBorderColor = glowColor ?? accentColor;

    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: userPhotoUrl!,
        imageBuilder: (_, provider) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: provider, fit: BoxFit.cover),
            border: Border.all(color: effectiveBorderColor, width: 2.2),
            boxShadow: shadows,
          ),
        ),
        placeholder: (_, __) => _initials(shadows, effectiveBorderColor),
        errorWidget: (_, __, ___) => _initials(shadows, effectiveBorderColor),
      );
    }
    return _initials(shadows, effectiveBorderColor);
  }

  Widget _initials(List<BoxShadow> shadows, Color borderColor) {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'F';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F6E56), Color(0xFF003D35)],
        ),
        border: Border.all(color: borderColor, width: 2.2),
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'BeVietnamPro',
        ),
      ),
    );
  }
}

/// Mở Apple Sheet Modal tuỳ biến nền Pha Màu RGB (Mesh Gradient Blur)
Future<void> showCustomRgbBackgroundModal(BuildContext context) {
  HapticFeedback.selectionClick();
  return showFinoraGlassModalBottomSheet<void>(
    context: context,
    title: 'Tuỳ biến nền Pha Màu RGB',
    subtitle: 'Pha màu 3 vùng Mesh Gradient Blur chuẩn Apple iOS 18',
    icon: Icons.blur_on_rounded,
    iconColor: const Color(0xFF10B981),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    builder: (ctx) => const _CustomRgbBackgroundModalContent(),
  );
}

class _RgbPresetItem {
  final String name;
  final Color c1;
  final Color c2;
  final Color c3;
  final double intensity;

  const _RgbPresetItem({
    required this.name,
    required this.c1,
    required this.c2,
    required this.c3,
    this.intensity = 0.18,
  });
}

class _CustomRgbBackgroundModalContent extends StatefulWidget {
  const _CustomRgbBackgroundModalContent();

  @override
  State<_CustomRgbBackgroundModalContent> createState() =>
      _CustomRgbBackgroundModalContentState();
}

class _CustomRgbBackgroundModalContentState
    extends State<_CustomRgbBackgroundModalContent> {
  int _selectedBlobIndex = 0;

  static const List<_RgbPresetItem> _presets = [
    _RgbPresetItem(
      name: 'Ngọc Lục Bảo',
      c1: Color(0xFF10B981),
      c2: Color(0xFF0284C7),
      c3: Color(0xFF8B5CF6),
    ),
    _RgbPresetItem(
      name: 'Đại Dương Xanh',
      c1: Color(0xFF0EA5E9),
      c2: Color(0xFF2563EB),
      c3: Color(0xFF06B6D4),
    ),
    _RgbPresetItem(
      name: 'Hoàng Hôn Hồng',
      c1: Color(0xFFF43F5E),
      c2: Color(0xFFF59E0B),
      c3: Color(0xFFA855F7),
    ),
    _RgbPresetItem(
      name: 'Tím Cực Quang',
      c1: Color(0xFF8B5CF6),
      c2: Color(0xFFEC4899),
      c3: Color(0xFF3B82F6),
    ),
    _RgbPresetItem(
      name: 'Tối Giản Tinh Khiết',
      c1: Color(0xFF64748B),
      c2: Color(0xFF94A3B8),
      c3: Color(0xFF0EA5E9),
      intensity: 0.10,
    ),
  ];

  static const List<Color> _quickSwatches = [
    Color(0xFF10B981),
    Color(0xFF0284C7),
    Color(0xFF2563EB),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFF64748B),
  ];

  Color _activeColor(ThemeStudioController studio) {
    switch (_selectedBlobIndex) {
      case 0:
        return studio.customBgColor1;
      case 1:
        return studio.customBgColor2;
      default:
        return studio.customBgColor3;
    }
  }

  void _updateActiveColor(ThemeStudioController studio, Color color) {
    if (_selectedBlobIndex == 0) {
      studio.setCustomBgColor1(color);
    } else if (_selectedBlobIndex == 1) {
      studio.setCustomBgColor2(color);
    } else {
      studio.setCustomBgColor3(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardSurface =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    final activeColor = _activeColor(studio);
    final rVal = (activeColor.r * 255.0).round().clamp(0, 255);
    final gVal = (activeColor.g * 255.0).round().clamp(0, 255);
    final bVal = (activeColor.b * 255.0).round().clamp(0, 255);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Live Preview Card
        Container(
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF6F8FA),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _ModalMeshPreviewPainter(
                  c1: studio.customBgColor1,
                  c2: studio.customBgColor2,
                  c3: studio.customBgColor3,
                  intensity: studio.useCustomRgbMeshBg
                      ? studio.customBgIntensity
                      : 0.0,
                  isDark: isDark,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xem trước nền Mesh Gradient Blur',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            studio.useCustomRgbMeshBg
                                ? '3 vùng màu RGB hoà quyện mềm mại 120Hz'
                                : 'Đang tắt hiệu ứng pha màu nền',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildColorDot(studio.customBgColor1),
                        const SizedBox(width: 6),
                        _buildColorDot(studio.customBgColor2),
                        const SizedBox(width: 6),
                        _buildColorDot(studio.customBgColor3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Toggle switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bật nền pha màu Gradient Blur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              Switch.adaptive(
                value: studio.useCustomRgbMeshBg,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  studio.setUseCustomRgbMeshBg(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Quick Presets
        Text(
          'BẢNG MÀU MẪU NHANH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: subColor,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _presets.map((preset) {
              final isSelected = studio.customBgColor1.toARGB32() ==
                      preset.c1.toARGB32() &&
                  studio.customBgColor2.toARGB32() == preset.c2.toARGB32() &&
                  studio.customBgColor3.toARGB32() == preset.c3.toARGB32();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    studio.applyRgbMeshPreset(
                      preset.c1,
                      preset.c2,
                      preset.c3,
                      intensity: preset.intensity,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFEAF0ED))
                          : cardSurface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color:
                            isSelected ? const Color(0xFF10B981) : borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [preset.c1, preset.c2, preset.c3],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // 4. 3 Blob Selector Tabs
        Text(
          'CHỌN VÙNG MÀU ĐỂ PHA RGB',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: subColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildBlobSelectorButton(
              index: 0,
              label: 'Màu 1 - Góc trên trái',
              color: studio.customBgColor1,
              isDark: isDark,
              titleColor: titleColor,
              borderColor: borderColor,
              cardSurface: cardSurface,
            ),
            const SizedBox(width: 8),
            _buildBlobSelectorButton(
              index: 1,
              label: 'Màu 2 - Góc phải',
              color: studio.customBgColor2,
              isDark: isDark,
              titleColor: titleColor,
              borderColor: borderColor,
              cardSurface: cardSurface,
            ),
            const SizedBox(width: 8),
            _buildBlobSelectorButton(
              index: 2,
              label: 'Màu 3 - Góc dưới',
              color: studio.customBgColor3,
              isDark: isDark,
              titleColor: titleColor,
              borderColor: borderColor,
              cardSurface: cardSurface,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 5. RGB Sliders + Swatches
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRgbChannelSlider(
                label: 'R (Đỏ)',
                value: rVal,
                activeColor: const Color(0xFFEF4444),
                titleColor: titleColor,
                onChanged: (v) {
                  _updateActiveColor(
                    studio,
                    Color.fromARGB(255, v, gVal, bVal),
                  );
                },
              ),
              _buildRgbChannelSlider(
                label: 'G (Lục)',
                value: gVal,
                activeColor: const Color(0xFF10B981),
                titleColor: titleColor,
                onChanged: (v) {
                  _updateActiveColor(
                    studio,
                    Color.fromARGB(255, rVal, v, bVal),
                  );
                },
              ),
              _buildRgbChannelSlider(
                label: 'B (Lam)',
                value: bVal,
                activeColor: const Color(0xFF3B82F6),
                titleColor: titleColor,
                onChanged: (v) {
                  _updateActiveColor(
                    studio,
                    Color.fromARGB(255, rVal, gVal, v),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSwatches.map((swatch) {
                  final selected = activeColor.toARGB32() == swatch.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _updateActiveColor(studio, swatch);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.black12,
                          width: selected ? 2.5 : 1.0,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: swatch.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6. Intensity Slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Độ đậm màu nền (Intensity)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    '${(studio.customBgIntensity * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: const Color(0xFF10B981),
                  thumbColor: const Color(0xFF10B981),
                ),
                child: Slider(
                  value: studio.customBgIntensity.clamp(0.04, 0.45),
                  min: 0.04,
                  max: 0.45,
                  onChanged: (val) => studio.setCustomBgIntensity(val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 7. Done Stadium Pill Button
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          color: const Color(0xFF10B981),
          expand: true,
          child: const Text('Hoàn tất & Áp dụng'),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildBlobSelectorButton({
    required int index,
    required String label,
    required Color color,
    required bool isDark,
    required Color titleColor,
    required Color borderColor,
    required Color cardSurface,
  }) {
    final isSelected = _selectedBlobIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedBlobIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF0ED))
                : cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRgbChannelSlider({
    required String label,
    required int value,
    required Color activeColor,
    required Color titleColor,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: activeColor,
              thumbColor: activeColor,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalMeshPreviewPainter extends CustomPainter {
  final Color c1;
  final Color c2;
  final Color c3;
  final double intensity;
  final bool isDark;

  const _ModalMeshPreviewPainter({
    required this.c1,
    required this.c2,
    required this.c3,
    required this.intensity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (intensity * (isDark ? 1.55 : 1.35)).clamp(0.0, 0.75);
    if (alpha <= 0.001) return;

    void drawOrb(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.45),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    drawOrb(
        Offset(size.width * 0.15, size.height * 0.20), size.width * 0.55, c1);
    drawOrb(
        Offset(size.width * 0.85, size.height * 0.35), size.width * 0.55, c2);
    drawOrb(
        Offset(size.width * 0.45, size.height * 0.90), size.width * 0.60, c3);
  }

  @override
  bool shouldRepaint(covariant _ModalMeshPreviewPainter oldDelegate) {
    return oldDelegate.c1 != c1 ||
        oldDelegate.c2 != c2 ||
        oldDelegate.c3 != c3 ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}
