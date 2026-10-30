import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

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
  final bool useGoldenRatio;

  const FinoraAnimatedAmount({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
    this.prefix = '',
    this.suffix = ' đ',
    this.showPositiveSign = false,
    this.useGoldenRatio = true,
  });

  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context);
    final effectiveDuration =
        studio?.getAnimationDuration(duration) ?? duration;
    final effectiveCurve = studio?.getAnimationCurve() ?? curve;

    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: amount.toDouble()),
      duration: effectiveDuration,
      curve: effectiveCurve,
      builder: (context, val, child) {
        final sign = (showPositiveSign && val > 0) ? '+' : '';
        final rounded = val.round();
        final formatted = _formatter.format(rounded.abs());

        if (useGoldenRatio) {
          final suffixStyle = baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 14.0) * 0.72,
            color: baseStyle.color?.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
          );

          return RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (prefix.isNotEmpty)
                  TextSpan(text: prefix, style: baseStyle),
                if (sign.isNotEmpty)
                  TextSpan(text: sign, style: baseStyle),
                TextSpan(text: formatted, style: baseStyle),
                if (suffix.isNotEmpty)
                  TextSpan(text: suffix, style: suffixStyle),
              ],
            ),
          );
        }

        final display = '$prefix$sign$formatted$suffix';
        return Text(
          display,
          style: baseStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// 1B. FINORA ROLLING AMOUNT (Tickers / Rolling Digit Columns)
/// Renders an ultra-luxurious vertical mechanical rolling counter for balances.
class FinoraRollingAmount extends StatefulWidget {
  final num amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final bool showPositiveSign;

  const FinoraRollingAmount({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = ' đ',
    this.showPositiveSign = false,
  });

  @override
  State<FinoraRollingAmount> createState() => _FinoraRollingAmountState();
}

class _FinoraRollingAmountState extends State<FinoraRollingAmount> {
  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context);
    final effectiveDuration =
        studio?.getAnimationDuration(widget.duration) ?? widget.duration;
    final effectiveCurve = studio?.getAnimationCurve() ?? widget.curve;

    final defaultStyle = widget.style ??
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
    final suffixStyle = defaultStyle.copyWith(
      fontSize: (defaultStyle.fontSize ?? 24) * 0.70,
      color: (defaultStyle.color ?? Colors.white).withValues(alpha: 0.85),
      fontWeight: FontWeight.w600,
    );

    final sign = (widget.showPositiveSign && widget.amount > 0) ? '+' : '';
    final formatted = _formatter.format(widget.amount.round().abs());
    final fullNumber = '$sign$formatted';

    final fontSize = defaultStyle.fontSize ?? 24.0;
    final charHeight = fontSize * 1.25;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (widget.prefix.isNotEmpty)
          Text(widget.prefix, style: defaultStyle),
        ...fullNumber.split('').map((char) {
          final digit = int.tryParse(char);
          if (digit != null) {
            return _RollingDigitWheel(
              digit: digit,
              style: defaultStyle,
              duration: effectiveDuration,
              curve: effectiveCurve,
              height: charHeight,
            );
          } else {
            return Text(
              char,
              style: defaultStyle.copyWith(
                color:
                    (defaultStyle.color ?? Colors.white).withValues(alpha: 0.75),
              ),
            );
          }
        }),
        if (widget.suffix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(widget.suffix.trim(), style: suffixStyle),
          ),
      ],
    );
  }
}

class _RollingDigitWheel extends StatelessWidget {
  final int digit;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final double height;

  const _RollingDigitWheel({
    required this.digit,
    required this.style,
    required this.duration,
    required this.curve,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: digit.toDouble()),
          duration: duration,
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -value * height),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(10, (i) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Text(
                        '$i',
                        style: style,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 1C. SPECULAR SHIMMER GLINT (Ánh Sáng Khúc Xạ Lướt Qua Thẻ Kính)
class FinoraShimmerGlint extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final BorderRadius? borderRadius;

  const FinoraShimmerGlint({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 4),
    this.borderRadius,
  });

  @override
  State<FinoraShimmerGlint> createState() => _FinoraShimmerGlintState();
}

class _FinoraShimmerGlintState extends State<FinoraShimmerGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scheduleNextGlint();
  }

  void _scheduleNextGlint() {
    _timer?.cancel();
    _timer = Timer(widget.interval, () {
      if (mounted) {
        _controller.forward(from: 0.0).then((_) {
          if (mounted) _scheduleNextGlint();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (_controller.value == 0.0 || _controller.value == 1.0) {
                    return const SizedBox.shrink();
                  }
                  final progress = _controller.value;
                  return Transform.translate(
                    offset: Offset((progress * 2.5 - 1.25) * 350, 0),
                    child: Transform.rotate(
                      angle: 0.45,
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.28),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
/// Smoothly transitions between pages using subtle horizontal slide + gentle opacity fade
/// while preserving widget state across tabs via IndexedStack.
class FinoraFluidTabSwitcher extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const FinoraFluidTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<FinoraFluidTabSwitcher> createState() => _FinoraFluidTabSwitcherState();
}

class _FinoraFluidTabSwitcherState extends State<FinoraFluidTabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late Animation<Offset> _slide;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.025, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant FinoraFluidTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final dir = widget.currentIndex > _prevIndex ? 1.0 : -1.0;
      _prevIndex = widget.currentIndex;
      _slide = Tween<Offset>(
        begin: Offset(0.022 * dir, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return IndexedStack(
        index: widget.currentIndex,
        children: widget.children,
      );
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.86, end: 1.0).animate(_fade),
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(
          index: widget.currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
}
