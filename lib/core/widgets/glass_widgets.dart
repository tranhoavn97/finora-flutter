import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import '../design_system/v8/finora_v8.dart' hide FinoraButton;
import '../theme/app_theme.dart';
import 'premium_widgets.dart';
import 'finora_icon_action.dart';
import 'liquid_glass/liquid_glass_card.dart';
export 'premium_widgets.dart'
    show
        GlassCard,
        FloatingGlassCard,
        AmbientFloatingBackground,
        FirstLetterUpperCaseFormatter,
        DotSeparatorTextInputFormatter,
        FinoraActionPill,
        FinoraSectionActionPill;
export 'finora_icon_action.dart';
export '../design_system/v8/finora_v8_controls.dart';

/// A shared glass segmented control matching Finora's web pill tabs.
/// The selected capsule slides with a soft spring instead of rebuilding in place.
class BouncyPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Color>? colors;
  final List<IconData>? icons;
  final double height;
  final double? fontSize;

  const BouncyPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
    this.icons,
    this.height = 38,
    this.fontSize,
  }) : assert(labels.length > 1);

  @override
  Widget build(BuildContext context) => FinoraSegmentedTabs(
        labels: labels,
        selectedIndex: selectedIndex,
        onChanged: onChanged,
        colors: colors,
        icons: icons,
        height: height,
        fontSize: fontSize,
      );
}

/// Frosted-glass card with a faint top sheen + bright hairline edge.

/// Page scaffold that paints the glass backdrop behind a transparent Scaffold.
class GlassScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? extendBodyBehindAppBar;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar,
  });

  /// Helper to calculate the top inset needed when [extendBodyBehindAppBar] is true
  static double topInset(BuildContext context, [double extra = 12.0]) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final isFloating = studio?.isAppBarFloating ?? false;
    return MediaQuery.paddingOf(context).top +
        FinoraV8Metrics.pageHeader +
        (isFloating ? 18.0 : 8.0) +
        extra;
  }

  @override
  State<GlassScaffold> createState() => _GlassScaffoldState();
}

class _GlassScaffoldState extends State<GlassScaffold> {
  bool _isAppBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isScrollHide = studio?.isAppBarScrollHide ?? false;
    final effectiveExtend = widget.extendBodyBehindAppBar ?? true;

    PreferredSizeWidget? effectiveAppBar = widget.appBar;
    if (effectiveAppBar != null && isScrollHide) {
      effectiveAppBar = PreferredSize(
        preferredSize: effectiveAppBar.preferredSize,
        child: AnimatedSlide(
          offset: _isAppBarVisible ? Offset.zero : const Offset(0, -1.2),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isAppBarVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: widget.appBar!,
          ),
        ),
      );
    }

    Widget content = widget.body;
    if (isScrollHide) {
      content = NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse &&
              _isAppBarVisible) {
            setState(() => _isAppBarVisible = false);
          } else if (notification.direction == ScrollDirection.forward &&
              !_isAppBarVisible) {
            setState(() => _isAppBarVisible = true);
          }
          return false;
        },
        child: content,
      );
    }

    return AmbientFloatingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: effectiveExtend,
        appBar: effectiveAppBar,
        body: content,
        bottomNavigationBar: widget.bottomNavigationBar,
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      ),
    );
  }
}

/// Compact, pinned frosted glass top bar matching the floating circular button design.
/// - BackdropFilter blur with real-time translucency
/// - Circular back button and circular action buttons
/// - Bold typography
/// - Hairline bottom specular border
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final double height;
  final double blur;
  final bool showBottomDivider;
  final Color? backgroundColor;
  final bool isTransparent;

  const GlassTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
    this.height = FinoraV8Metrics.pageHeader,
    this.blur = 18.0,
    this.showBottomDivider = false,
    this.backgroundColor,
    this.isTransparent = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height + 12);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBack && (onBack != null || canPop);

    final isFloating = studio?.isAppBarFloating ??
        (studio?.appBarScrollBehavior == AppAppBarScrollBehavior.floating ||
            studio?.topBarStyle == AppTopBarStyle.floatingIsland);
    final customAlpha = (studio?.appBarOpacity ?? 0.55).clamp(0.0, 1.0);
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);
    final hMargin = studio?.pageHorizontalMargin ?? 14.0;

    final topBarStyle = studio?.topBarStyle ?? AppTopBarStyle.frostedGlass;
    final isMinimal = topBarStyle == AppTopBarStyle.pureMinimal;
    final isSeamless = topBarStyle == AppTopBarStyle.seamlessBlend;

    final bool transparentBar = isMinimal ||
        isTransparent ||
        backgroundColor == Colors.transparent ||
        customAlpha <= 0.01;

    final effectiveBlur = transparentBar
        ? 0.0
        : (studio?.appBarBlur ?? (isSeamless ? 18.0 : 22.0)).clamp(0.0, 30.0);

    final Color topBarFill;
    if (transparentBar) {
      topBarFill = Colors.transparent;
    } else if (backgroundColor != null) {
      topBarFill = backgroundColor!;
    } else {
      topBarFill = Colors.transparent;
    }

    final effectiveRadius = isFloating
        ? BorderRadius.circular(
            studio?.cardCornerRadius.clamp(14.0, 24.0) ?? 18)
        : BorderRadius.zero;

    final isLiquidGlass = studio?.isSystemWideLiquidGlass ?? false;
    final borderWidth = studio?.widgetBorderWidth ?? 0.8;
    final bool hasBorder = !isSeamless &&
        !isMinimal &&
        borderWidth > 0.05 &&
        (studio?.appBarShowBorder ?? true);

    final effectiveBorder = transparentBar || !hasBorder
        ? null
        : (isFloating
            ? (isLiquidGlass
                ? null
                : (studio?.getCardBorder(dark) ??
                    Border.all(
                      color: primary.withValues(alpha: dark ? 0.35 : 0.22),
                      width: borderWidth,
                    )))
            : (showBottomDivider
                ? Border(
                    bottom: BorderSide(
                      color: isLiquidGlass
                          ? (dark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white.withValues(alpha: 0.25))
                          : (dark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                      width: isLiquidGlass ? 0.8 : borderWidth,
                    ),
                  )
                : null));

    final List<BoxShadow>? effectiveShadows = (transparentBar || isSeamless)
        ? null
        : (isFloating
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.20 : 0.04),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: primary.withValues(alpha: dark ? 0.06 : 0.02),
                  blurRadius: 20,
                  spreadRadius: -3,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isLiquidGlass
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.12 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : studio?.getGlowShadows(dark)));

    Widget barContent = SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isFloating ? 12 : hMargin),
        child: Row(
          children: [
            if (shouldShowBack) ...[
              FinoraCircleIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Quay lại',
                size: 38,
                iconSize: 20,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
            ] else if (titleWidget != null && title.isEmpty) ...[
              // Full width for custom titleWidget
            ] else ...[
              const SizedBox(width: 4),
            ],
            Expanded(
              child: titleWidget ??
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
            ),
            if (actions.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: action,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );

    if (isFloating) {
      final floatingChild = Container(
        decoration: BoxDecoration(
          color: topBarFill,
          borderRadius: effectiveRadius,
          border: effectiveBorder,
        ),
        child: barContent,
      );

      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: hMargin,
            right: hMargin,
            top: 6,
            bottom: 6,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              boxShadow: effectiveShadows,
            ),
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: floatingChild,
            ),
          ),
        ),
      );
    }

    final Widget pinnedBar = Container(
      decoration: BoxDecoration(
        color: topBarFill,
        border: effectiveBorder,
        boxShadow: effectiveShadows,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(height: height, child: barContent),
      ),
    );

    if (transparentBar || effectiveBlur <= 0.1) {
      return pinnedBar;
    }

    return ClipRect(
      child: BackdropFilter(
        filter:
            ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: pinnedBar,
      ),
    );
  }
}

/// Sliver version of GlassTopBar for CustomScrollView with pinned: true
class FinoraSliverBlurAppBar extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final double height;
  final double blur;

  const FinoraSliverBlurAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
    this.height = FinoraV8Metrics.pageHeader,
    this.blur = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      flexibleSpace: GlassTopBar(
        title: title,
        titleWidget: titleWidget,
        onBack: onBack,
        showBack: showBack,
        actions: actions,
        height: height,
        blur: blur,
      ),
    );
  }
}

/// Modern Apple-inspired glass header for bottom sheet modals
class FinoraSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onClose;
  final bool showHandle;

  const FinoraSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onClose,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = iconColor ??
        studio?.primaryColor ??
        Theme.of(context).colorScheme.primary;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const subColor = Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  FinoraIconAction(
                    icon: Icons.close_rounded,
                    label: 'Đóng',
                    size: 38,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ],
    );
  }
}

/// Frosted glass dialog for iOS-style premium dialogs.
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const GlassDialog({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liquid = studio?.isSystemWideLiquidGlass ?? true;
    final effectiveBlur = studio?.glassBlur ?? 25.0;
    final effectiveFill = liquid
        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
            .withValues(alpha: isDark ? 0.68 : 0.72)
        : (studio?.getModalFillColor(isDark) ??
            (isDark ? const Color(0xFF0F172A) : Colors.white));
    final effectiveRadius = radius != 24.0
        ? radius
        : (studio?.getCardRadius(studio.globalDensity) ?? 24.0);
    final primaryColor = iconColor ??
        studio?.primaryColor ??
        Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LiquidGlassSurface(
        radius: effectiveRadius,
        blur: effectiveBlur,
        fillColor: effectiveFill,
        tintColor: primaryColor,
        enabled: liquid,
        specular: studio?.liquidGlassSpecularHighlight ?? true,
        refraction: studio?.liquidGlassCausticRefraction ?? true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(
                              alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor.withValues(
                                alpha: isDark ? 0.35 : 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(icon, color: primaryColor, size: 18),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FinoraIconAction(
                      icon: Icons.close_rounded,
                      label: 'Đóng',
                      size: 34,
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                padding: padding,
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Frosted glass bottom sheet with drag indicator, ambient glow, and rounded top corners.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool showHandle;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? padding;
  final bool isExpanded;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.radius = 28.0,
    this.showHandle = true,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onClose,
    this.padding,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Clean, 100% opaque Apple iOS 18 sheet surface
    final effectiveFill = isDark ? const Color(0xFF111827) : Colors.white;
    final effectiveRadius = radius;

    final sheetContent = Material(
      color: effectiveFill,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveFill,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 36,
              spreadRadius: -2,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: isExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      FinoraSheetHeader(
                        title: title!,
                        subtitle: subtitle,
                        icon: icon,
                        iconColor: iconColor,
                        trailing: trailing,
                        onClose: onClose,
                        showHandle: showHandle,
                      ),
                    ] else if (showHandle) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 38,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: padding != null
                          ? Padding(padding: padding!, child: child)
                          : child,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      FinoraSheetHeader(
                        title: title!,
                        subtitle: subtitle,
                        icon: icon,
                        iconColor: iconColor,
                        trailing: trailing,
                        onClose: onClose,
                        showHandle: showHandle,
                      ),
                    ] else if (showHandle) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 38,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                      child: padding != null
                          ? Padding(padding: padding!, child: child)
                          : child,
                    ),
                  ],
                ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(effectiveRadius)),
      child: sheetContent,
    );
  }
}

/// Helper function to open modal bottom sheets with unified frosted glass styling.
Future<T?> showFinoraGlassModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double radius = 28.0,
  bool showHandle = true,
  String? title,
  String? subtitle,
  IconData? icon,
  Color? iconColor,
  Widget? trailing,
  VoidCallback? onClose,
  EdgeInsetsGeometry? padding,
  bool isExpanded = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.50),
    builder: (ctx) => GlassBottomSheet(
      radius: radius,
      showHandle: showHandle,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      trailing: trailing,
      onClose: onClose,
      padding: padding,
      isExpanded: isExpanded,
      child: builder(ctx),
    ),
  );
}

/// Primary filled button with a soft coloured glow.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final bool glow;
  final double height;
  final bool expand;
  final bool isLoading;
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = Brand.primaryBlue,
    this.glow = true,
    this.height = 52,
    this.expand = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FinoraButton(
      onPressed: onPressed,
      height: height,
      expand: expand,
      color: color.withValues(alpha: 1.0),
      isLoading: isLoading,
      child: child,
    );
  }
}

/// iOS-style filled glass text field.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.maxLines = 1,
    this.suffix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return FinoraTextField(
      controller: controller,
      hint: hint,
      obscure: obscure,
      keyboardType: keyboardType,
      suffix: suffix,
      radius: 22,
      inputFormatters: inputFormatters,
    );
  }
}

/// iOS-style segmented control. [options] are (value, label) pairs.
class SegmentedControl extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => FinoraSegmentedTabs(
        labels: options.map((option) => option.$2).toList(),
        selectedIndex: options.indexWhere((option) => option.$1 == selected),
        onChanged: (index) => onChanged(options[index].$1),
      );
}

/// iOS-style pill filter chip.
class FilterChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  const FilterChipX(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.color = Brand.primaryBlue,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return LiquidFilterPill(
      label: label,
      selected: selected,
      onTap: onTap,
      color: color,
      icon: icon,
    );
  }
}

/// Fully rounded, color-aware frosted filter shared across the app.
class LiquidFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const LiquidFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) => FinoraFilterPill(
        label: label,
        selected: selected,
        onTap: onTap,
        color: color,
        icon: icon,
      );
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title,
              style: AppText.sectionTitle.copyWith(color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (actionText != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: FinoraIconAction(
              icon: actionText!.toLowerCase().contains('thêm')
                  ? Icons.add_rounded
                  : Icons.arrow_forward_rounded,
              label: actionText!,
              onPressed: onAction,
            ),
          ),
      ],
    );
  }
}

/// Uppercase group label.
class Overline extends StatelessWidget {
  final String text;
  const Overline(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: AppText.overline.copyWith(color: context.fc.textTertiary));
  }
}

/// Rounded tinted icon badge (icon or emoji).
class IconBadge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color tint;
  final double size;
  const IconBadge(
      {super.key, this.icon, this.emoji, required this.tint, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.44))
          : Icon(icon, color: tint, size: size * 0.46),
    );
  }
}

/// Centred premium empty-state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.primaryBlue.withValues(alpha: 0.14),
              border:
                  Border.all(color: Brand.primaryBlue.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: Brand.accentBlue, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: AppText.sectionTitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: c.textSecondary)),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 22),
            PrimaryButton(
              onPressed: onAction,
              child: Text(actionText!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Xóa',
  String cancelText = 'Hủy',
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryTextColor =
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  final secondaryTextColor =
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  const dangerColor = Color(0xFFE11D48);

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.56),
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 376),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dangerColor.withValues(alpha: isDark ? 0.34 : 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.52 : 0.14),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: dangerColor.withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    dangerColor.withValues(alpha: isDark ? 0.28 : 0.18),
                    dangerColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
                ),
                border: Border.all(
                  color: dangerColor.withValues(alpha: isDark ? 0.45 : 0.30),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dangerColor.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: dangerColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13.5,
                height: 1.48,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: dangerColor.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: dangerColor.withValues(alpha: 0.22),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    size: 13,
                    color: dangerColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Số dư ví & báo cáo sẽ tự động đối soát lại ngay',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFFDA4AF)
                            : const Color(0xFFBE123C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                          width: 1.1,
                        ),
                        shape: const StadiumBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(dialogCtx).pop(false);
                      },
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: dangerColor.withValues(alpha: 0.45),
                        shape: const StadiumBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(dialogCtx).pop(true);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_rounded,
                              size: 17, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            confirmText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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
  return result ?? false;
}

class GlassCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  const GlassCalendarPicker({super.key, required this.initialDate});

  @override
  State<GlassCalendarPicker> createState() => _GlassCalendarPickerState();
}

class _GlassCalendarPickerState extends State<GlassCalendarPicker> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month,
        widget.initialDate.day);
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark ? Colors.white60 : Colors.black54;

    final monthStr = 'Tháng ${_currentMonth.month}, ${_currentMonth.year}';
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final totalDays = _daysInMonth(_currentMonth);
    final firstDayWeekday = _firstWeekdayOfMonth(_currentMonth);
    final emptyPrefixCells = firstDayWeekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left, color: primaryColor),
              ),
              Text(
                monthStr,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: emptyPrefixCells + totalDays,
            itemBuilder: (context, index) {
              if (index < emptyPrefixCells) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - emptyPrefixCells + 1;
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF1877F2)
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text(
                    'Chọn',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular icon or emoji badge with liquid glass finish: soft gradient, reflective glass border, and crescent highlight.
class LiquidGlassCircleIcon extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color tint;
  final double size;

  const LiquidGlassCircleIcon({
    super.key,
    this.emoji,
    this.icon,
    required this.tint,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: isDark ? 0.35 : 0.22),
            tint.withValues(alpha: isDark ? 0.12 : 0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.40 : 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            left: size * 0.16,
            right: size * 0.16,
            child: Container(
              height: size * 0.38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(size)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.50 : 0.75),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (emoji != null && emoji!.trim().isNotEmpty)
            Text(
              emoji!,
              style: TextStyle(
                fontSize: size * 0.46,
                height: 1.1,
              ),
            )
          else if (icon != null)
            Icon(
              icon,
              color: tint,
              size: size * 0.50,
            )
          else
            Icon(
              Icons.category_rounded,
              color: tint,
              size: size * 0.50,
            ),
        ],
      ),
    );
  }
}

/// Unified, theme-studio-driven date picker adhering to system typography, corner radius & brand colors.
Future<DateTime?> showFinoraDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final studio = Provider.of<ThemeStudioController?>(context, listen: false);
  final primaryColor = studio?.resolvedPrimary ?? const Color(0xFF005FEA);
  final cardRadius = studio?.cardCornerRadius ?? 24.0;
  final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            backgroundColor: bgColor,
          ),
          colorScheme:
              (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                  .copyWith(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: bgColor,
            onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Unified, theme-studio-driven date range picker.
Future<DateTimeRange?> showFinoraDateRangePicker({
  required BuildContext context,
  required DateTimeRange initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? saveText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final studio = Provider.of<ThemeStudioController?>(context, listen: false);
  final primaryColor = studio?.resolvedPrimary ?? const Color(0xFF005FEA);
  final cardRadius = studio?.cardCornerRadius ?? 24.0;
  final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

  return showDateRangePicker(
    context: context,
    initialDateRange: initialDateRange,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    saveText: saveText,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            backgroundColor: bgColor,
          ),
          colorScheme:
              (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                  .copyWith(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: bgColor,
            onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Unified, luxury collapsible header delegate matching Revolut & Apple Wallet standards.
/// Pinned Toolbar Delegate for Natural Scroll Header pattern.
/// When the Hero Card scrolls naturally with the page,
/// this toolbar smoothly pins beneath the top bar with adaptive liquid glass blur.
class FinoraPinnedToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final double topInset;
  final double horizontalPadding;
  final double verticalPadding;
  final bool isDark;

  FinoraPinnedToolbarDelegate({
    required this.child,
    double? height,
    double? toolbarHeight,
    this.topInset = 0.0,
    this.horizontalPadding = 14.0,
    this.verticalPadding = 6.0,
    required this.isDark,
  }) : height = toolbarHeight ?? height ?? 44.0;

  @override
  double get minExtent => topInset + height + verticalPadding * 2;

  @override
  double get maxExtent => topInset + height + verticalPadding * 2;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);
    final topBarStyle = studio?.topBarStyle ?? AppTopBarStyle.seamlessBlend;
    final isMinimal = topBarStyle == AppTopBarStyle.pureMinimal;
    final isSeamless = topBarStyle == AppTopBarStyle.seamlessBlend;
    final customAlpha = (isMinimal || isSeamless)
        ? 0.0
        : (studio?.appBarOpacity ?? 0.55).clamp(0.0, 1.0);
    final adaptiveTop = studio?.getScreenTopBackgroundColor(isDark) ??
        (studio?.getStyleSurfaceBase(isDark) ??
            (isDark ? const Color(0xFF0F172A) : Colors.white));
    final tintedBase = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.12 : 0.06),
      adaptiveTop,
    );
    final isPinned = overlapsContent || shrinkOffset > 2.0;
    final topBarFill = (!isPinned ||
            isMinimal ||
            isSeamless ||
            customAlpha <= 0.01)
        ? Colors.transparent
        : tintedBase.withValues(alpha: (customAlpha * 0.85).clamp(0.10, 0.95));
    final borderWidth = studio?.widgetBorderWidth ?? 0.8;
    final bool hasBorder = isPinned &&
        !isSeamless &&
        !isMinimal &&
        borderWidth > 0.05 &&
        (studio?.appBarShowBorder ?? true);

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: topBarFill,
          border: !hasBorder
              ? null
              : Border(
                  bottom: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                    width: borderWidth,
                  ),
                ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topInset + verticalPadding,
            horizontalPadding,
            verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant FinoraPinnedToolbarDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.topInset != topInset ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.verticalPadding != verticalPadding ||
        oldDelegate.isDark != isDark;
  }
}

/// - Expands into a full glass hero card
/// - Smoothly cross-fades into a compact sub-bar matching AppBar background
/// - Keeps the secondary toolbar/tabs pinned below with zero jumpiness
class FinoraCollapsibleHeroHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double topInset;
  final Widget expandedCard;
  final Widget? collapsedBar;
  final Widget? toolbar;
  final double expandedCardHeight;
  final double collapsedBarHeight;
  final double toolbarHeight;
  final bool isDark;
  final double horizontalPadding;

  FinoraCollapsibleHeroHeaderDelegate({
    required this.topInset,
    required this.expandedCard,
    this.collapsedBar,
    this.toolbar,
    required this.expandedCardHeight,
    this.collapsedBarHeight = 42.0,
    this.toolbarHeight = 44.0,
    required this.isDark,
    this.horizontalPadding = 14.0,
  });

  @override
  double get minExtent =>
      topInset +
      (collapsedBar != null ? collapsedBarHeight : 0.0) +
      (toolbar != null ? toolbarHeight + 6.0 : 0.0) +
      6.0;

  @override
  double get maxExtent =>
      topInset +
      expandedCardHeight +
      8.0 +
      (toolbar != null ? toolbarHeight + 6.0 : 0.0) +
      6.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent).clamp(1.0, 9999.0))
        .clamp(0.0, 1.0);
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);
    final topBarStyle = studio?.topBarStyle ?? AppTopBarStyle.seamlessBlend;
    final isMinimal = topBarStyle == AppTopBarStyle.pureMinimal;
    final isSeamless = topBarStyle == AppTopBarStyle.seamlessBlend;
    final customAlpha = (isMinimal || isSeamless)
        ? 0.0
        : (studio?.appBarOpacity ?? 0.55).clamp(0.0, 1.0);
    final adaptiveTop = studio?.getScreenTopBackgroundColor(isDark) ??
        (studio?.getStyleSurfaceBase(isDark) ??
            (isDark ? const Color(0xFF0F172A) : Colors.white));
    final tintedBase = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.12 : 0.06),
      adaptiveTop,
    );
    final effectiveAlpha =
        (customAlpha * (0.80 + 0.20 * progress)).clamp(0.0, 1.0);
    final topBarFill =
        (isMinimal || isSeamless || progress <= 0.05 || customAlpha <= 0.01)
            ? Colors.transparent
            : tintedBase.withValues(
                alpha: (effectiveAlpha * 0.70).clamp(0.08, 0.90));
    final borderWidth = studio?.widgetBorderWidth ?? 0.8;
    final bool hasBorder = !isSeamless &&
        !isMinimal &&
        borderWidth > 0.05 &&
        (studio?.appBarShowBorder ?? true);

    final headerBody = Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, topInset, horizontalPadding, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Pha 1: Thẻ lớn (Hero Card) biến mất hoàn toàn trước progress = 0.36
                if (progress < 0.36)
                  Positioned.fill(
                    child: Opacity(
                      opacity: ((0.36 - progress) / 0.36).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -progress * 26.0),
                        child: Transform.scale(
                          scale: (1.0 - progress * 0.12).clamp(0.92, 1.0),
                          alignment: Alignment.topCenter,
                          child: IgnorePointer(
                            ignoring: progress > 0.28,
                            child: expandedCard,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Pha 2: Viên nang Dynamic Island xuất hiện mượt mà từ progress = 0.38 đến 0.72 với Curves.easeOutCubic
                if (collapsedBar != null && progress > 0.38)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Builder(builder: (_) {
                      final double rawT =
                          ((progress - 0.38) / 0.34).clamp(0.0, 1.0);
                      final double easeT = Curves.easeOutCubic.transform(rawT);
                      return Opacity(
                        opacity: easeT,
                        child: Transform.translate(
                          offset: Offset(0, (1.0 - easeT) * 14.0),
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * easeT,
                            alignment: Alignment.bottomCenter,
                            child: IgnorePointer(
                              ignoring: progress < 0.48,
                              child: collapsedBar!,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
          if (toolbar != null) ...[
            const SizedBox(height: 6),
            toolbar!,
          ],
        ],
      ),
    );

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: topBarFill,
          border: (!hasBorder || progress <= 0.2)
              ? null
              : Border(
                  bottom: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: progress > 0.4 ? 0.08 : 0.0),
                    width: borderWidth,
                  ),
                ),
        ),
        child: headerBody,
      ),
    );
  }

  @override
  bool shouldRebuild(
      covariant FinoraCollapsibleHeroHeaderDelegate oldDelegate) {
    return oldDelegate.expandedCard != expandedCard ||
        oldDelegate.collapsedBar != collapsedBar ||
        oldDelegate.toolbar != toolbar ||
        oldDelegate.isDark != isDark ||
        oldDelegate.topInset != topInset ||
        oldDelegate.expandedCardHeight != expandedCardHeight;
  }
}

/// Dynamic Island Capsule Widget siêu sang chuẩn Apple & Revolut.
/// Thiết kế nguyên khối bo tròn 100px, 2 Pod đối xứng cân đối,
/// đèn LED chỉ báo phát quang, vạch chia hairline thanh lịch và kính mờ chống xuyên sáng.
class FinoraDynamicIslandBar extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final Color leftColor;
  final IconData? leftIcon;
  final VoidCallback? onLeftTap;
  final String rightLabel;
  final String rightValue;
  final Color rightColor;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;
  final bool isDark;
  final double height;
  final VoidCallback? onTap;

  const FinoraDynamicIslandBar({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.leftColor,
    this.leftIcon,
    this.onLeftTap,
    required this.rightLabel,
    required this.rightValue,
    required this.rightColor,
    this.rightIcon,
    this.onRightTap,
    required this.isDark,
    this.height = 42.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardFill = studio?.getCardFillColor(isDark) ??
        (isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.95));

    final effectiveBg = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black)
          .withValues(alpha: isDark ? 0.04 : 0.02),
      cardFill,
    );

    final subTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.16 : 0.10),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pod Trái
              Expanded(
                child: InkWell(
                  onTap: onLeftTap,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leftIcon != null) ...[
                        Icon(leftIcon, size: 13, color: leftColor),
                        const SizedBox(width: 5),
                      ] else ...[
                        Container(
                          width: 7.5,
                          height: 7.5,
                          decoration: BoxDecoration(
                            color: leftColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: leftColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        leftLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          leftValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: leftColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Vạch chia hairline thẳng đứng
              Container(
                width: 1.0,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.14 : 0.08),
              ),

              // Pod Phải
              Expanded(
                child: InkWell(
                  onTap: onRightTap,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (rightIcon != null) ...[
                        Icon(rightIcon, size: 13, color: rightColor),
                        const SizedBox(width: 5),
                      ] else ...[
                        Container(
                          width: 7.5,
                          height: 7.5,
                          decoration: BoxDecoration(
                            color: rightColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: rightColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        rightLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          rightValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: rightColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
