import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'liquid_glass/liquid_glass_card.dart';

class FinoraNavigation extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const FinoraNavigation({
    super.key,
    required this.index,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  State<FinoraNavigation> createState() => _FinoraNavigationState();
}

class _FinoraNavigationState extends State<FinoraNavigation> {
  /// Continuous fractional tab position (`0.0` .. `3.0`) while finger is scrubbing.
  double? _dragFraction;

  /// Active hovered tab index (`0` .. `3`) during press-hold-slide scrubbing.
  int? _dragTabIndex;

  /// Tracks the last tab index emitted to avoid duplicate haptic/tap triggers.
  late int _lastEmittedIndex;

  @override
  void initState() {
    super.initState();
    _lastEmittedIndex = widget.index.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant FinoraNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && _dragFraction == null) {
      _lastEmittedIndex = widget.index.clamp(0, 3);
    }
  }

  /// Tab-specific accent color for each of the 4 main dock tabs:
  /// - Tab 0 (`Trang chủ`): Emerald `#0F6E56` (Light) / `#10B981` (Dark)
  /// - Tab 1 (`Tài sản`): Ocean Sapphire `#0284C7` (Light) / `#38BDF8` (Dark)
  /// - Tab 2 (`Kế hoạch`): Royal Teal/Indigo `#0D9488` (Light) / `#2DD4BF` (Dark)
  /// - Tab 3 (`Cá nhân`): Royal Violet `#4F46E5` (Light) / `#818CF8` (Dark)
  static Color tabAccentColor(int tabIndex, bool dark) =>
      dark ? const Color(0xFF10B981) : const Color(0xFF007859);

  double? _dragStartX;
  bool _isScrubbing = false;

  void _handlePointerDown(
    double localDx,
    double totalWidth,
    ThemeStudioController? studio,
  ) {
    _dragStartX = localDx;
    _isScrubbing = false;
  }

  void _handlePointerMove(
    double localDx,
    double totalWidth,
    ThemeStudioController? studio,
  ) {
    if (totalWidth <= 0) return;
    if (_dragStartX != null && (localDx - _dragStartX!).abs() > 5.0) {
      _isScrubbing = true;
    }

    if (_isScrubbing) {
      final double normalized = (localDx / totalWidth).clamp(0.0, 0.9999);
      final double fraction = (normalized * 4.0 - 0.5).clamp(0.0, 3.0);
      final int targetIndex = (normalized * 4.0).floor().clamp(0, 3);

      if (_dragTabIndex != targetIndex || _dragFraction != fraction) {
        setState(() {
          _dragFraction = fraction;
          _dragTabIndex = targetIndex;
        });
      }

      if (targetIndex != _lastEmittedIndex) {
        _lastEmittedIndex = targetIndex;
        studio?.performHaptic();
        HapticFeedback.selectionClick();
        widget.onTap(targetIndex);
      }
    }
  }

  void _handlePointerUp() {
    _dragStartX = null;
    _isScrubbing = false;
    if (_dragFraction != null || _dragTabIndex != null) {
      setState(() {
        _dragFraction = null;
        _dragTabIndex = null;
      });
    }
  }

  void _handleTabTap(int tabIndex, ThemeStudioController? studio) {
    final bool wasSelected = widget.index == tabIndex;
    _lastEmittedIndex = tabIndex;
    if (!wasSelected) {
      studio?.performHaptic();
      HapticFeedback.selectionClick();
    }
    widget.onTap(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final dockStyle =
        studio?.dockNavStyle ?? AppDockNavStyle.balancedFloatingCta;
    final dockIconStyle =
        studio?.dockIconStyle ?? AppDockIconStyle.modernLucide;
    final tab0 = _resolveTabIcons(0, dockIconStyle);
    final tab1 = _resolveTabIcons(1, dockIconStyle);
    final tab2 = _resolveTabIcons(2, dockIconStyle);
    final tab3 = _resolveTabIcons(3, dockIconStyle);
    final labelStyle = studio?.dockLabelStyle ?? AppDockLabelStyle.always;
    final tabSelectStyle =
        studio?.tabSelectStyle ?? AppTabSelectStyle.pillHighlight;

    final isBalancedCta = dockStyle == AppDockNavStyle.balancedFloatingCta;
    final isClassic = dockStyle == AppDockNavStyle.classicDock;
    final isCompact = dockStyle == AppDockNavStyle.compactCapsule;
    final isUnderline = dockStyle == AppDockNavStyle.glassNeonUnderline ||
        tabSelectStyle == AppTabSelectStyle.glowUnderline;
    final isPillTabs = dockStyle == AppDockNavStyle.pillTabs;
    final isHyperOs = dockStyle == AppDockNavStyle.hyperOsFloatingBar;
    final isColorOs = dockStyle == AppDockNavStyle.colorOsCurvedDock;
    final isMinimalDot = dockStyle == AppDockNavStyle.minimalistDotDock ||
        tabSelectStyle == AppTabSelectStyle.bounceBadge;
    final isCyberSplit = dockStyle == AppDockNavStyle.cyberpunkSplitDock;
    final isNotchWave = dockStyle == AppDockNavStyle.notchWaveRise;
    final isIslandBubbles = dockStyle == AppDockNavStyle.segmentedIslandBubbles;
    final isGlowTray = dockStyle == AppDockNavStyle.expandedGlowTray;
    final isStealthWire = dockStyle == AppDockNavStyle.stealthWireMinimal;
    final isCockpit = dockStyle == AppDockNavStyle.futuristicCyberCockpit;

    // Default layout: Interactive Apple iOS 18 Dock with Tap + Hold-and-Slide Scrubbing & Floating (+) CTA
    if (isBalancedCta) {
      final tabs = [
        (
          unselected: tab0.unselected,
          selected: tab0.selected,
          label: 'Trang chủ'
        ),
        (
          unselected: tab1.unselected,
          selected: tab1.selected,
          label: 'Tài sản'
        ),
        (
          unselected: tab2.unselected,
          selected: tab2.selected,
          label: 'Kế hoạch'
        ),
        (
          unselected: tab3.unselected,
          selected: tab3.selected,
          label: 'Cá nhân'
        ),
      ];
      return _buildBalancedFloatingCtaDock(context, studio, dark, tabs);
    }

    final double maxWidth = (isCompact || isMinimalDot || isStealthWire)
        ? 370
        : (isClassic
            ? double.infinity
            : (isGlowTray ? 540 : (isHyperOs ? 470 : 500)));

    final EdgeInsets safeMargin = isClassic
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(
            (isCompact || isMinimalDot || isStealthWire) ? 22 : 14,
            0,
            (isCompact || isMinimalDot || isStealthWire) ? 22 : 14,
            isNotchWave ? 6 : 12,
          );

    final BorderRadius borderRadius = isClassic
        ? const BorderRadius.vertical(top: Radius.circular(24))
        : (isHyperOs
            ? BorderRadius.circular(32)
            : (isColorOs
                ? BorderRadius.circular(42)
                : (isStealthWire
                    ? BorderRadius.circular(20)
                    : (isCockpit
                        ? BorderRadius.circular(16)
                        : (isNotchWave
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                                bottomLeft: Radius.circular(36),
                                bottomRight: Radius.circular(36),
                              )
                            : BorderRadius.circular(
                                (isCompact || isMinimalDot) ? 40 : 100))))));

    final borderWidth = studio?.widgetBorderWidth ?? 0.8;
    final bool hasBorder = borderWidth > 0.05;

    final Border? borderStyle;
    if (isCockpit || !hasBorder) {
      borderStyle = null;
    } else if (isClassic) {
      borderStyle = Border(
        top: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.75),
          width: borderWidth,
        ),
      );
    } else if (isHyperOs) {
      borderStyle = Border.all(
        color: (studio?.resolvedPrimary ?? const Color(0xFF0070F3))
            .withValues(alpha: dark ? 0.38 : 0.45),
        width: borderWidth,
      );
    } else if (isColorOs) {
      borderStyle = Border.all(
        color: const Color(0xFF00C4B4).withValues(alpha: dark ? 0.40 : 0.45),
        width: borderWidth,
      );
    } else if (isCyberSplit) {
      borderStyle = Border.all(
        color: const Color(0xFF00E5FF).withValues(alpha: dark ? 0.55 : 0.65),
        width: borderWidth,
      );
    } else if (isStealthWire) {
      borderStyle = Border.all(
        color: dark
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFCBD5E1),
        width: borderWidth,
      );
    } else if (isGlowTray) {
      borderStyle = Border.all(
        color: (studio?.resolvedPrimary ?? const Color(0xFF6366F1))
            .withValues(alpha: dark ? 0.50 : 0.60),
        width: borderWidth,
      );
    } else {
      borderStyle = Border.all(
        color: dark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.75),
        width: borderWidth,
      );
    }

    // Special layout 1: Segmented Island Bubbles: 5 detached floating capsules
    if (isIslandBubbles) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Center(
          heightFactor: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIslandBubble(context, 0, tab0.unselected, tab0.selected,
                  'Trang chủ', studio, dark),
              const SizedBox(width: 6),
              _buildIslandBubble(context, 1, tab1.unselected, tab1.selected,
                  'Tài sản', studio, dark),
              const SizedBox(width: 8),
              _buildCenterAddButton(studio,
                  isCompact: false,
                  isColorOs: false,
                  isHyperOs: false,
                  isNotchWave: false),
              const SizedBox(width: 8),
              _buildIslandBubble(context, 2, tab2.unselected, tab2.selected,
                  'Kế hoạch', studio, dark),
              const SizedBox(width: 6),
              _buildIslandBubble(context, 3, tab3.unselected, tab3.selected,
                  'Cá nhân', studio, dark),
            ],
          ),
        ),
      );
    }

    // Special layout 2: Cyberpunk Neo-Split
    if (isCyberSplit) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (dark ? const Color(0xFF090D1A) : Colors.white)
                          .withValues(alpha: studio?.dockOpacity ?? 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color(0xFF00E5FF)
                            .withValues(alpha: dark ? 0.65 : 0.75),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        _tab(
                            context,
                            0,
                            tab0.unselected,
                            tab0.selected,
                            'Trang chủ',
                            studio,
                            labelStyle,
                            isUnderline,
                            isPillTabs,
                            isMinimalDot,
                            isColorOs,
                            isHyperOs,
                            isCyberSplit,
                            isStealthWire,
                            isCockpit,
                            tabSelectStyle),
                        _tab(
                            context,
                            1,
                            tab1.unselected,
                            tab1.selected,
                            'Tài sản',
                            studio,
                            labelStyle,
                            isUnderline,
                            isPillTabs,
                            isMinimalDot,
                            isColorOs,
                            isHyperOs,
                            isCyberSplit,
                            isStealthWire,
                            isCockpit,
                            tabSelectStyle),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildCenterAddButton(studio,
                      isCompact: false,
                      isColorOs: false,
                      isHyperOs: false,
                      isNotchWave: false),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (dark ? const Color(0xFF090D1A) : Colors.white)
                          .withValues(alpha: studio?.dockOpacity ?? 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border.all(
                        color: const Color(0xFF00E5FF)
                            .withValues(alpha: dark ? 0.65 : 0.75),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        _tab(
                            context,
                            2,
                            tab2.unselected,
                            tab2.selected,
                            'Kế hoạch',
                            studio,
                            labelStyle,
                            isUnderline,
                            isPillTabs,
                            isMinimalDot,
                            isColorOs,
                            isHyperOs,
                            isCyberSplit,
                            isStealthWire,
                            isCockpit,
                            tabSelectStyle),
                        _tab(
                            context,
                            3,
                            tab3.unselected,
                            tab3.selected,
                            'Cá nhân',
                            studio,
                            labelStyle,
                            isUnderline,
                            isPillTabs,
                            isMinimalDot,
                            isColorOs,
                            isHyperOs,
                            isCyberSplit,
                            isStealthWire,
                            isCockpit,
                            tabSelectStyle),
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

    return SafeArea(
      top: false,
      minimum: safeMargin,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isGlowTray)
                Positioned(
                  bottom: -4,
                  left: 20,
                  right: 20,
                  height: 18,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0070F3).withValues(alpha: 0.5),
                          const Color(0xFFEC4899).withValues(alpha: 0.5),
                          const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isNotchWave)
                Positioned(
                  top: -10,
                  child: Container(
                    width: 58,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (dark ? const Color(0xFF101B34) : Colors.white)
                          .withValues(
                              alpha: (studio?.dockOpacity ?? 0.85) * 0.95),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(29)),
                      border: Border(
                        top: BorderSide(
                          color: (studio?.resolvedDockActiveColor ??
                                  const Color(0xFF005FEA))
                              .withValues(alpha: dark ? 0.6 : 0.7),
                          width: 1.4,
                        ),
                        left: BorderSide(
                          color: (studio?.resolvedPrimary ??
                                  const Color(0xFF005FEA))
                              .withValues(alpha: dark ? 0.35 : 0.45),
                          width: 1.0,
                        ),
                        right: BorderSide(
                          color: (studio?.resolvedPrimary ??
                                  const Color(0xFF005FEA))
                              .withValues(alpha: dark ? 0.35 : 0.45),
                          width: 1.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (studio?.resolvedPrimary ??
                                  const Color(0xFF005FEA))
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                  ),
                ),
              Builder(builder: (context) {
                final isLiquid = studio?.isSystemWideLiquidGlass ?? false;
                final primary =
                    studio?.resolvedPrimary ?? const Color(0xFF0070F3);
                final enableSpecular =
                    studio?.liquidGlassSpecularHighlight ?? false;
                final enableCaustics =
                    studio?.liquidGlassCausticRefraction ?? false;

                final List<BoxShadow> dockShadows = [
                  BoxShadow(
                    color: (dark ? Colors.black : const Color(0xFF0E2D6C))
                        .withValues(alpha: dark ? 0.38 : 0.08),
                    blurRadius:
                        (isCompact || isMinimalDot || isStealthWire) ? 14 : 26,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  if (isLiquid)
                    BoxShadow(
                      color: primary.withValues(alpha: dark ? 0.08 : 0.04),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: primary.withValues(alpha: dark ? 0.12 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  if (isGlowTray)
                    BoxShadow(
                      color: primary.withValues(alpha: dark ? 0.18 : 0.10),
                      blurRadius: 24,
                      spreadRadius: -1,
                      offset: const Offset(0, 4),
                    ),
                  if (isHyperOs)
                    BoxShadow(
                      color: primary.withValues(alpha: dark ? 0.25 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    )
                  else if (isColorOs)
                    BoxShadow(
                      color: const Color(0xFF00C4B4)
                          .withValues(alpha: dark ? 0.22 : 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 3),
                    ),
                ];

                final Gradient effectiveDockGradient = isLiquid
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                const Color(0xFF142442).withValues(
                                    alpha:
                                        ((studio?.dockOpacity ?? 0.38) * 0.70)
                                            .clamp(0.18, 0.45)),
                                const Color(0xFF07101E).withValues(
                                    alpha:
                                        ((studio?.dockOpacity ?? 0.38) * 0.85)
                                            .clamp(0.22, 0.50)),
                              ]
                            : [
                                Colors.white.withValues(
                                    alpha:
                                        ((studio?.dockOpacity ?? 0.38) * 0.75)
                                            .clamp(0.18, 0.48)),
                                const Color(0xFFE2F0FD).withValues(
                                    alpha:
                                        ((studio?.dockOpacity ?? 0.38) * 0.50)
                                            .clamp(0.12, 0.38)),
                              ],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: dark
                            ? [
                                (isHyperOs
                                        ? const Color(0xFF0C101C)
                                        : (isColorOs
                                            ? const Color(0xFF0A1820)
                                            : (isCockpit
                                                ? const Color(0xFF080D1A)
                                                : const Color(0xFF101B34))))
                                    .withValues(
                                        alpha: ((studio?.dockOpacity ?? 0.75) *
                                                0.85)
                                            .clamp(0.10, 1.0)),
                                const Color(0xFF070D1B).withValues(
                                    alpha: (studio?.dockOpacity ?? 0.75)
                                        .clamp(0.10, 1.0)),
                              ]
                            : [
                                Colors.white.withValues(
                                    alpha: (studio?.dockOpacity ?? 0.75)
                                        .clamp(0.15, 1.0)),
                                (isColorOs
                                        ? const Color(0xFFE0F7FA)
                                        : const Color(0xFFE5EFFC))
                                    .withValues(
                                        alpha: ((studio?.dockOpacity ?? 0.75) *
                                                0.85)
                                            .clamp(0.10, 1.0)),
                              ],
                      );

                final dockStack = Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        gradient: isLiquid ? effectiveDockGradient : null,
                        color: isLiquid
                            ? null
                            : (dark ? const Color(0xFF0F172A) : Colors.white),
                        border: isLiquid ? null : borderStyle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              (isCompact || isMinimalDot || isStealthWire)
                                  ? 6
                                  : (isClassic ? 14 : 10),
                          vertical: isStealthWire
                              ? 2
                              : ((isCompact || isMinimalDot)
                                  ? 4
                                  : (isHyperOs ? 7 : 6)),
                        ),
                        child: Row(
                          children: [
                            _tab(
                                context,
                                0,
                                tab0.unselected,
                                tab0.selected,
                                'Trang chủ',
                                studio,
                                labelStyle,
                                isUnderline,
                                isPillTabs,
                                isMinimalDot,
                                isColorOs,
                                isHyperOs,
                                isCyberSplit,
                                isStealthWire,
                                isCockpit,
                                tabSelectStyle),
                            _tab(
                                context,
                                1,
                                tab1.unselected,
                                tab1.selected,
                                'Tài sản',
                                studio,
                                labelStyle,
                                isUnderline,
                                isPillTabs,
                                isMinimalDot,
                                isColorOs,
                                isHyperOs,
                                isCyberSplit,
                                isStealthWire,
                                isCockpit,
                                tabSelectStyle),
                            _buildCenterAddButton(
                              studio,
                              isCompact:
                                  isCompact || isMinimalDot || isStealthWire,
                              isColorOs: isColorOs,
                              isHyperOs: isHyperOs,
                              isNotchWave: isNotchWave,
                            ),
                            _tab(
                                context,
                                2,
                                tab2.unselected,
                                tab2.selected,
                                'Kế hoạch',
                                studio,
                                labelStyle,
                                isUnderline,
                                isPillTabs,
                                isMinimalDot,
                                isColorOs,
                                isHyperOs,
                                isCyberSplit,
                                isStealthWire,
                                isCockpit,
                                tabSelectStyle),
                            _tab(
                                context,
                                3,
                                tab3.unselected,
                                tab3.selected,
                                'Cá nhân',
                                studio,
                                labelStyle,
                                isUnderline,
                                isPillTabs,
                                isMinimalDot,
                                isColorOs,
                                isHyperOs,
                                isCyberSplit,
                                isStealthWire,
                                isCockpit,
                                tabSelectStyle),
                          ],
                        ),
                      ),
                    ),
                    if (isLiquid && enableCaustics)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: LiquidRefractionPainter(
                              borderRadius: borderRadius.topLeft.x,
                              tintColor: primary,
                              isDark: dark,
                            ),
                          ),
                        ),
                      ),
                    if (isLiquid && enableSpecular)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: LiquidSpecularBorderPainter(
                              borderRadius: borderRadius.topLeft.x,
                              borderWidth: 1.15,
                              borderGradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.22, 0.75, 1.0],
                                colors: dark
                                    ? const [
                                        Color(0x35FFFFFF),
                                        Color(0x0AFFFFFF),
                                        Color(0x00FFFFFF),
                                        Color(0x04FFFFFF),
                                      ]
                                    : const [
                                        Color(0x40FFFFFF),
                                        Color(0x0EFFFFFF),
                                        Color(0x00FFFFFF),
                                        Color(0x06FFFFFF),
                                      ],
                              ),
                              enableSpecularHighlight: true,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: dockShadows,
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: dockStack,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(
    ThemeStudioController? studio, {
    required bool isCompact,
    required bool isColorOs,
    required bool isHyperOs,
    required bool isNotchWave,
  }) {
    final primaryColor = studio?.dockPlusColor ??
        (isHyperOs
            ? const Color(0xFF0070F3)
            : (isColorOs
                ? const Color(0xFF00C4B4)
                : (studio?.resolvedDockPlusColor ??
                    studio?.resolvedPrimary ??
                    const Color(0xFF0F6E56))));

    final btn = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: 'Thêm giao dịch',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(primaryColor, Colors.white, 0.14)!,
                primaryColor,
                Color.lerp(primaryColor, Colors.black, 0.16)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.36),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onAddTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: isCompact ? 40 : 48,
                height: isCompact ? 40 : 48,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: isCompact ? 22 : 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isNotchWave) {
      return Transform.translate(
        offset: const Offset(0, -14),
        child: btn,
      );
    }
    return btn;
  }

  Widget _buildIslandBubble(
    BuildContext context,
    int tab,
    IconData icon,
    IconData activeIcon,
    String label,
    ThemeStudioController? studio,
    bool dark,
  ) {
    final selected = widget.index == tab;
    final primary = tabAccentColor(tab, dark);
    return GestureDetector(
      onTap: () => _handleTabTap(tab, studio),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              EdgeInsets.symmetric(horizontal: selected ? 14 : 11, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : (dark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.75)),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? primary
                  : (dark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFCBD5E1)),
              width: 1.1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : (dark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    int tab,
    IconData icon,
    IconData activeIcon,
    String label,
    ThemeStudioController? studio,
    AppDockLabelStyle labelStyle,
    bool isUnderline,
    bool isPillTabs,
    bool isMinimalDot,
    bool isColorOs,
    bool isHyperOs,
    bool isCyberSplit,
    bool isStealthWire,
    bool isCockpit,
    AppTabSelectStyle tabSelectStyle,
  ) {
    final selected = widget.index == tab;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isHyperOs
        ? const Color(0xFF0070F3)
        : (isColorOs ? const Color(0xFF00C4B4) : tabAccentColor(tab, dark));
    final color = selected
        ? primaryColor
        : (studio?.resolvedDockInactiveColor(dark) ??
            (dark ? const Color(0xFFA3B4D4) : const Color(0xFF5B6E8C)));

    final bool showLabel = (!isMinimalDot && !isStealthWire) &&
        (labelStyle == AppDockLabelStyle.always ||
            (labelStyle == AppDockLabelStyle.selectedOnly && selected));

    Widget buildIndicator() {
      if (!selected) return const SizedBox.shrink();
      if (isMinimalDot || tabSelectStyle == AppTabSelectStyle.bounceBadge) {
        return Container(
          margin: const EdgeInsets.only(top: 3),
          height: 4.5,
          width: 4.5,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.9),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }
      if (isColorOs) {
        return Container(
          margin: const EdgeInsets.only(top: 2),
          height: 3,
          width: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF00C4B4),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C4B4).withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        );
      }
      if (isUnderline || tabSelectStyle == AppTabSelectStyle.glowUnderline) {
        return Container(
          margin: const EdgeInsets.only(top: 2),
          height: 2.5,
          width: 18,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.8),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.only(top: 3),
        height: 3,
        width: 14,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.55),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      );
    }

    BoxDecoration? getPillDecoration() {
      if (!selected) return null;
      if (tabSelectStyle == AppTabSelectStyle.neonBorder) {
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        );
      }
      if (tabSelectStyle == AppTabSelectStyle.filledIcon) {
        return BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        );
      }
      if (isMinimalDot || isUnderline || isColorOs || isStealthWire) {
        return null;
      }
      if (isCockpit) {
        return BoxDecoration(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1),
        );
      }
      if (isHyperOs) {
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: dark ? 0.28 : 0.16),
              const Color(0xFFFF6B00).withValues(alpha: dark ? 0.16 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 0.8,
          ),
        );
      }
      if (isPillTabs) {
        return BoxDecoration(
          color: primaryColor.withValues(alpha: dark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(16),
        );
      }
      return BoxDecoration(
        color: primaryColor.withValues(alpha: dark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
      );
    }

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: () => _handleTabTap(tab, studio),
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: isStealthWire ? 38 : 46),
              child: Center(
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                    horizontal: isPillTabs && selected ? 10 : 8,
                    vertical: showLabel ? 4 : (isStealthWire ? 4 : 8),
                  ),
                  decoration: getPillDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          selected ? activeIcon : icon,
                          size: showLabel ? 21 : (isStealthWire ? 19 : 23),
                          color: color,
                        ),
                      ),
                      if (showLabel) ...[
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: color,
                                    letterSpacing: -0.2,
                                  ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      buildIndicator(),
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

  ({IconData unselected, IconData selected}) _resolveTabIcons(
      int tabIndex, AppDockIconStyle style) {
    switch (style) {
      case AppDockIconStyle.modernLucide:
        switch (tabIndex) {
          case 0:
            return (unselected: LucideIcons.house, selected: LucideIcons.house);
          case 1:
            return (
              unselected: LucideIcons.wallet_cards,
              selected: LucideIcons.wallet_cards
            );
          case 2:
            return (
              unselected: LucideIcons.target,
              selected: LucideIcons.target
            );
          case 3:
          default:
            return (
              unselected: LucideIcons.circle_user_round,
              selected: LucideIcons.circle_user_round
            );
        }
      case AppDockIconStyle.appleCupertino:
        switch (tabIndex) {
          case 0:
            return (
              unselected: Icons.roofing_outlined,
              selected: Icons.roofing_rounded
            );
          case 1:
            return (
              unselected: Icons.account_balance_wallet_outlined,
              selected: Icons.account_balance_wallet_rounded
            );
          case 2:
            return (
              unselected: Icons.pie_chart_outline_rounded,
              selected: Icons.pie_chart_rounded
            );
          case 3:
          default:
            return (
              unselected: Icons.person_outline_rounded,
              selected: Icons.person_rounded
            );
        }
      case AppDockIconStyle.fintechDuotone:
        switch (tabIndex) {
          case 0:
            return (
              unselected: LucideIcons.layout_grid,
              selected: LucideIcons.layout_grid
            );
          case 1:
            return (
              unselected: LucideIcons.credit_card,
              selected: LucideIcons.credit_card
            );
          case 2:
            return (
              unselected: LucideIcons.target,
              selected: LucideIcons.target
            );
          case 3:
          default:
            return (
              unselected: LucideIcons.user_check,
              selected: LucideIcons.user_check
            );
        }
      case AppDockIconStyle.cyberGlow:
        switch (tabIndex) {
          case 0:
            return (
              unselected: LucideIcons.sparkles,
              selected: LucideIcons.sparkles
            );
          case 1:
            return (
              unselected: LucideIcons.shield,
              selected: LucideIcons.shield_check
            );
          case 2:
            return (
              unselected: LucideIcons.activity,
              selected: LucideIcons.activity
            );
          case 3:
          default:
            return (unselected: LucideIcons.bot, selected: LucideIcons.bot);
        }
      case AppDockIconStyle.minimalistDot:
        switch (tabIndex) {
          case 0:
            return (
              unselected: LucideIcons.compass,
              selected: LucideIcons.compass
            );
          case 1:
            return (
              unselected: LucideIcons.banknote,
              selected: LucideIcons.banknote
            );
          case 2:
            return (
              unselected: LucideIcons.chart_pie,
              selected: LucideIcons.chart_pie
            );
          case 3:
          default:
            return (
              unselected: LucideIcons.circle_user,
              selected: LucideIcons.circle_user_round
            );
        }
      case AppDockIconStyle.materialSystem:
        switch (tabIndex) {
          case 0:
            return (
              unselected: Icons.home_outlined,
              selected: Icons.home_rounded
            );
          case 1:
            return (
              unselected: Icons.account_balance_wallet_outlined,
              selected: Icons.account_balance_wallet_rounded
            );
          case 2:
            return (
              unselected: Icons.pie_chart_outline_rounded,
              selected: Icons.pie_chart_rounded
            );
          case 3:
          default:
            return (
              unselected: Icons.person_outline_rounded,
              selected: Icons.person_rounded
            );
        }
    }
  }

  /// Interactive Apple iOS 18 Dock with Tap + Press-Hold-Slide Horizontal Scrubbing
  /// and Tab-Specific Solid Pill Highlights + Separate Floating (+) Speed-Dial Button.
  /// Interactive Apple Dock matching Image 4 (Active Capsule [Icon + Label] & Inactive [Icon])
  /// with Hold-and-Slide Horizontal Scrubbing & Floating Coral (+) CTA Button.
  Widget _buildBalancedFloatingCtaDock(
    BuildContext context,
    ThemeStudioController? studio,
    bool dark,
    List<({IconData unselected, IconData selected, String label})> tabs,
  ) {
    const double maxWidth = 428;
    final int activeIndex = (_dragTabIndex ?? widget.index).clamp(0, 3);
    final bool isDragging = _dragFraction != null;
    final Color activeAccent = tabAccentColor(activeIndex, dark);
    final double dockBlur = (studio?.dockBlur ?? 18.0).clamp(0.0, 32.0);
    final double dockAlpha =
        (studio?.dockOpacity ?? (dark ? 0.82 : 0.78)).clamp(0.15, 1.0);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Interactive Dock Chassis (Image 4 Design: Pill Dock with Floating Active Capsule)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: dockBlur, sigmaY: dockBlur),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: (dark
                                ? const Color(0xFF0F172A)
                                : Colors.white)
                            .withValues(alpha: dockAlpha),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDragging
                              ? activeAccent.withValues(
                                  alpha: dark ? 0.55 : 0.40)
                              : (dark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : const Color(0xFFCBD5E1)
                                      .withValues(alpha: 0.85)),
                          width: isDragging ? 1.25 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (dark ? Colors.black : const Color(0xFF0F172A))
                                    .withValues(alpha: dark ? 0.40 : 0.08),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: activeAccent.withValues(
                                alpha: isDragging
                                    ? (dark ? 0.24 : 0.12)
                                    : (dark ? 0.10 : 0.04)),
                            blurRadius: isDragging ? 18 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double innerWidth = constraints.maxWidth;

                          return Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (e) => _handlePointerDown(
                              e.localPosition.dx,
                              innerWidth,
                              studio,
                            ),
                            onPointerMove: (e) => _handlePointerMove(
                              e.localPosition.dx,
                              innerWidth,
                              studio,
                            ),
                            onPointerUp: (_) => _handlePointerUp(),
                            onPointerCancel: (_) => _handlePointerUp(),
                            child: Row(
                              children: List.generate(tabs.length, (i) {
                                final tab = tabs[i];
                                final bool isSelected = activeIndex == i;
                                return _buildInteractiveAppleDockTab(
                                  context: context,
                                  tabIndex: i,
                                  unselectedIcon: tab.unselected,
                                  selectedIcon: tab.selected,
                                  label: tab.label,
                                  isSelected: isSelected,
                                  isDragging: isDragging && isSelected,
                                  dark: dark,
                                  studio: studio,
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Separate Floating CTA (+) Button with Customizable Color & Press Bounce
              _FloatingCtaButton(
                onTap: widget.onAddTap,
                accentColor:
                    studio?.dockPlusColor ?? const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveAppleDockTab({
    required BuildContext context,
    required int tabIndex,
    required IconData unselectedIcon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required bool isDragging,
    required bool dark,
    required ThemeStudioController? studio,
  }) {
    final Color activeAccent =
        studio?.dockActiveColor ?? tabAccentColor(tabIndex, dark);
    final Color activeFg = dark ? Colors.white : Colors.white;
    final Color inactiveFg =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      flex: isSelected ? 3 : 2,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              onTap: () => _handleTabTap(tabIndex, studio),
              borderRadius: BorderRadius.circular(100),
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: Duration(milliseconds: isSelected ? 160 : 70),
                curve: Curves.easeOutCubic,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(activeAccent, Colors.white, 0.10)!,
                            activeAccent,
                            Color.lerp(activeAccent, Colors.black, 0.14)!,
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(
                              alpha: dark ? 0.32 : 0.45),
                          width: 1.0,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeAccent.withValues(
                                alpha: dark ? 0.42 : 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? AnimatedScale(
                        scale: isDragging ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutBack,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selectedIcon,
                                  size: 19,
                                  color: activeFg,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: activeFg,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          unselectedIcon,
                          size: 21,
                          color: inactiveFg,
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

class _FloatingCtaButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _FloatingCtaButton({
    required this.onTap,
    this.accentColor = const Color(0xFF10B981),
  });

  @override
  State<_FloatingCtaButton> createState() => _FloatingCtaButtonState();
}

class _FloatingCtaButtonState extends State<_FloatingCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.accentColor;
    final lightStop = Color.lerp(baseColor, Colors.white, 0.14)!;
    final darkStop = Color.lerp(baseColor, Colors.black, 0.18)!;

    return AnimatedScale(
      scale: _isPressed ? 0.90 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutBack,
      child: Tooltip(
        message: 'Thêm mới',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.mediumImpact();
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightStop,
                  baseColor,
                  darkStop,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
