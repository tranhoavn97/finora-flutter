import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../glassmorphism_tokens.dart';
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
            filter: ImageFilter.blur(
              sigmaX: GlassmorphismTokens.controlBlur,
              sigmaY: GlassmorphismTokens.controlBlur,
            ),
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
                  width: GlassmorphismTokens.hairlineBorderWidth,
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
    this.color = GlassmorphismTokens.primary,
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
                    width: GlassmorphismTokens.hairlineBorderWidth,
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

/// Standard Apple iOS HIG Back Button: 40x40 circle with hairline border, subtle shadow, 24px chevron
class FinoraBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isClose; // if true, uses close icon (X)

  const FinoraBackButton({
    super.key,
    this.onTap,
    this.tooltip,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: Border.all(
              color: isDark
                  ? GlassmorphismTokens.borderDarkSolid
                  : GlassmorphismTokens.borderLightSolid,
              width: GlassmorphismTokens.hairlineBorderWidth,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            isClose ? Icons.close_rounded : Icons.chevron_left_rounded,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            size: isClose ? 20 : 24,
          ),
        ),
      ),
    );
  }
}

/// Standard Apple iOS HIG Top-Bar Add Button: 40x40 circle with Apple System Blue fill and white (+) icon
class FinoraAddIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? tooltip;

  const FinoraAddIconButton({
    super.key,
    required this.onTap,
    this.tooltip = 'Thêm mới',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GlassmorphismTokens.primary,
            boxShadow: [
              BoxShadow(
                color: GlassmorphismTokens.primaryGlow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Standard Apple iOS HIG Section Circular Add Button: 32x32 circle in Apple System Blue
class FinoraSectionAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final double size;
  final String? tooltip;

  const FinoraSectionAddButton({
    super.key,
    required this.onTap,
    this.label = 'Thêm',
    this.size = 32,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassmorphismTokens.primary,
              boxShadow: [
                BoxShadow(
                  color: GlassmorphismTokens.primaryGlow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: size * 0.625,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard Apple iOS HIG Header Action Icon Button: 40x40 circle with hairline border
class FinoraHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final double iconSize;

  const FinoraHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: Border.all(
              color: isDark
                  ? GlassmorphismTokens.borderDarkSolid
                  : GlassmorphismTokens.borderLightSolid,
              width: GlassmorphismTokens.hairlineBorderWidth,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            icon,
            color: color ?? defaultColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class FinoraPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final List<Widget> actions;
  final bool isClose;
  final bool centerTitle;

  const FinoraPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onAdd,
    this.actions = const [],
    this.isClose = false,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
    const secondaryColor = GlassmorphismTokens.neutral;

    final showBack = onBack != null;
    final allActions = <Widget>[
      ...actions,
      if (onAdd != null) ...[
        if (actions.isNotEmpty) const SizedBox(width: 8),
        FinoraAddIconButton(onTap: onAdd!),
      ],
    ];

    return SafeArea(
      bottom: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Leading
            if (showBack) ...[
              FinoraBackButton(
                onTap: onBack,
                isClose: isClose,
              ),
              const SizedBox(width: 12),
            ] else if (centerTitle)
              SizedBox(width: allActions.isNotEmpty ? 40 : 0),

            // Title & optional subtitle
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: centerTitle ? 8 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: centerTitle
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Trailing actions / Add button
            if (allActions.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: allActions,
              )
            else if (showBack && centerTitle)
              const SizedBox(width: 40)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
