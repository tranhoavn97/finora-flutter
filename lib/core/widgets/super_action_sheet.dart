import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../features/transaction/add_transaction_page.dart';
import '../../features/ai/ai_advisor_screen.dart';
import '../../features/qr_pay/qr_scanner_screen.dart';
import '../../features/loan/loan_screen.dart';
import '../../state/theme_studio_controller.dart';

/// FINORA Speed Dial Action Sheet (+)
/// Khi nhấn vào dấu + ở thanh Dock, vẫn giữ nguyên nút dấu + tại đúng vị trí đó
/// (với màu sắc tuỳ chỉnh của nút +) và bung các tuỳ chọn mượt mà phía trên.
void showSuperActionSheet({
  required BuildContext context,
  required String userId,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'SpeedDial',
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.36),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _SpeedDialOverlay(
        userId: userId,
        parentContext: context,
        animation: animation,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

class _SpeedDialOverlay extends StatefulWidget {
  final String userId;
  final BuildContext parentContext;
  final Animation<double> animation;

  const _SpeedDialOverlay({
    required this.userId,
    required this.parentContext,
    required this.animation,
  });

  @override
  State<_SpeedDialOverlay> createState() => _SpeedDialOverlayState();
}

class _SpeedDialOverlayState extends State<_SpeedDialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeAndRun(VoidCallback action) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    Future.microtask(action);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(
      widget.parentContext,
      listen: false,
    );
    final dockStyle =
        studio?.dockNavStyle ?? AppDockNavStyle.balancedFloatingCta;
    final isRightAnchored = dockStyle == AppDockNavStyle.balancedFloatingCta;
    final plusColor = studio?.dockPlusColor ??
        (isRightAnchored
            ? const Color(0xFF10B981)
            : (studio?.resolvedDockPlusColor ?? const Color(0xFF10B981)));
    final lightStop = Color.lerp(plusColor, Colors.white, 0.14)!;
    final darkStop = Color.lerp(plusColor, Colors.black, 0.18)!;

    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom + 12;

    return Stack(
      children: [
        // 1. Frosted Glass Backdrop
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // 2. Speed Dial Fan-Out Stack anchored right above the Dock (+) button
        Positioned(
          left: isRightAnchored ? null : 16,
          right: 16,
          bottom: bottomPadding,
          child: Align(
            alignment:
                isRightAnchored ? Alignment.bottomRight : Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 428),
                child: Column(
                  crossAxisAlignment: isRightAnchored
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header pill
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: plusColor.withValues(alpha: 0.38),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: plusColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'TÁC VỤ NHANH FINORA',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action 5: Trợ lý AI & Quét hoá đơn
                    _buildSpeedDialItem(
                      index: 4,
                      title: 'Trợ lý AI & Quét hoá đơn',
                      subtitle: 'Hỏi đáp tài chính & OCR hoá đơn',
                      icon: LucideIcons.sparkles,
                      gradientColors: const [
                        Color(0xFF059669),
                        Color(0xFF10B981)
                      ],
                      isDark: isDark,
                      isRightAnchored: isRightAnchored,
                      onTap: () => _closeAndRun(() {
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AiAdvisorScreen(userId: widget.userId),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Action 4: Ghi chép Đầu tư
                    _buildSpeedDialItem(
                      index: 3,
                      title: 'Ghi chép Đầu tư',
                      subtitle: 'Vàng, cổ phiếu, tiết kiệm, BĐS',
                      icon: LucideIcons.trending_up,
                      gradientColors: const [
                        Color(0xFFFBBF24),
                        Color(0xFFF59E0B)
                      ],
                      isDark: isDark,
                      isRightAnchored: isRightAnchored,
                      onTap: () => _closeAndRun(() {
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionPage(
                              userId: widget.userId,
                              initialType: 'investment',
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Action 3: Thêm Cho vay / Vay nợ
                    _buildSpeedDialItem(
                      index: 2,
                      title: 'Thêm Cho vay / Vay nợ',
                      subtitle: 'Ghi sổ khoản cho vay hoặc đi vay',
                      icon: LucideIcons.handshake,
                      gradientColors: const [
                        Color(0xFFFB7185),
                        Color(0xFFF43F5E)
                      ],
                      isDark: isDark,
                      isRightAnchored: isRightAnchored,
                      onTap: () => _closeAndRun(() {
                        showModalBottomSheet(
                          context: widget.parentContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddLoanSheet(
                            userId: widget.userId,
                            initialType: 'loan',
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Action 2: Quét mã VietQR & Chuyển tiền
                    _buildSpeedDialItem(
                      index: 1,
                      title: 'Quét mã VietQR & Chuyển tiền',
                      subtitle: 'Mở thẳng App Ngân hàng Vợ/Chồng & ghi sổ',
                      icon: LucideIcons.qr_code,
                      gradientColors: const [
                        Color(0xFF00C2FA),
                        Color(0xFF0EA5E9)
                      ],
                      isDark: isDark,
                      isRightAnchored: isRightAnchored,
                      onTap: () => _closeAndRun(() {
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                QrScannerScreen(userId: widget.userId),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Action 1: Ghi chép giao dịch
                    _buildSpeedDialItem(
                      index: 0,
                      title: 'Ghi chép giao dịch',
                      subtitle: 'Chi tiêu, thu nhập, chuyển khoản',
                      icon: LucideIcons.calendar_check,
                      gradientColors: [lightStop, plusColor],
                      isDark: isDark,
                      isRightAnchored: isRightAnchored,
                      onTap: () => _closeAndRun(() {
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddTransactionPage(userId: widget.userId),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Anchored Dock (+) Button — remains the (+) button at the exact dock spot!
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _controller,
                        curve:
                            const Interval(0.0, 0.75, curve: Curves.easeOutBack),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 62,
                          height: 62,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: plusColor.withValues(alpha: 0.18),
                            border: Border.all(
                              color: plusColor.withValues(alpha: 0.50),
                              width: 1.4,
                            ),
                          ),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [lightStop, plusColor, darkStop],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.78),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: plusColor.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
    required bool isRightAnchored,
    required VoidCallback onTap,
  }) {
    final startInterval = (index * 0.10).clamp(0.0, 0.65);
    final endInterval = (startInterval + 0.40).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
    );

    final cardPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F33) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gradientColors.last.withValues(alpha: isDark ? 0.35 : 0.24),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRightAnchored) ...[
            _buildCircleIcon(icon, gradientColors),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isRightAnchored
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isRightAnchored) ...[
            const SizedBox(width: 12),
            _buildCircleIcon(icon, gradientColors),
          ],
        ],
      ),
    );

    return ScaleTransition(
      scale: animation,
      alignment:
          isRightAnchored ? Alignment.bottomRight : Alignment.bottomCenter,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: GestureDetector(
            onTap: onTap,
            child: cardPill,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, List<Color> gradientColors) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.36),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }
}
