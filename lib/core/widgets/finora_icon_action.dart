import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../state/theme_studio_controller.dart';
import 'finora_member_filter.dart';



/// One size and shape for compact page, section and modal actions.

class FinoraIconAction extends StatelessWidget {

  const FinoraIconAction({

    super.key,

    required this.icon,

    required this.label,

    this.onPressed,

    this.onTap,

    this.primary = false,

    this.size = 44,

  });



  final IconData icon;

  final String label;

  final VoidCallback? onPressed;

  final VoidCallback? onTap;

  final bool primary;

  final double size;



  @override

  Widget build(BuildContext context) {

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final effectiveSize =

        size == 44 && studio != null ? studio.getIconButtonSize() : size;

    final radius = switch (studio?.iconStyle) {

      AppIconStyle.softSquare => 12.0,

      AppIconStyle.dimensional => 18.0,

      _ => effectiveSize / 2,

    };

    return FinoraCircleIconButton(

      icon: icon,

      tooltip: label,

      onPressed: onTap ?? onPressed,

      primary: primary,

      size: effectiveSize,

      iconSize: effectiveSize * 0.48,

      cornerRadius: radius,

    );

  }

}



/// Unified Compact Liquid Glass Back Button

/// Specifications:

/// - Exact 34x34 compact dimension

/// - Smooth circular shape with BackdropFilter blur

/// - Translucent liquid glass fill with fine specular hairline border

/// - Soft ambient drop shadow

/// - Crisp Apple iOS arrow icon (Icons.arrow_back_ios_new_rounded)

class FinoraBackButton extends StatelessWidget {

  const FinoraBackButton({

    super.key,

    this.onPressed,

    this.size = 34.0,

  });



  final VoidCallback? onPressed;

  final double size;



  @override

  Widget build(BuildContext context) => FinoraCircleIconButton(

        icon: Icons.arrow_back_ios_new_rounded,

        tooltip: 'Quay lại',

        size: size,

        iconSize: 14.5,

        cornerRadius: size / 2,

        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),

      );

}



/// Floating circular icon button for frosted glass AppBars and modern headers

/// Designed after the reference image: circular container with subtle shadow,

/// hairline border, BackdropFilter blur, and crisp centered icon.

class FinoraCircleIconButton extends StatelessWidget {

  final IconData icon;

  final VoidCallback? onPressed;

  final String? tooltip;

  final double size;

  final double iconSize;

  final Color? color;

  final Color? iconColor;

  final bool primary;

  final double? cornerRadius;



  const FinoraCircleIconButton({

    super.key,

    required this.icon,

    this.onPressed,

    this.tooltip,

    this.size = 38.0,

    this.iconSize = 20.0,

    this.color,

    this.iconColor,

    this.primary = false,

    this.cornerRadius,

  });



  @override

  Widget build(BuildContext context) {

    final dark = Theme.of(context).brightness == Brightness.dark;

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final scheme = Theme.of(context).colorScheme;

    final accent = studio?.resolvedPrimary ?? scheme.primary;

    final radius = cornerRadius ??

        (studio?.iconStyle == AppIconStyle.softSquare ? 12.0 : size / 2);

    final shape =

        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    final fill = color ??

        (primary

            ? accent

            : (dark ? const Color(0xFF1E293B) : Colors.white)

                .withValues(alpha: dark ? 0.72 : 0.88));

    Widget button = DecoratedBox(

      decoration: BoxDecoration(

        color: fill,

        borderRadius: BorderRadius.circular(radius),

        border: Border.all(

          color: (dark ? Colors.white : Colors.black)

              .withValues(alpha: dark ? 0.10 : 0.08),

          width: 0.85,

        ),

        boxShadow: primary

            ? [

                BoxShadow(

                  color: accent.withValues(alpha: dark ? 0.32 : 0.20),

                  blurRadius: 10,

                  offset: const Offset(0, 3),

                ),

              ]

            : null,

      ),

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          customBorder: shape,

          onTap: onPressed == null

              ? null

              : () {

                  HapticFeedback.selectionClick();

                  onPressed!();

                },

          child: SizedBox.square(

            dimension: size,

            child: Icon(icon,

                size: iconSize,

                color: iconColor ??

                    (primary ? Colors.white : scheme.onSurface)

                        .withValues(alpha: onPressed == null ? 0.42 : 1.0)),

          ),

        ),

      ),

    );

    button = Semantics(button: true, enabled: onPressed != null, child: button);

    if (tooltip != null && tooltip!.isNotEmpty) {

      button = Tooltip(message: tooltip!, child: button);

    }

    return button;

  }

}



/// Unified Primary Add Action Button

/// Specifications:

/// - Same 34x34 compact circular size

/// - Vibrant primary gradient fill with specular highlight border

/// - Crisp centered add icon

class FinoraAddButton extends StatelessWidget {

  final VoidCallback? onPressed;

  final String tooltip;

  final double size;

  final Color? color;

  final Color? iconColor;



  const FinoraAddButton({

    super.key,

    required this.onPressed,

    this.tooltip = 'Thêm mới',

    this.size = 34.0,

    this.color,

    this.iconColor,

  });



  @override

  Widget build(BuildContext context) => FinoraCircleIconButton(

        icon: Icons.add_rounded,

        tooltip: tooltip,

        size: size,

        iconSize: 19,

        cornerRadius: size / 2,

        primary: color == null,

        color: color,

        iconColor: iconColor ?? Colors.white,

        onPressed: onPressed,

      );

}



/// Unified "Xem tất cả >" Pill Action Button

/// Specifications:

/// - Exact 30px height pill

/// - Subtle translucent frosted glass container with hairline retina border

/// - Crisp Cupertino chevron right

/// - Smooth haptic feedback on tap

class FinoraSeeAllButton extends StatelessWidget {

  final String label;

  final VoidCallback? onTap;



  const FinoraSeeAllButton({

    super.key,

    this.label = 'Xem tất cả',

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    final dark = Theme.of(context).brightness == Brightness.dark;

    final bg = (dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))

        .withValues(alpha: dark ? 0.72 : 0.88);

    return DecoratedBox(

      decoration: BoxDecoration(

        color: bg,

        borderRadius: BorderRadius.circular(100),

        border: Border.all(

          color: (dark ? Colors.white : Colors.black)

              .withValues(alpha: dark ? 0.10 : 0.06),

          width: 0.8,

        ),

      ),

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          onTap: onTap == null

              ? null

              : () {

                  HapticFeedback.selectionClick();

                  onTap!();

                },

          borderRadius: BorderRadius.circular(100),

          child: Container(

            height: 30,

            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            child: Row(

              mainAxisSize: MainAxisSize.min,

              children: [

                Text(

                  label,

                  style: TextStyle(

                    fontSize: 11.5,

                    fontWeight: FontWeight.w700,

                    color: dark ? Colors.white70 : const Color(0xFF475569),

                  ),

                ),

                const SizedBox(width: 3),

                Icon(

                  Icons.arrow_forward_ios_rounded,

                  size: 10,

                  color: dark ? Colors.white54 : const Color(0xFF64748B),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}



/// Unified Pill / Squircle Action Button (with text + optional icon, e.g. "Xem tất cả", "+ Thêm")

class FinoraPillButton extends StatelessWidget {

  final IconData? icon;

  final String label;

  final VoidCallback? onPressed;

  final VoidCallback? onTap;

  final bool primary;

  final bool compact;



  const FinoraPillButton({

    super.key,

    this.icon,

    required this.label,

    this.onPressed,

    this.onTap,

    this.primary = false,

    this.compact = false,

  });



  @override

  Widget build(BuildContext context) {

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final dark = Theme.of(context).brightness == Brightness.dark;

    final scheme = Theme.of(context).colorScheme;

    final radius = studio?.getButtonRadius() ?? 999.0;

    final effectiveCallback = onTap ?? onPressed;



    final shape = RoundedRectangleBorder(

      borderRadius: BorderRadius.circular(radius >= 999 ? 999 : radius * 0.75),

    );

    final bg = primary

        ? scheme.primary

        : (dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))

            .withValues(alpha: dark ? 0.72 : 0.88);

    final fg = primary ? Colors.white : scheme.onSurface;



    return DecoratedBox(

      decoration: ShapeDecoration(

        color: bg,

        shape: shape,

        shadows: primary

            ? [

                BoxShadow(

                  color: scheme.primary.withValues(alpha: dark ? 0.32 : 0.18),

                  blurRadius: 8,

                  offset: const Offset(0, 2),

                ),

              ]

            : null,

      ),

      child: Material(

        color: Colors.transparent,

        shape: shape,

        child: InkWell(

          customBorder: shape,

          onTap: effectiveCallback == null

              ? null

              : () {

                  HapticFeedback.selectionClick();

                  effectiveCallback();

                },

          child: Padding(

            padding: EdgeInsets.symmetric(

              horizontal: compact ? 10 : 14,

              vertical: compact ? 6 : 8,

            ),

            child: Row(

              mainAxisSize: MainAxisSize.min,

              children: [

                if (icon != null) ...[

                  Icon(icon, size: compact ? 14 : 16, color: fg),

                  const SizedBox(width: 5),

                ],

                Text(

                  label,

                  style: TextStyle(

                    fontSize: compact ? 11.5 : 12.5,

                    fontWeight: FontWeight.w700,

                    color: fg,

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



/// Unified Translucent Date Filter Pill

/// Compact design with onHeroCard glass optimization

class FinoraDateFilterPill extends StatelessWidget {

  final String label;

  final VoidCallback? onTap;

  final bool isCustom;

  final double height;

  final bool onHeroCard;



  const FinoraDateFilterPill({

    super.key,

    required this.label,

    required this.onTap,

    this.isCustom = false,

    this.height = 32.0,

    this.onHeroCard = false,

  });



  @override

  Widget build(BuildContext context) {

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final dark = Theme.of(context).brightness == Brightness.dark || onHeroCard;

    final primary =

        studio?.primaryColor ?? Theme.of(context).colorScheme.primary;



    final bgColor = onHeroCard

        ? Colors.black.withValues(alpha: 0.22)

        : (isCustom

            ? primary.withValues(alpha: dark ? 0.22 : 0.12)

            : (dark

                ? Colors.white.withValues(alpha: 0.10)

                : Colors.white.withValues(alpha: 0.85)));



    final borderColor = onHeroCard

        ? Colors.white.withValues(alpha: 0.18)

        : (isCustom

            ? primary.withValues(alpha: 0.5)

            : (dark

                ? Colors.white.withValues(alpha: 0.16)

                : Colors.black.withValues(alpha: 0.08)));



    final textColor = onHeroCard

        ? Colors.white.withValues(alpha: 0.95)

        : (isCustom

            ? primary

            : (dark ? Colors.white : const Color(0xFF0F172A)));



    final iconColor = onHeroCard

        ? Colors.white.withValues(alpha: 0.85)

        : (isCustom

            ? primary

            : (dark ? Colors.white70 : const Color(0xFF475569)));



    final chevronColor = onHeroCard

        ? Colors.white.withValues(alpha: 0.60)

        : (isCustom

            ? primary

            : (dark ? Colors.white54 : const Color(0xFF64748B)));



    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap == null

            ? null

            : () {

                HapticFeedback.selectionClick();

                onTap!();

              },

        borderRadius: BorderRadius.circular(100),

        child: Container(

          height: height,

          padding: EdgeInsets.symmetric(

              horizontal: onHeroCard ? 8 : 9, vertical: 2.5),

          decoration: BoxDecoration(

            color: bgColor,

            borderRadius: BorderRadius.circular(100),

            border: Border.all(

              color: borderColor,

              width: 0.75,

            ),

          ),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Icon(

                Icons.calendar_today_rounded,

                size: onHeroCard ? 10.5 : 11.5,

                color: iconColor,

              ),

              SizedBox(width: onHeroCard ? 4 : 4.5),

              Text(

                label,

                style: TextStyle(

                  fontSize: onHeroCard ? 11 : 11.5,

                  fontWeight: FontWeight.w700,

                  color: textColor,

                  letterSpacing: -0.1,

                ),

              ),

              const SizedBox(width: 2.5),

              Icon(

                Icons.keyboard_arrow_down_rounded,

                size: onHeroCard ? 13 : 13.5,

                color: chevronColor,

              ),

            ],

          ),

        ),

      ),

    );

  }

}



/// Unified Member Segmented Control (Tất cả | Chồng | Vợ)

/// Standard 34px height across Dashboard, Budget, Transaction, etc.

class FinoraMemberSegmentedFilter extends StatelessWidget {

  final String selectedValue; // 'all', 'husband', 'wife'

  final ValueChanged<String> onChanged;

  final double height;



  const FinoraMemberSegmentedFilter({

    super.key,

    required this.selectedValue,

    required this.onChanged,

    this.height = 34.0,

  });



  static const _values = ['all', 'husband', 'wife'];

  static const _labels = ['Tất cả', 'Chồng', 'Vợ'];

  @override

  Widget build(BuildContext context) {

    final dark = Theme.of(context).brightness == Brightness.dark;

    final index = _values.indexOf(selectedValue).clamp(0, 2);

    final activeColor = index == 1

        ? const Color(0xFF0284C7) // Chồng: Xanh đại dương (Ocean Blue)

        : (index == 2

            ? const Color(0xFFEC4899) // Vợ: Hồng ngọt ngào (Rose Pink)

            : (dark ? const Color(0xFF334155) : const Color(0xFF475569)));

    final x = -1.0 + (index * (2.0 / 2));



    return Container(

      height: height,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(

        color: dark ? const Color(0xFF202D39) : const Color(0xFFEDF3F1),

        borderRadius: BorderRadius.circular(100),

        border: Border.all(

          color: dark

              ? Colors.white.withValues(alpha: 0.12)

              : Colors.white.withValues(alpha: 0.90),

          width: 0.8,

        ),

      ),

      child: Stack(

        children: [

          AnimatedAlign(

            duration: const Duration(milliseconds: 250),

            curve: Curves.easeOutCubic,

            alignment: Alignment(x, 0),

            child: FractionallySizedBox(

              widthFactor: 1 / 3,

              heightFactor: 1,

              child: Padding(

                padding: const EdgeInsets.symmetric(horizontal: 2.5),

                child: Container(

                  decoration: BoxDecoration(

                    color: activeColor,

                    borderRadius: BorderRadius.circular(100),

                    boxShadow: [

                      BoxShadow(

                        color: activeColor.withValues(alpha: 0.35),

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

            children: List.generate(3, (i) {

              final isSelected = i == index;

              return Expanded(

                child: Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 1.5),

                  child: InkWell(

                    borderRadius: BorderRadius.circular(100),

                    onTap: () {

                      if (!isSelected) {

                        HapticFeedback.selectionClick();

                        onChanged(_values[i]);

                      }

                    },

                    child: Center(

                      child: Text(

                        _labels[i],

                        style: TextStyle(

                          fontSize: 11.5,

                          fontWeight:

                              isSelected ? FontWeight.w800 : FontWeight.w600,

                          color: isSelected

                              ? Colors.white

                              : (dark ? Colors.white70 : const Color(0xFF64748B)),

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

    );

  }

}



/// Unified Member Filter Dropdown Pill
/// Compact circular avatar/icon-only button (no text label on the button)
class FinoraMemberFilterPill extends StatelessWidget {
  final String label;
  final String selectedValue; // 'all', 'husband', 'wife'
  final VoidCallback onTap;
  final double height;
  final bool onHeroCard;

  const FinoraMemberFilterPill({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.onTap,
    this.height = 28.0,
    this.onHeroCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark || onHeroCard;
    final member =
        (selectedValue == 'all' || selectedValue.isEmpty) ? null : selectedValue;
    final dotColor = FinoraMemberAvatar.colorFor(member);

    final bgColor = onHeroCard
        ? Colors.black.withValues(alpha: 0.28)
        : (dark ? const Color(0xFF1E293B) : Colors.white);

    final borderColor = onHeroCard
        ? dotColor.withValues(alpha: 0.55)
        : (dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: height,
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: FinoraMemberAvatar(
              member: member,
              size: height - 4,
              isDark: dark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ultra-sleek connected dual glass capsule for Hero Card headers
/// Merges Member Avatar (circular icon/avatar only) + Date Filter into an integrated, compact
/// frosted-glass control with hairline divider and subtle micro-haptics.
class FinoraHeroFilterCapsule extends StatelessWidget {
  final String memberLabel;
  final String memberValue; // 'all', 'husband', 'wife'
  final VoidCallback onMemberTap;
  final String dateLabel;
  final VoidCallback onDateTap;
  final bool isLightCard;

  const FinoraHeroFilterCapsule({
    super.key,
    required this.memberLabel,
    required this.memberValue,
    required this.onMemberTap,
    required this.dateLabel,
    required this.onDateTap,
    this.isLightCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final member =
        (memberValue == 'all' || memberValue.isEmpty) ? null : memberValue;

    final capsuleBg = isLightCard
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.22);

    final borderColor = isLightCard
        ? const Color(0xFFCBD5E1)
        : Colors.white.withValues(alpha: 0.18);

    final textColor = isLightCard
        ? const Color(0xFF0F172A)
        : Colors.white.withValues(alpha: 0.95);

    final chevronColor = isLightCard
        ? const Color(0xFF64748B)
        : Colors.white.withValues(alpha: 0.60);

    final dividerColor = isLightCard
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.20);

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: capsuleBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: borderColor,
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLightCard ? 0.03 : 0.16),
            blurRadius: 8,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left segment: Member Avatar ONLY (no text label)
            Tooltip(
              message: memberLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onMemberTap();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: FinoraMemberAvatar(
                      member: member,
                      size: 22,
                      isDark: !isLightCard,
                      showRing: true,
                    ),
                  ),
                ),
              ),
            ),

            // Subtle vertical frosted divider
            Container(
              width: 0.8,
              height: 12,
              color: dividerColor,
            ),

            // Right segment: Date
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDateTap();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 10.5,
                        color: isLightCard
                            ? const Color(0xFF0284C7)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 2.5),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 13,
                        color: chevronColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

