import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../state/theme_studio_controller.dart';
import '../../widgets/finora_icon_action.dart';
import '../../widgets/finora_modal_scope.dart';
import 'finora_v8_tokens.dart';

bool _isDefaultEmeraldColor(Color c) {
  final v = c.toARGB32();
  return v == 0xFF00866A ||
      v == 0xFF0F6E56 ||
      v == 0xFF10B981 ||
      v == 0xFF059669 ||
      v == 0xFF007859 ||
      v == 0xFF047857;
}

class FinoraSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Color>? colors;
  final List<IconData>? icons;
  final List<int>? counts;
  final bool showIcons;
  final bool compact;
  final double? height;
  final double? fontSize;
  final bool transparentBackground;

  const FinoraSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
    this.icons,
    this.counts,
    this.showIcons = false,
    this.compact = false,
    this.height,
    this.fontSize,
    this.transparentBackground = false,
  }) : assert(labels.length > 1);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {}
    final primary =
        studio?.resolvedPrimary ?? Theme.of(context).colorScheme.primary;
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);
    final Color rawActive = (colors != null && safeIndex < colors!.length)
        ? colors![safeIndex]
        : primary;
    // Sync default emerald tab colors to the user's selected system primary color
    final bool allEmerald =
        colors != null && colors!.every(_isDefaultEmeraldColor);
    final Color active = (colors == null ||
            allEmerald ||
            (safeIndex == 0 && _isDefaultEmeraldColor(rawActive)))
        ? primary
        : rawActive;
    final x = -1.0 + (2 * safeIndex / (labels.length - 1));
    final controlHeight = (height ?? 40).clamp(34.0, 48.0);
    final double effectiveFontSize = fontSize ?? 11.5;

    return SizedBox(
      height: controlHeight,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                if (totalWidth <= 0) return;
                final tabWidth = totalWidth / labels.length;
                final targetIndex = (details.localPosition.dx / tabWidth)
                    .floor()
                    .clamp(0, labels.length - 1);
                if (targetIndex != safeIndex) {
                  HapticFeedback.selectionClick();
                  onChanged(targetIndex);
                }
              },
              child: Container(
                height: controlHeight,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: transparentBackground
                      ? Colors.transparent
                      : Color.alphaBlend(
                          primary.withValues(alpha: dark ? 0.10 : 0.06),
                          dark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                        ).withValues(
                          alpha: FinoraModalScope.isInsideModal(context)
                              ? 1.0
                              : (studio?.glassOpacity ?? 0.92).clamp(0.18, 0.98),
                        ),
                  borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                  border: transparentBackground
                      ? null
                      : Border.all(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.09)
                              : primary.withValues(alpha: 0.14),
                          width: 0.8,
                        ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(x, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / labels.length,
                        heightFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: active,
                              borderRadius:
                                  BorderRadius.circular(FinoraV8Radius.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: active.withValues(
                                      alpha: dark ? 0.38 : 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(labels.length, (index) {
                        final selected = index == safeIndex;
                        final fgColor = selected
                            ? Colors.white
                            : (dark
                                ? FinoraV8Colors.darkMuted
                                : FinoraV8Colors.lightMuted);
                        return Expanded(
                          child: Semantics(
                            button: true,
                            selected: selected,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(FinoraV8Radius.pill),
                              onTap: () {
                                if (!selected) HapticFeedback.selectionClick();
                                onChanged(index);
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: FinoraV8Motion.fast,
                                  curve: FinoraV8Motion.fastCurve,
                                  style: (labels.length >= 5
                                          ? FinoraV8Type.caption
                                          : FinoraV8Type.label)
                                      .copyWith(
                                    fontSize: effectiveFontSize,
                                    letterSpacing: -0.2,
                                    color: fgColor,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (showIcons &&
                                              icons != null &&
                                              index < icons!.length) ...[
                                            Icon(
                                              icons![index],
                                              size: (labels.length >= 5
                                                      ? 12
                                                      : 13.5)
                                                  .toDouble(),
                                              color: fgColor,
                                            ),
                                            const SizedBox(width: 3),
                                          ],
                                          Text(labels[index], maxLines: 1),
                                          if (counts != null &&
                                              index < counts!.length) ...[
                                            const SizedBox(width: 5),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.5,
                                                      vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.24)
                                                    : (dark
                                                        ? Colors.white
                                                            .withValues(
                                                                alpha: 0.10)
                                                        : active.withValues(
                                                            alpha: 0.12)),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${counts![index]}',
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontFamily: 'BeVietnamPro',
                                                  fontSize: (effectiveFontSize -
                                                          1.5)
                                                      .clamp(9.0, 12.0),
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.0,
                                                  color: selected
                                                      ? Colors.white
                                                      : (dark
                                                          ? Colors.white
                                                              .withValues(
                                                                  alpha: 0.85)
                                                          : active),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A scrollable segmented control matching Category pill tab style for many options.
class FinoraScrollableSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Color>? colors;
  final List<dynamic>? icons; // Can be IconData, String (emoji), or Widget
  final double height;

  const FinoraScrollableSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
    this.icons,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {}
    final primary =
        studio?.resolvedPrimary ?? Theme.of(context).colorScheme.primary;
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          primary.withValues(alpha: dark ? 0.10 : 0.06),
          dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.09)
              : primary.withValues(alpha: 0.14),
          width: 1.0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (index) {
            final selected = index == safeIndex;
            final rawColor = (colors != null && index < colors!.length)
                ? colors![index]
                : primary;
            final activeColor =
                (colors == null || _isDefaultEmeraldColor(rawColor))
                    ? primary
                    : rawColor;
            final fgColor = selected
                ? Colors.white
                : (dark ? FinoraV8Colors.darkMuted : FinoraV8Colors.lightMuted);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                  onTap: () {
                    if (!selected) HapticFeedback.selectionClick();
                    onChanged(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(
                                    alpha: dark ? 0.35 : 0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              color: fgColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class FinoraFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final Widget? leading;
  final int? count;
  final EdgeInsetsGeometry? padding;

  const FinoraFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = FinoraV8Colors.brand,
    this.icon,
    this.leading,
    this.count,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {}
    final effectiveColor = _isDefaultEmeraldColor(color)
        ? (studio?.resolvedPrimary ?? color)
        : color;
    final foreground = selected
        ? Colors.white
        : (dark ? FinoraV8Colors.darkMuted : FinoraV8Colors.neutral);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: SizedBox(
        height: FinoraV8Metrics.minTouchTarget,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? effectiveColor
                  : (dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      .withValues(alpha: dark ? 0.72 : 0.88),
              borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : (dark ? Colors.white : Colors.black)
                        .withValues(alpha: dark ? 0.10 : 0.08),
                width: 0.85,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(
                            alpha: dark ? 0.35 : 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onTap?.call();
                      },
                borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                child: AnimatedContainer(
                  duration: FinoraV8Motion.fast,
                  curve: FinoraV8Motion.fastCurve,
                  height: FinoraV8Metrics.compactControl,
                  padding: padding ??
                      const EdgeInsets.symmetric(horizontal: FinoraV8Space.x3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        SizedBox.square(
                          dimension: 20,
                          child: IconTheme.merge(
                            data: IconThemeData(color: foreground, size: 16),
                            child: leading!,
                          ),
                        ),
                        const SizedBox(width: FinoraV8Space.x2),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 16, color: foreground),
                        const SizedBox(width: FinoraV8Space.x2),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FinoraV8Type.label.copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.24)
                                : effectiveColor.withValues(
                                    alpha: dark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              color: selected ? Colors.white : effectiveColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinoraPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const FinoraPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(FinoraV8Metrics.pageHeader);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? FinoraV8Colors.darkText : FinoraV8Colors.lightText;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: FinoraV8Metrics.pageHeader,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FinoraV8Space.x2),
          child: Row(
            children: [
              if (onBack != null)
                FinoraBackButton(onPressed: onBack)
              else
                const SizedBox(width: 4),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: FinoraV8Type.pageTitle.copyWith(color: textColor),
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
