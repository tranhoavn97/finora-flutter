import 'package:flutter/material.dart';
import '../frosted_glass_tokens.dart';

/// Modal Bottom Sheet implementing Apple VisionOS Frosted Glass depth.
class FrostedNeoSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final double maxHeightFactor;

  const FrostedNeoSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.maxHeightFactor = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * maxHeightFactor,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FrostedGlassTokens.radiusSheet),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(FrostedGlassTokens.radiusSheet),
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // VisionOS Grab Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.24)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (title != null || trailing != null) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          if (title != null)
                            Expanded(
                              child: Text(
                                title!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? FrostedGlassTokens.darkTextPrimary
                                      : FrostedGlassTokens.lightTextPrimary,
                                ),
                              ),
                            ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: child,
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

/// Helper function to open a Frosted Neo-Glass Bottom Sheet
Future<T?> showFrostedNeoSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  Widget? trailing,
  double maxHeightFactor = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => FrostedNeoSheet(
      title: title,
      trailing: trailing,
      maxHeightFactor: maxHeightFactor,
      child: child,
    ),
  );
}
