import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shared completion/error notice, above page content and clear of the dock/keyboard.
/// Styled as a luxury Dynamic Island floating capsule with glowing status badge.
class FinoraNotice {
  final BuildContext context;
  FinoraNotice._(this.context);
  static FinoraNotice of(BuildContext context) => FinoraNotice._(context);
  static final _active = <OverlayState, _NoticeEntry>{};

  void hideCurrentSnackBar() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) _active.remove(overlay)?.close();
  }

  void showSnackBar(SnackBar message) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    hideCurrentSnackBar();
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    late final _NoticeEntry current;
    void dismiss() {
      if (_active[overlay] == current) _active.remove(overlay);
      current.close();
    }

    final rawBg = message.backgroundColor;
    final bool isError = rawBg != null &&
        (rawBg == Colors.red ||
            rawBg == Colors.redAccent ||
            (rawBg.r > 0.72 && rawBg.g < 0.35));
    final bool isWarning = rawBg != null &&
        !isError &&
        (rawBg == Colors.orange || (rawBg.r > 0.78 && rawBg.g > 0.45));

    final Color accentColor = isError
        ? const Color(0xFFEF4444)
        : (isWarning
            ? const Color(0xFFF59E0B)
            : (rawBg ?? const Color(0xFF10B981)));

    final Color capsuleFill = isError
        ? const Color(0xFF2A0E17)
        : (isWarning ? const Color(0xFF281A0B) : const Color(0xFF0A261F));

    final IconData statusIcon = isError
        ? Icons.error_outline_rounded
        : (isWarning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: media.padding.top + 8,
        left: 14,
        right: 14,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Dismissible(
              key: ObjectKey(current),
              direction: DismissDirection.up,
              onDismissed: (_) => dismiss(),
              child: Semantics(
                liveRegion: true,
                container: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (ctx, val, child) => Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - val) * -10.0),
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * val,
                        child: child,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Material(
                        key: const ValueKey('finora-top-notice'),
                        color: capsuleFill.withValues(alpha: 0.94),
                        elevation: 0,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: accentColor.withValues(alpha: 0.48),
                            width: 1.2,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                accentColor.withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                          child: IconTheme(
                            data: const IconThemeData(
                              color: Colors.white,
                              size: 18,
                            ),
                            child: DefaultTextStyle(
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1.3,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          accentColor.withValues(alpha: 0.24),
                                      border: Border.all(
                                        color:
                                            accentColor.withValues(alpha: 0.55),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: message.content,
                                    ),
                                  ),
                                  if (message.action != null) ...[
                                    const SizedBox(width: 4),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            accentColor.withValues(alpha: 0.28),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: const StadiumBorder(),
                                      ),
                                      onPressed: () {
                                        dismiss();
                                        message.action!.onPressed();
                                      },
                                      child: Text(
                                        message.action!.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                  IconButton(
                                    tooltip: 'Đóng thông báo',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: dismiss,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.white70,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
    current = _NoticeEntry(entry);
    entry.addListener(() {
      if (!entry.mounted) {
        current.timer?.cancel();
        if (_active[overlay] == current) _active.remove(overlay);
      }
    });
    _active[overlay] = current;
    overlay.insert(entry);
    message.onVisible?.call();
    if (!(media.accessibleNavigation && message.action != null)) {
      current.timer = Timer(message.duration, dismiss);
    }
  }
}

class _NoticeEntry {
  final OverlayEntry entry;
  Timer? timer;
  bool closed = false;
  _NoticeEntry(this.entry);
  void close() {
    if (closed) return;
    closed = true;
    timer?.cancel();
    // An overlay can be disposed by navigation/test teardown before the timer.
    entry.remove();
    entry.dispose();
  }
}
