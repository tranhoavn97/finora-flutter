import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/glassmorphism_tokens.dart';

/// Floating Translucent Rounded Glass Dock Navigation.
/// Standardized with Glassmorphism 2.0 tokens (specular rim, calibrated blur, soft depth shadow).
class FinoraNavigation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 4 : 16.0;

    final bgColor =
        dark ? GlassmorphismTokens.navFillDark : GlassmorphismTokens.navFillLight;

    final borderGradient = GlassmorphismTokens.cardBorderGradient(dark);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: GlassmorphismTokens.navShadow(dark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassmorphismTokens.navBlur,
              sigmaY: GlassmorphismTokens.navBlur,
            ),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Stack(
                children: [
                  // Directional Specular Border Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _NavSpecularBorderPainter(
                          borderRadius: 999,
                          borderWidth: GlassmorphismTokens.borderThin,
                          borderGradient: borderGradient,
                        ),
                      ),
                    ),
                  ),

                  // Navigation Tabs
                  Row(
                    children: [
                      _tab(
                        context,
                        tab: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Tổng quan',
                      ),
                      _tab(
                        context,
                        tab: 1,
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Giao dịch',
                      ),
                      _centerAddButton(context),
                      _tab(
                        context,
                        tab: 2,
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: 'Ví & Thẻ',
                      ),
                      _tab(
                        context,
                        tab: 3,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Cá nhân',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerAddButton(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onAddTap();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GlassmorphismTokens.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GlassmorphismTokens.primary.withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required int tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = index == tab;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const selectedColor = GlassmorphismTokens.primary;
    const unselectedColor = GlassmorphismTokens.neutral;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) {
            HapticFeedback.selectionClick();
            onTap(tab);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? GlassmorphismTokens.primary
                    .withValues(alpha: dark ? 0.22 : 0.14)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 21,
                color: selected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? selectedColor : unselectedColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the floating navigation island directional specular border.
class _NavSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient borderGradient;

  const _NavSpecularBorderPainter({
    required this.borderRadius,
    this.borderWidth = 0.8,
    required this.borderGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final half = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      half,
      half,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0.0, borderRadius - half)),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    // Specular apex highlight along top-left curve
    if (size.width > 24 && size.height > 24) {
      final specularPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = borderWidth * 1.3
        ..shader = ui.Gradient.linear(
          Offset(half, half),
          Offset(size.width * 0.35, half + 4),
          const [
            Color(0xB3FFFFFF), // Crisp specular apex
            Color(0x28FFFFFF), // Soft dissipation
            Color(0x00FFFFFF), // Transparent
          ],
          const [0.0, 0.6, 1.0],
        );

      final startX = math.min(
        half + math.max(0.0, borderRadius) * 0.5,
        size.width * 0.35,
      );
      if (startX < size.width * 0.35) {
        final highlightPath = Path()
          ..moveTo(startX, half)
          ..lineTo(size.width * 0.35, half);

        canvas.drawPath(highlightPath, specularPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NavSpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderGradient != borderGradient;
}
