import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_widgets.dart';

/// Unified Member Filter UI/UX for Finora
/// Standardized 32px capsule pill + Apple Glass Bottom Sheet across all pages.
class FinoraUnifiedMemberPill extends StatelessWidget {
  final String? currentMember; // null or 'all' = All, 'husband' = Husband, 'wife' = Wife
  final ValueChanged<String?> onSelected;
  final bool isDark;

  const FinoraUnifiedMemberPill({
    super.key,
    required this.currentMember,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final member = (currentMember == 'all' || currentMember == null)
        ? null
        : currentMember;
    final label = member == 'husband'
        ? 'Chồng'
        : (member == 'wife' ? 'Vợ' : 'Tất cả');
    final icon = member == 'husband'
        ? Icons.face_rounded
        : (member == 'wife' ? Icons.face_3_rounded : Icons.people_alt_rounded);
    final color = member == 'husband'
        ? const Color(0xFF38BDF8)
        : (member == 'wife'
            ? const Color(0xFFF472B6)
            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)));

    final isFiltered = member != null;

    return Material(
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
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 32,
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFiltered
                ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isFiltered
                  ? color.withValues(alpha: isDark ? 0.60 : 0.40)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.24)
                      : const Color(0xFFCBD5E1)),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 13.5, color: color),
              const SizedBox(width: 4.5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: (isDark ? Colors.white : const Color(0xFF0F172A))
                    .withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized Modal Sheet for Member Filter
void showFinoraMemberFilterSheet(
  BuildContext context, {
  required String? currentTag,
  required ValueChanged<String?> onSelected,
  required bool isDark,
}) {
  final active = (currentTag == 'all' || currentTag == null) ? null : currentTag;

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
            12,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Phân loại theo thành viên',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _buildOption(
                ctx: ctx,
                tag: null,
                title: 'Tất cả (Cả hai vợ chồng)',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFFFBBF24),
                isSelected: active == null,
                isDark: isDark,
                onSelected: onSelected,
              ),
              const SizedBox(height: 8),
              _buildOption(
                ctx: ctx,
                tag: 'husband',
                title: 'Chỉ riêng Chồng',
                icon: Icons.face_rounded,
                color: const Color(0xFF38BDF8),
                isSelected: active == 'husband',
                isDark: isDark,
                onSelected: onSelected,
              ),
              const SizedBox(height: 8),
              _buildOption(
                ctx: ctx,
                tag: 'wife',
                title: 'Chỉ riêng Vợ',
                icon: Icons.face_3_rounded,
                color: const Color(0xFFF472B6),
                isSelected: active == 'wife',
                isDark: isDark,
                onSelected: onSelected,
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
  required IconData icon,
  required Color color,
  required bool isSelected,
  required bool isDark,
  required ValueChanged<String?> onSelected,
}) {
  return InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      onSelected(tag);
      Navigator.pop(ctx);
    },
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: isDark ? 0.20 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? color
              : (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06)),
          width: isSelected ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, size: 20, color: color),
        ],
      ),
    ),
  );
}
