import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../state/theme_studio_controller.dart';
import 'avatar_crop_sheet.dart';
import 'finora_modal_scope.dart';
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

  static String? normalizeMember(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty ||
        clean == 'all' ||
        clean == 'joint' ||
        clean == 'chung' ||
        clean == 'tất cả') {
      return null;
    }
    if (clean == 'husband' ||
        clean == 'chồng' ||
        clean == 'chong' ||
        clean.contains('chồng') ||
        clean.contains('husband')) {
      return 'husband';
    }
    if (clean == 'wife' ||
        clean == 'vợ' ||
        clean == 'vo' ||
        clean.contains('vợ') ||
        clean.contains('wife')) {
      return 'wife';
    }
    return null;
  }

  static Color colorFor(String? member) {
    final norm = normalizeMember(member);
    if (norm == 'husband') return const Color(0xFF0284C7);
    if (norm == 'wife') return const Color(0xFFE11D48);
    return const Color(0xFF059669);
  }

  static IconData defaultIconFor(String? member) {
    final norm = normalizeMember(member);
    if (norm == 'husband') return Icons.face_rounded;
    if (norm == 'wife') return Icons.face_3_rounded;
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
    final normalized = normalizeMember(member);
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
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final member = (currentMember == 'all' ||
            currentMember == null ||
            currentMember == 'joint')
        ? null
        : currentMember;
    final color = FinoraMemberAvatar.colorFor(member);
    final isFiltered = member != null;
    final btnSize = height ?? 36.0;

    final insideModal = FinoraModalScope.isInsideModal(context);
    final fillAlpha = insideModal
        ? 1.0
        : (studio?.glassOpacity ?? 0.92).clamp(0.20, 1.0);
    final Color baseSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color solidBg = (isFiltered
            ? Color.alphaBlend(
                color.withValues(alpha: isDark ? 0.28 : 0.14),
                baseSurface,
              )
            : baseSurface)
        .withValues(alpha: fillAlpha);

    final memberLabel = member == 'husband'
        ? (studio?.husbandDisplayLabel ?? 'Chồng')
        : (member == 'wife'
            ? (studio?.wifeDisplayLabel ?? 'Vợ')
            : 'Tất cả');

    final tooltipLabel =
        'Đang lọc: $memberLabel (Chạm để đổi hoặc tải ảnh avatar)';

    final borderColor = isFiltered
        ? Color.alphaBlend(
            color.withValues(alpha: isDark ? 0.75 : 0.55),
            baseSurface,
          )
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    final pillContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expand ? null : btnSize,
      height: btnSize,
      padding:
          expand ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: solidBg,
        shape: expand ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: expand ? BorderRadius.circular(999) : null,
        border: Border.all(
          color: borderColor,
          width: isFiltered ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFiltered
                ? color.withValues(alpha: isDark ? 0.22 : 0.10)
                : Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expand
          ? Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FinoraMemberAvatar(
                        member: member,
                        size: (btnSize - 12).clamp(20.0, 26.0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            memberLabel,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ],
            )
          : Center(
              child: FinoraMemberAvatar(
                member: member,
                size: btnSize - 4,
                isDark: isDark,
              ),
            ),
    );

    return SizedBox(
      width: expand ? null : btnSize,
      height: btnSize,
      child: Tooltip(
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
            child: pillContent,
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
    builder: (ctx) => _FinoraMemberFilterSheetContent(
      activeTag: active,
      onSelected: onSelected,
      isDark: isDark,
    ),
  );
}

class _FinoraMemberFilterSheetContent extends StatefulWidget {
  final String? activeTag;
  final ValueChanged<String?> onSelected;
  final bool isDark;

  const _FinoraMemberFilterSheetContent({
    required this.activeTag,
    required this.onSelected,
    required this.isDark,
  });

  @override
  State<_FinoraMemberFilterSheetContent> createState() =>
      _FinoraMemberFilterSheetContentState();
}

class _FinoraMemberFilterSheetContentState
    extends State<_FinoraMemberFilterSheetContent> {
  late final TextEditingController _husbandCtrl;
  late final TextEditingController _wifeCtrl;
  final FocusNode _husbandFocus = FocusNode();
  final FocusNode _wifeFocus = FocusNode();
  ThemeStudioController? _studioRef;
  bool _showCustomizeDrawer = false;

  @override
  void initState() {
    super.initState();
    _studioRef = Provider.of<ThemeStudioController?>(context, listen: false);
    _husbandCtrl = TextEditingController(text: _studioRef?.husbandName ?? '');
    _wifeCtrl = TextEditingController(text: _studioRef?.wifeName ?? '');
    _husbandFocus.addListener(_onFocusChange);
    _wifeFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_husbandFocus.hasFocus && !_wifeFocus.hasFocus && mounted) {
      _studioRef?.notifyMemberNamesChanged();
    }
  }

  @override
  void dispose() {
    _husbandFocus.removeListener(_onFocusChange);
    _wifeFocus.removeListener(_onFocusChange);
    final studio = _studioRef;
    if (studio != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        studio.notifyMemberNamesChanged();
      });
    }
    _husbandFocus.dispose();
    _wifeFocus.dispose();
    _husbandCtrl.dispose();
    _wifeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final active = widget.activeTag;
    final liveStudio =
        Provider.of<ThemeStudioController?>(context, listen: true);
    _studioRef = liveStudio;
    final primaryColor =
        liveStudio?.resolvedPrimary ?? const Color(0xFF059669);
    final secondaryColor =
        liveStudio?.resolvedSecondary ?? const Color(0xFF0284C7);

    if (liveStudio != null) {
      if (!_husbandFocus.hasFocus &&
          _husbandCtrl.text != liveStudio.husbandName) {
        _husbandCtrl.text = liveStudio.husbandName;
      }
      if (!_wifeFocus.hasFocus && _wifeCtrl.text != liveStudio.wifeName) {
        _wifeCtrl.text = liveStudio.wifeName;
      }
    }

    final husbandTitle = liveStudio?.husbandDisplayLabel ?? 'Chồng';
    final wifeTitle = liveStudio?.wifeDisplayLabel ?? 'Vợ';

    return GlassBottomSheet(
      showHandle: true,
      radius: 28,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.paddingOf(context).bottom +
              16,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Compact Header + "Tùy chỉnh" Pill Button
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành viên gia đình',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Chạm thẻ để lọc · Nhấn icon máy ảnh để đổi avatar',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (liveStudio != null)
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _showCustomizeDrawer = !_showCustomizeDrawer;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _showCustomizeDrawer
                              ? primaryColor
                              : primaryColor.withValues(
                                  alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showCustomizeDrawer
                                  ? Icons.expand_less_rounded
                                  : Icons.edit_note_rounded,
                              size: 14,
                              color: _showCustomizeDrawer
                                  ? Colors.white
                                  : primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đổi tên',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _showCustomizeDrawer
                                    ? Colors.white
                                    : primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Sleek 3-Column Bento Grid: [ Tất cả ] [ Chồng ] [ Vợ ]
              Row(
                children: [
                  Expanded(
                    child: _buildBentoMemberCard(
                      ctx: context,
                      tag: null,
                      title: 'Tất cả',
                      roleBadge: 'Chung',
                      color: primaryColor,
                      isSelected: active == null,
                      isDark: isDark,
                      onSelected: widget.onSelected,
                      onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                        context,
                        role: 'joint',
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoMemberCard(
                      ctx: context,
                      tag: 'husband',
                      title: husbandTitle,
                      roleBadge: 'Chồng',
                      color: const Color(0xFF0284C7),
                      isSelected: active == 'husband',
                      isDark: isDark,
                      onSelected: widget.onSelected,
                      onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                        context,
                        role: 'husband',
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoMemberCard(
                      ctx: context,
                      tag: 'wife',
                      title: wifeTitle,
                      roleBadge: 'Vợ',
                      color: const Color(0xFFE11D48),
                      isSelected: active == 'wife',
                      isDark: isDark,
                      onSelected: widget.onSelected,
                      onEditAvatar: () => showFinoraMemberAvatarPickerSheet(
                        context,
                        role: 'wife',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Collapsible Inline Name Editor Drawer (Only shown when "Đổi tên" is tapped)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: (_showCustomizeDrawer && liveStudio != null)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Tên hiển thị của Vợ & Chồng',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      FocusScope.of(context).unfocus();
                                      liveStudio.setHusbandName(
                                        _husbandCtrl.text,
                                        notify: false,
                                      );
                                      liveStudio.setWifeName(
                                        _wifeCtrl.text,
                                        notify: true,
                                      );
                                      setState(() {
                                        _showCustomizeDrawer = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Lưu tên',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _husbandCtrl,
                                      focusNode: _husbandFocus,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (v) {
                                        liveStudio.setHusbandName(
                                          v,
                                          notify: false,
                                        );
                                        setState(() {});
                                      },
                                      onSubmitted: (v) {
                                        liveStudio.setHusbandName(
                                          v,
                                          notify: true,
                                        );
                                      },
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: 'Tên Chồng (VD: Minh)',
                                        hintStyle: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(7),
                                          child: FinoraMemberAvatar(
                                            member: 'husband',
                                            size: 18,
                                            isDark: isDark,
                                          ),
                                        ),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 9),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _wifeCtrl,
                                      focusNode: _wifeFocus,
                                      textInputAction: TextInputAction.done,
                                      onChanged: (v) {
                                        liveStudio.setWifeName(
                                          v,
                                          notify: false,
                                        );
                                        setState(() {});
                                      },
                                      onSubmitted: (v) {
                                        liveStudio.setWifeName(
                                          v,
                                          notify: true,
                                        );
                                      },
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: 'Tên Vợ (VD: Lan)',
                                        hintStyle: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(7),
                                          child: FinoraMemberAvatar(
                                            member: 'wife',
                                            size: 18,
                                            isDark: isDark,
                                          ),
                                        ),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 9),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBentoMemberCard({
  required BuildContext ctx,
  required String? tag,
  required String title,
  required String roleBadge,
  required Color color,
  required bool isSelected,
  required bool isDark,
  required ValueChanged<String?> onSelected,
  VoidCallback? onEditAvatar,
}) {
  final baseSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(tag);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(
                  color.withValues(alpha: isDark ? 0.24 : 0.12),
                  baseSurface,
                )
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.24 : 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelected)
              Positioned(
                top: -2,
                right: 2,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onEditAvatar == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onEditAvatar();
                        },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FinoraMemberAvatar(
                        member: tag,
                        size: 50,
                        isDark: isDark,
                        showRing: true,
                      ),
                      if (onEditAvatar != null)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: baseSurface,
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 10.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Future<void> saveCroppedDataUri(
    BuildContext sheetCtx,
    String targetRole,
    String dataUri,
  ) async {
    final roleLabel = labelForRole(targetRole);
    final accent = accentForRole(targetRole);
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
        content: Text('Đã cập nhật & đồng bộ ảnh đại diện $roleLabel!'),
        backgroundColor: accent,
      ),
    );
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
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 92,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      if (!sheetCtx.mounted) return;
      final croppedDataUri = await showFinoraAvatarCropSheet(
        context: sheetCtx,
        imageBytes: bytes,
        roleLabel: roleLabel,
        accentColor: accent,
      );
      if (croppedDataUri == null || !sheetCtx.mounted) return;
      await saveCroppedDataUri(sheetCtx, targetRole, croppedDataUri);
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

  Future<void> recropExistingPhoto(
    BuildContext sheetCtx,
    String targetRole,
    String rawAvatar,
  ) async {
    final bytes = tryDecodeAvatarDataUri(rawAvatar);
    if (bytes == null) return;
    final croppedDataUri = await showFinoraAvatarCropSheet(
      context: sheetCtx,
      imageBytes: bytes,
      roleLabel: labelForRole(targetRole),
      accentColor: accentForRole(targetRole),
    );
    if (croppedDataUri == null || !sheetCtx.mounted) return;
    await saveCroppedDataUri(sheetCtx, targetRole, croppedDataUri);
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
                            'joint', 'Chung', Icons.people_alt_rounded),
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
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Chọn ảnh',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
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
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Chụp ảnh',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
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
                  if (tryDecodeAvatarDataUri(currentVal) != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => recropExistingPhoto(
                            stCtx, activeRole, currentVal!),
                        icon: Icon(Icons.crop_rotate_rounded,
                            size: 18, color: accent),
                        label: Text(
                          'Cắt / chỉnh sửa ảnh hiện tại',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.38),
                            width: 1.1,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
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
