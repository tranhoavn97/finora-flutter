import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/finora_icon_action.dart';
import 'finora_v8_tokens.dart';

class FinoraSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Color>? colors;
  final List<IconData>? icons;
  final bool showIcons;
  final bool compact;
  final double? height;
  final double? fontSize;

  const FinoraSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
    this.icons,
    this.showIcons = false,
    this.compact = false,
    this.height,
    this.fontSize,
  }) : assert(labels.length > 1);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);
    final active = (colors != null && safeIndex < colors!.length)
        ? colors![safeIndex]
        : (dark ? const Color(0xFF64748B) : const Color(0xFF475569));
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
                padding: const EdgeInsets.all(FinoraV8Space.x1),
                decoration: BoxDecoration(
                  color:
                      dark ? const Color(0xFF202D39) : const Color(0xFFEDF3F1),
                  borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFDDE6E2),
                    width: 1.0,
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
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
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
                                        horizontal: 4),
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
                                              size: (labels.length >= 5 ? 12 : 14).toDouble(),
                                              color: fgColor,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(labels[index], maxLines: 1),
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
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF202D39) : const Color(0xFFEDF3F1),
        borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDDE6E2),
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
            final activeColor =
                dark ? const Color(0xFF64748B) : const Color(0xFF475569);
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
  final EdgeInsetsGeometry? padding;

  const FinoraFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = FinoraV8Colors.brand,
    this.icon,
    this.leading,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                  ? color
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
                        color: color.withValues(alpha: dark ? 0.35 : 0.22),
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
