import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'finora_v8_tokens.dart';

class FinoraSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Color>? colors;
  final bool compact;
  final double? height;

  const FinoraSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
    this.compact = false,
    this.height,
  }) : assert(labels.length > 1);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);
    final active = colors == null
        ? FinoraV8Colors.brand
        : colors![safeIndex.clamp(0, colors!.length - 1)];
    final x = -1.0 + (2 * safeIndex / (labels.length - 1));
    final controlHeight = height ??
        (compact
            ? FinoraV8Metrics.segmentedCompact
            : FinoraV8Metrics.segmented);

    return SizedBox(
      height: controlHeight < FinoraV8Metrics.minTouchTarget
          ? FinoraV8Metrics.minTouchTarget
          : controlHeight,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: controlHeight,
              padding: const EdgeInsets.all(FinoraV8Space.x1),
              decoration: BoxDecoration(
                color: dark
                    ? FinoraV8Colors.darkTrack.withValues(alpha: .86)
                    : FinoraV8Colors.lightTrack.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: .12)
                      : Colors.white.withValues(alpha: .94),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: FinoraV8Motion.spring,
                    curve: FinoraV8Motion.springCurve,
                    alignment: Alignment(x, 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / labels.length,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: active,
                          borderRadius:
                              BorderRadius.circular(FinoraV8Radius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: active.withValues(alpha: .26),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(labels.length, (index) {
                      final selected = index == safeIndex;
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
                                style: FinoraV8Type.label.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : (dark
                                          ? FinoraV8Colors.darkMuted
                                          : FinoraV8Colors.lightMuted),
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(labels[index], maxLines: 1),
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
          ),
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
        ? color
        : (dark ? FinoraV8Colors.darkMuted : FinoraV8Colors.neutral);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: SizedBox(
        height: FinoraV8Metrics.minTouchTarget,
        child: Center(
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
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: dark ? .24 : .12)
                      : (dark
                          ? Colors.white.withValues(alpha: .07)
                          : Colors.white.withValues(alpha: .82)),
                  borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: .52)
                        : (dark
                            ? Colors.white.withValues(alpha: .14)
                            : FinoraV8Colors.lightBorder),
                  ),
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
              children: [
                if (onBack != null)
                  SizedBox.square(
                    dimension: FinoraV8Metrics.minTouchTarget,
                    child: IconButton.filled(
                      tooltip: 'Quay lại',
                      onPressed: onBack,
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        fixedSize:
                            const Size.square(FinoraV8Metrics.iconButton),
                        backgroundColor: dark
                            ? Colors.white.withValues(alpha: .08)
                            : FinoraV8Colors.brand.withValues(alpha: .09),
                        foregroundColor:
                            dark ? Colors.white : FinoraV8Colors.brand,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    ),
                  )
                else
                  const SizedBox(width: FinoraV8Space.x2),
                const SizedBox(width: FinoraV8Space.x2),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: FinoraV8Type.pageTitle.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
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
