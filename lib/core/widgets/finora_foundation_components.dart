import 'package:flutter/material.dart';

import '../theme/finora_tokens.dart';
import '../utils/formatters.dart';
import 'finora_privacy_mask.dart';

/// 1. FinoraPageHeader — Tiêu đề trang chuẩn mực theo từng nhiệm vụ
class FinoraPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool compact;

  const FinoraPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.showBackButton = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 4 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: FinoraTokens.text(isDark),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: FinoraTokens.text(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: FinoraTokens.textSub(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 2. FinoraSectionHeading — Tiêu đề nhóm + hành động ngắn gọn
class FinoraSectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FinoraSectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FinoraTokens.text(isDark),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FinoraTokens.brand(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3. FinoraAmountText — Hiển thị số tiền chuẩn hóa (tabular figures, privacy mask, wrap thông minh)
class FinoraAmountText extends StatelessWidget {
  final int amount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool showSign;
  final bool isProtected;
  final bool isExpense;

  const FinoraAmountText({
    super.key,
    required this.amount,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.showSign = false,
    this.isProtected = false,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color effectiveColor = color ?? FinoraTokens.text(isDark);
    if (color == null && showSign) {
      if (isExpense || amount < 0) {
        effectiveColor = FinoraTokens.expense(isDark);
      } else if (amount > 0) {
        effectiveColor = FinoraTokens.income(isDark);
      }
    }

    String formatted = Formatters.formatCurrency(amount.abs());
    if (showSign) {
      if (isExpense || amount < 0) {
        formatted = '-$formatted';
      } else if (amount > 0) {
        formatted = '+$formatted';
      }
    }

    return FinoraPrivacyMask(
      isProtected: isProtected,
      child: Text(
        formatted,
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.4,
          color: effectiveColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 4. FinoraPrimaryButton — Nút chính dạng Capsule 48-52dp theo chuẩn Apple
class FinoraPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;

  const FinoraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = FinoraTokens.primary(isDark);
    final fg = FinoraTokens.onPrimary(isDark);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinoraTokens.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 5. FinoraSecondaryButton — Nút phụ nền mềm (mint/subtle surface) chữ xanh đậm
class FinoraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const FinoraSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA);
    final fg = FinoraTokens.brand(isDark);

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(
            color: isDark ? const Color(0xFF354352) : const Color(0xFFDEE7F0),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinoraTokens.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. FioMascotWidget — Linh vật Rồng ngọc Fio đồng hành cùng Finora
enum FioMood { greeting, listening, thinking, done, caution, milestone }

class FioMascotWidget extends StatelessWidget {
  final double size;
  final FioMood mood;

  const FioMascotWidget({
    super.key,
    this.size = 40,
    this.mood = FioMood.greeting,
  });

  String get _assetForMood {
    switch (mood) {
      case FioMood.milestone:
      case FioMood.done:
        return 'assets/mascot/expression-04-excited.png';
      case FioMood.caution:
        return 'assets/mascot/expression-03-focused.png';
      case FioMood.listening:
      case FioMood.thinking:
        return 'assets/mascot/expression-02-confident.png';
      case FioMood.greeting:
        return 'assets/mascot/expression-01-happy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetForMood,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => CustomPaint(
          size: Size(size, size),
          painter: _FioPainter(mood: mood, isDark: isDark),
        ),
      ),
    );
  }
}

class _FioPainter extends CustomPainter {
  final FioMood mood;
  final bool isDark;

  _FioPainter({required this.mood, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Linh vật Rồng Ngọc Finora: Nền ngọc lục bảo + sừng vàng + đồng xu tài chính
    final paint = Paint()..isAntiAlias = true;

    // Soft base shadow
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.84, w * 0.6, h * 0.1),
      paint..color = (isDark ? Colors.black : const Color(0xFF003D35)).withValues(alpha: 0.16),
    );

    // Dragon Body (Emerald gradient)
    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.20)
      ..cubicTo(w * 0.74, h * 0.18, w * 0.86, h * 0.42, w * 0.82, h * 0.68)
      ..cubicTo(w * 0.78, h * 0.86, w * 0.64, h * 0.90, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.36, h * 0.90, w * 0.22, h * 0.86, w * 0.18, h * 0.68)
      ..cubicTo(w * 0.14, h * 0.42, w * 0.26, h * 0.18, w * 0.50, h * 0.20)
      ..close();

    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF34D399), Color(0xFF00866A), Color(0xFF003D35)],
    ).createShader(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.72));
    canvas.drawPath(bodyPath, paint);
    paint.shader = null;

    // Cute Dragon Horns (Gold Accent)
    final hornPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leftHorn = Path()
      ..moveTo(w * 0.34, h * 0.24)
      ..cubicTo(w * 0.26, h * 0.12, w * 0.28, h * 0.04, w * 0.32, h * 0.02)
      ..cubicTo(w * 0.37, h * 0.04, w * 0.38, h * 0.14, w * 0.40, h * 0.22)
      ..close();
    final rightHorn = Path()
      ..moveTo(w * 0.66, h * 0.24)
      ..cubicTo(w * 0.74, h * 0.12, w * 0.72, h * 0.04, w * 0.68, h * 0.02)
      ..cubicTo(w * 0.63, h * 0.04, w * 0.62, h * 0.14, w * 0.60, h * 0.22)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);
    canvas.drawPath(rightHorn, hornPaint);

    // Cream/Mint Belly
    final bellyPaint = Paint()
      ..color = const Color(0xFFE8F8F2)
      ..style = PaintingStyle.fill;
    final bellyPath = Path()
      ..moveTo(w * 0.50, h * 0.48)
      ..cubicTo(w * 0.65, h * 0.48, w * 0.70, h * 0.72, w * 0.64, h * 0.86)
      ..cubicTo(w * 0.56, h * 0.89, w * 0.44, h * 0.89, w * 0.36, h * 0.86)
      ..cubicTo(w * 0.30, h * 0.72, w * 0.35, h * 0.48, w * 0.50, h * 0.48)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);

    // Eyes
    paint.color = const Color(0xFF003D35);
    canvas.drawCircle(Offset(w * 0.40, h * 0.38), w * 0.045, paint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.38), w * 0.045, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.41, h * 0.37), w * 0.015, paint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.37), w * 0.015, paint);

    // Golden Coin
    paint.color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(w * 0.50, h * 0.68), w * 0.11, paint);
  }

  @override
  bool shouldRepaint(covariant _FioPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.isDark != isDark;
}

/// 7. FinoraAssistantInsightCard — Thẻ nhận định thông minh của Fio
class FinoraAssistantInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final String? evidence;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FinoraAssistantInsightCard({
    super.key,
    required this.title,
    required this.insight,
    this.evidence,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2531) : Colors.white,
        borderRadius: BorderRadius.circular(FinoraTokens.radiusCard),
        border: Border.all(
          color: isDark ? const Color(0xFF354352) : const Color(0xFFDEE7F0),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FioMascotWidget(size: 32, mood: FioMood.greeting),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: FinoraTokens.brand(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: FinoraTokens.text(isDark),
            ),
          ),
          if (evidence != null) ...[
            const SizedBox(height: 6),
            Text(
              evidence!,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                color: FinoraTokens.textSub(isDark),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
                    borderRadius: BorderRadius.circular(FinoraTokens.radiusPill),
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: FinoraTokens.brand(isDark),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
