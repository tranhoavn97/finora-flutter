import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 1. FINORA ANIMATED AMOUNT (Count-up & Smooth Value Transition)
/// Smoothly interpolates from the previous numeric value to the target value
/// using Curves.fastOutSlowIn, formatting with standard Vietnamese separators (12.345.000 đ).
class FinoraAnimatedAmount extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final bool showPositiveSign;

  const FinoraAnimatedAmount({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
    this.prefix = '',
    this.suffix = ' đ',
    this.showPositiveSign = false,
  });

  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: amount.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final sign = (showPositiveSign && val > 0) ? '+' : '';
        final rounded = val.round();
        final formatted = _formatter.format(rounded.abs());
        final display = '$prefix$sign$formatted$suffix';
        return Text(
          display,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// 2. FINORA SHIMMER (Liquid Glass Shimmer Loading)
/// Renders an ambient ice-blue/cyan sheen sweeping across a frosted glass card.
class FinoraShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const FinoraShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  State<FinoraShimmer> createState() => _FinoraShimmerState();
}

class _FinoraShimmerState extends State<FinoraShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.45)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.65);
    final highlightColor = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.85);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (v * 3.0), -0.5),
              end: Alignment(0.5 + (v * 3.0), 0.5),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// 3. FINORA STAGGERED ITEM (Cascade entrance animation for lists & cards)
class FinoraStaggeredItem extends StatefulWidget {
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double slideOffset;
  final Widget child;

  const FinoraStaggeredItem({
    super.key,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 14.0,
    required this.child,
  });

  @override
  State<FinoraStaggeredItem> createState() => _FinoraStaggeredItemState();
}

class _FinoraStaggeredItemState extends State<FinoraStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<double>(
      begin: widget.slideOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delay = widget.baseDelay * widget.index.clamp(0, 10);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 4. FINORA FLUID TAB SWITCHER
/// Smoothly transitions between pages using subtle horizontal slide + gentle opacity fade.
class FinoraFluidTabSwitcher extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const FinoraFluidTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0.0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: children[currentIndex],
      ),
    );
  }
}
