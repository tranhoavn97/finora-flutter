import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../state/theme_studio_controller.dart';
import 'finora_notice.dart';
import 'glass_widgets.dart';

/// Renders the circular avatar or icon for Husband ('husband'), Wife ('wife'), or All (null/'all').
class FinoraMemberAvatar extends StatelessWidget {
  final String? member; // 'husband', 'wife', or null/'all'
  final double size;
  final bool? isDark;
  final bool showRing;
  final ThemeStudioController? studio;

  const FinoraMemberAvatar({
    super.key,
    String? member,
    String? role,
    String? memberKey,
    this.size = 28,
    this.isDark,
    this.showRing = false,
    this.studio,
  }) : member = member ?? role ?? memberKey;

  static Color colorFor(String? member) {
    if (member == 'husband') return const Color(0xFF0284C7);
    if (member == 'wife') return const Color(0xFFE11D48);
    return const Color(0xFF059669);
  }

  static IconData defaultIconFor(String? member) {
    if (member == 'husband') return Icons.face_rounded;
    if (member == 'wife') return Icons.face_3_rounded;
    return Icons.people_alt_rounded;
  }

  Widget _buildSingleAvatarContent(
    String? rawAvatar,
    Color accent,
    IconData fallbackIcon,
    double avatarSize,
  ) {
    if (rawAvatar != null && rawAvatar.trim().isNotEmpty) {
      final clean = rawAvatar.trim();
      if (clean.startsWith('data:image/')) {
        final commaIdx = clean.indexOf(',');
        if (commaIdx != -1) {
          try {
            final bytes = base64Decode(clean.substring(commaIdx + 1));
            return ClipOval(
              child: Image.memory(
                bytes,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, size: avatarSize * 0.56, color: accent),
              ),
            );
          } catch (_) {}
        }
      } else if (clean.startsWith('emoji:')) {
        final emoji = clean.substring('emoji:'.length).trim();
        return Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: avatarSize * 0.56,
              height: 1.0,
            ),
          ),
        );
      } else if (clean.startsWith('asset:') || clean.startsWith('assets/')) {
        final assetPath = clean.startsWith('asset:')
            ? clean.substring('asset:'.length).trim()
            : clean;
        return ClipOval(
          child: Image.asset(
            assetPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: avatarSize * 0.56, color: accent),
          ),
        );
      } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            clean,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: avatarSize * 0.56, color: accent),
          ),
        );
      }
    }

    return Icon(
      fallbackIcon,
      size: avatarSize * 0.56,
      color: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStudio =
        studio ?? Provider.of<ThemeStudioController?>(context, listen: true);
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final normalized =
        (member == 'all' || member == null || member == 'joint') ? null : member;
    final accent = colorFor(normalized);
    final baseSurface = dark ? const Color(0xFF1E293B) : Colors.white;
    final badgeBg = Color.alphaBlend(
      accent.withValues(alpha: dark ? 0.30 : 0.16),
      baseSurface,
    );

    final husbandRaw = effectiveStudio?.husbandAvatar;
    final wifeRaw = effectiveStudio?.wifeAvatar;
    final jointRaw = effectiveStudio?.jointFamilyAvatar;

    if (normalized == null && jointRaw != null && jointRaw.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: badgeBg,
          border: showRing
              ? Border.all(
                  color: accent.withValues(alpha: dark ? 0.75 : 0.55),
                  width: 1.4,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: _buildSingleAvatarContent(
          jointRaw,
          accent,
          Icons.people_alt_rounded,
          size,
        ),
      );
    }

    if (normalized == null &&
        ((husbandRaw != null && husbandRaw.isNotEmpty) ||
            (wifeRaw != null && wifeRaw.isNotEmpty))) {
      // Render overlapping dual mini-avatars when "All" is active and custom avatars exist
      final miniSize = size * 0.68;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: (size - miniSize) / 2,
              child: Container(
                width: miniSize,
                height: miniSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    const Color(0xFF0284C7).withValues(alpha: 0.25),
                    baseSurface,
                  ),
                  border: Border.all(color: baseSurface, width: 1.2),
                ),
                child: _buildSingleAvatarContent(
                  husbandRaw,
                  const Color(0xFF0284C7),
                  Icons.face_rounded,
                  miniSize,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: (size - miniSize) / 2,
              child: Container(
                width: miniSize,
                height: miniSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    const Color(0xFFE11D48).withValues(alpha: 0.25),
                    baseSurface,
                  ),
                  border: Border.all(color: baseSurface, width: 1.2),
                ),
                child: _buildSingleAvatarContent(
                  wifeRaw,
                  const Color(0xFFE11D48),
                  Icons.face_3_rounded,
                  miniSize,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final rawAvatar = normalized == 'husband'
        ? husbandRaw
        : (normalized == 'wife' ? wifeRaw : null);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badgeBg,
        border: showRing
            ? Border.all(
                color: accent.withValues(alpha: dark ? 0.75 : 0.55),
                width: 1.4,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: _buildSingleAvatarContent(
        rawAvatar,
        accent,
        defaultIconFor(normalized),
        size,
      ),
    );
  }
}

/// Unified Member Filter UI/UX for Finora
/// Renders ONLY the circular avatar/icon of that person (no text label on the button itself)
/// and opens the Luxury Glass Member Filter & Avatar Upload Sheet on tap.
class FinoraUnifiedMemberPill extends StatelessWidget {
  final String?
      currentMember; // null or 'all' = All, 'husband' = Husband, 'wife' = Wife
  final ValueChanged<String?> onSelected;
  final bool isDark;
  final double? height;
  final bool expand;

  const FinoraUnifiedMemberPill({
    super.key,
    required this.currentMember,
    required this.onSelected,
    required this.isDark,
    this.height,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final member = (currentMember == 'all' ||
            currentMember == null ||
            currentMember == 'joint')
        ? null
        : currentMember;
    final color = FinoraMemberAvatar.colorFor(member);
    final isFiltered = member != null;
    final btnSize = height ?? 38.0;

    // 100% SOLID OPAQUE background (never transparent)
    final Color baseSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color solidBg = isFiltered
        ? Color.alphaBlend(
            color.withValues(alpha: isDark ? 0.28 : 0.14),
            baseSurface,
          )
        : baseSurface;

    final shortLabel = member == 'husband'
        ? 'Chồng'
        : (member == 'wife' ? 'Vợ' : 'Tất cả');
    final tooltipLabel = member == 'husband'
        ? 'Đang lọc: Chồng (Chạm để đổi hoặc tải ảnh avatar)'
        : (member == 'wife'
            ? 'Đang lọc: Vợ (Chạm để đổi hoặc tải ảnh avatar)'
            : 'Đang lọc: Tất cả thành viên (Chạm để chọn Vợ/Chồng)');

    return Tooltip(
      message: tooltipLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            showFinoraMemberFilterSheet(
              context,
              currentTag: member,
              onSelected: onSelected,
              isDark: isDark,
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: solidBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isFiltered
                    ? Color.alphaBlend(
                        color.withValues(alpha: isDark ? 0.75 : 0.55),
                        baseSurface,
                      )
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
                width: isFiltered ? 1.5 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFiltered
                      ? color.withValues(alpha: isDark ? 0.28 : 0.14)
                      : Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                FinoraMemberAvatar(
                  member: member,
                  size: btnSize - 6,
                  isDark: isDark,
                ),
                SizedBox(
                  width: 1,
                  height: 1,
                  child: OverflowBox(
                    maxWidth: 90,
                    maxHeight: 20,
                    child: Opacity(
                      opacity: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(shortLabel, maxLines: 1),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 1),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: baseSurface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized Modal Sheet for Member Filter + Husband/Wife Avatar Upload
void showFinoraMemberFilterSheet(
  BuildContext context, {
  required String? currentTag,
  required ValueChanged<String?> onSelected,
  required bool isDark,
}) {
  final active =
      (currentTag == 'all' || currentTag == null || currentTag == 'joint')
          ? null
          : currentTag;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return GlassBottomSheet(
        showHandle: true,
        radius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phân loại theo thành viên',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chọn người hiển thị hoặc tải ảnh đại diện cho Vợ / Chồng',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOption(
                ctx: ctx,
                tag: null,
                title: 'Tất cả (Vợ & Chồng · Ảnh chung)',
                subtitle: 'Tổng hợp toàn bộ ví, tài sản và thu chi gia đình',
                color: const Color(0xFF059669),
                isSelected: active == null,
                isDark: isDark,
                onSelected: onSelected,
                onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                  ctx,
                  role: 'joint',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 10),
              _buildOption(
                ctx: ctx,
                tag: 'husband',
                title: 'Chỉ riêng Chồng',
                subtitle: 'Chỉ lọc dữ liệu của Chồng',
                color: const Color(0xFF0284C7),
                isSelected: active == 'husband',
                isDark: isDark,
                onSelected: onSelected,
                onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                  ctx,
                  role: 'husband',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 10),
              _buildOption(
                ctx: ctx,
                tag: 'wife',
                title: 'Chỉ riêng Vợ',
                subtitle: 'Chỉ lọc dữ liệu của Vợ',
                color: const Color(0xFFE11D48),
                isSelected: active == 'wife',
                isDark: isDark,
                onSelected: onSelected,
                onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                  ctx,
                  role: 'wife',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOption({
  required BuildContext ctx,
  required String? tag,
  required String title,
  required String subtitle,
  required Color color,
  required bool isSelected,
  required bool isDark,
  required ValueChanged<String?> onSelected,
  VoidCallback? onEditAvatar,
}) {
  final baseSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
  return InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      onSelected(tag);
      Navigator.pop(ctx);
    },
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Color.alphaBlend(
                color.withValues(alpha: isDark ? 0.24 : 0.12), baseSurface)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FinoraMemberAvatar(
                  member: tag,
                  size: 44,
                  isDark: isDark,
                  showRing: true,
                ),
                if (onEditAvatar != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: baseSurface, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (onEditAvatar != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onEditAvatar();
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: color.withValues(alpha: 0.40),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_rounded, size: 12.5, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'Up ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ],
      ),
    ),
  );
}

/// Opens the Avatar & Icon Upload Picker Sheet for Joint ('joint'), Husband ('husband') or Wife ('wife')
Future<void> showFinoraMemberAvatarPickerSheet(
  BuildContext context, {
  required String role, // 'joint', 'husband', or 'wife'
  required bool isDark,
}) async {
  String activeRole = (role == 'all' || role == 'joint')
      ? 'joint'
      : (role == 'wife' ? 'wife' : 'husband');

  List<String> presetsForRole(String r) {
    if (r == 'joint') {
      return const [
        'emoji:💑',
        'emoji:👩‍❤️‍👨',
        'emoji:👨‍👩‍👧‍👦',
        'emoji:🏡',
        'emoji:💞',
        'emoji:🥂',
        'emoji:💎',
        'emoji:🐉',
        'asset:assets/images/mascot/app_icon.png',
      ];
    }
    if (r == 'husband') {
      return const [
        'emoji:👨💼',
        'emoji:🤴',
        'emoji:🧔',
        'emoji:🧑💻',
        'emoji:🕶️',
        'emoji:🦁',
        'emoji:🐉',
        'emoji:⚡',
        'asset:assets/images/mascot/app_icon.png',
      ];
    }
    return const [
      'emoji:👩💼',
      'emoji:👸',
      'emoji:👩🎨',
      'emoji:🧚♀️',
      'emoji:💎',
      'emoji:🦊',
      'emoji:🌸',
      'emoji:🦋',
      'asset:assets/images/mascot/app_icon.png',
    ];
  }

  String labelForRole(String r) {
    if (r == 'joint') return 'Chung (Vợ & Chồng)';
    if (r == 'husband') return 'Chồng';
    return 'Vợ';
  }

  Color accentForRole(String r) {
    if (r == 'joint') return const Color(0xFF059669);
    if (r == 'husband') return const Color(0xFF0284C7);
    return const Color(0xFFE11D48);
  }

  Future<void> pickPhoto(
    BuildContext sheetCtx,
    ImageSource source,
    String targetRole,
  ) async {
    final roleLabel = labelForRole(targetRole);
    final accent = accentForRole(targetRole);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        maxWidth: 360,
        maxHeight: 360,
        imageQuality: 84,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (!sheetCtx.mounted) return;
      final studio = sheetCtx.read<ThemeStudioController>();
      if (targetRole == 'joint') {
        await studio.setJointFamilyAvatar(dataUri);
      } else if (targetRole == 'husband') {
        await studio.setHusbandAvatar(dataUri);
      } else {
        await studio.setWifeAvatar(dataUri);
      }
      if (!sheetCtx.mounted) return;
      Navigator.pop(sheetCtx);
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật ảnh đại diện $roleLabel!'),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      if (!sheetCtx.mounted) return;
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải ảnh: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (stCtx, setSheetState) {
          final studio = stCtx.watch<ThemeStudioController>();
          final accent = accentForRole(activeRole);
          final roleLabel = labelForRole(activeRole);
          final presets = presetsForRole(activeRole);
          final currentVal = activeRole == 'joint'
              ? studio.jointFamilyAvatar
              : (activeRole == 'husband'
                  ? studio.husbandAvatar
                  : studio.wifeAvatar);

          Widget buildRoleTab(String tabRole, String title, IconData icon) {
            final selected = activeRole == tabRole;
            final tabColor = accentForRole(tabRole);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setSheetState(() => activeRole = tabRole);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? tabColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: tabColor.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: selected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return GlassBottomSheet(
            showHandle: true,
            radius: 28,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.paddingOf(stCtx).bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        buildRoleTab(
                            'joint', 'Ảnh Chung', Icons.people_alt_rounded),
                        buildRoleTab('husband', 'Chồng', Icons.face_rounded),
                        buildRoleTab('wife', 'Vợ', Icons.face_3_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FinoraMemberAvatar(
                        member: activeRole == 'joint' ? null : activeRole,
                        size: 50,
                        isDark: isDark,
                        showRing: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avatar & Icon $roleLabel',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeRole == 'joint'
                                  ? 'Hiển thị ở nút "Tất cả (Vợ & Chồng)" trên mọi trang'
                                  : 'Hiển thị trên nút lọc & danh sách giao dịch',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentVal != null && currentVal.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            if (activeRole == 'joint') {
                              studio.setJointFamilyAvatar(null);
                            } else if (activeRole == 'husband') {
                              studio.setHusbandAvatar(null);
                            } else {
                              studio.setWifeAvatar(null);
                            }
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: const Text('Mặc định'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE11D48),
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              pickPhoto(stCtx, ImageSource.gallery, activeRole),
                          icon:
                              const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text(
                            'Tải ảnh từ máy',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              pickPhoto(stCtx, ImageSource.camera, activeRole),
                          icon: Icon(Icons.camera_alt_rounded,
                              size: 18, color: accent),
                          label: Text(
                            'Chụp ảnh mới',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                              color: accent.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'HOẶC CHỌN ICON AVATAR MẪU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: presets.map((preset) {
                      final selected = currentVal == preset;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (activeRole == 'joint') {
                            studio.setJointFamilyAvatar(preset);
                          } else if (activeRole == 'husband') {
                            studio.setHusbandAvatar(preset);
                          } else {
                            studio.setWifeAvatar(preset);
                          }
                          Navigator.pop(stCtx);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? accent.withValues(alpha: isDark ? 0.28 : 0.16)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9)),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              width: selected ? 2.0 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: preset.startsWith('emoji:')
                              ? Text(
                                  preset.substring('emoji:'.length),
                                  style: const TextStyle(fontSize: 24),
                                )
                              : ClipOval(
                                  child: Image.asset(
                                    preset.substring('asset:'.length),
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
