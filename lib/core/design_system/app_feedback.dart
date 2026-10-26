import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback helper for subtle micro-interactions.
/// Ensures consistent tactile response throughout the luxury UI experience.
class AppFeedback {
  AppFeedback._();

  /// Very light tick for tab changes, chips, segmented controls, or small toggles.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light impact for pressing primary buttons, cards, or FAB.
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for completing a critical action like saving a transaction.
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for destructive operations like deleting an account or reset.
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
}

/// Dynamic Island Style Top Toast Notification
class FinoraTopToast {
  FinoraTopToast._();

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = const Color(0xFF10B981),
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    HapticFeedback.lightImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
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
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                        .withValues(alpha: isDark ? 0.92 : 0.96),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.14 : 0.08),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: widget.iconColor, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
