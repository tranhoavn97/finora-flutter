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
import '../design_system/app_colors.dart';
import 'glass_widgets.dart';

/// FINORA iOS 27 Liquid Glass Bento Quick Actions Sheet (+)
/// Khi nhấn vào dấu + ở thanh Dock, bung bảng Bento Tác vụ nhanh gọn gàng,
/// icon và nhãn hợp công năng, không dư thừa khoảng trống 2 bên.
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
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.36),
    transitionDuration: const Duration(milliseconds: 240),
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
      duration: const Duration(milliseconds: 300),
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
    final sideMargin = studio?.pageHorizontalMargin ?? 12.0;

    final panelAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return Stack(
      children: [
        // 1. Frosted Glass Backdrop
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // 2. Bento Command Deck anchored above Dock
        Positioned(
          left: sideMargin,
          right: sideMargin,
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
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.90, end: 1.0)
                          .animate(panelAnim),
                      alignment: isRightAnchored
                          ? Alignment.bottomRight
                          : Alignment.bottomCenter,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOut,
                        ),
                        child: FinoraDraggableSheetWrapper(
                          onClose: () => Navigator.of(context).pop(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 6, 12, 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                          .withValues(alpha: 0.90)
                                      : Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.42 : 0.10),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Integrated Drag Handle + Compact Header (zero wasted top space, >=44dp touch zone)
                                    FinoraSheetDragHandle(
                                      padding: const EdgeInsets.only(
                                          top: 3, bottom: 5),
                                      minHeight: 44.0,
                                      onClose: () =>
                                          Navigator.of(context).pop(),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: plusColor.withValues(
                                                  alpha: isDark ? 0.22 : 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            child: Icon(
                                              LucideIcons.zap,
                                              size: 13.5,
                                              color: plusColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tác vụ nhanh',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A))
                                                  .withValues(
                                                      alpha:
                                                          isDark ? 0.08 : 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Vuốt để đóng',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Row 1: 2 Primary Hero Cards (50/50) — Quét QR (Left) & Ghi giao dịch (Right)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildPrimaryHeroCard(
                                            title: 'Quét QR',
                                            subtitle: 'Mở Ngân hàng & Ghi sổ',
                                            icon: LucideIcons.qr_code,
                                            gradientColors: const [
                                              Color(0xFF0EA5E9),
                                              Color(0xFF0284C7),
                                            ],
                                            isDark: isDark,
                                            onTap: () => _closeAndRun(() {
                                              Navigator.of(widget.parentContext)
                                                  .push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      QrScannerScreen(
                                                          userId:
                                                              widget.userId),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildPrimaryHeroCard(
                                            title: 'Ghi giao dịch',
                                            subtitle: 'Thu chi & Chuyển khoản',
                                            icon: Icons.edit_note_rounded,
                                            gradientColors: [
                                              lightStop,
                                              plusColor,
                                            ],
                                            isDark: isDark,
                                            onTap: () => _closeAndRun(() {
                                              Navigator.of(widget.parentContext)
                                                  .push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddTransactionPage(
                                                          userId:
                                                              widget.userId),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),

                                  // Row 2: 3 Compact Secondary Bento Tiles (1/3 each)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCompactBentoTile(
                                          title: 'Trợ lý AI',
                                          subtitle: 'Phân tích & OCR',
                                          icon: LucideIcons.sparkles,
                                          accentColor: AppColors.jointTeal,
                                          isDark: isDark,
                                          onTap: () => _closeAndRun(() {
                                            Navigator.of(widget.parentContext)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) => AiAdvisorScreen(
                                                    userId: widget.userId),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCompactBentoTile(
                                          title: 'Sổ Vay / Nợ',
                                          subtitle: 'Cho vay & Đi vay',
                                          icon: LucideIcons.handshake,
                                          accentColor: const Color(0xFFF43F5E),
                                          isDark: isDark,
                                          onTap: () => _closeAndRun(() {
                                            showModalBottomSheet(
                                              context: widget.parentContext,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (_) => AddLoanSheet(
                                                userId: widget.userId,
                                                initialType: 'loan',
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCompactBentoTile(
                                          title: 'Đầu tư',
                                          subtitle: 'Vàng · Cổ phiếu',
                                          icon: LucideIcons.trending_up,
                                          accentColor: const Color(0xFFF59E0B),
                                          isDark: isDark,
                                          onTap: () => _closeAndRun(() {
                                            Navigator.of(widget.parentContext)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddTransactionPage(
                                                  userId: widget.userId,
                                                  initialType: 'investment',
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Anchored Dock (+) Close Button
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
                          width: 56,
                          height: 56,
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
                                color: plusColor.withValues(alpha: 0.42),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
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

  Widget _buildPrimaryHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final accent = gradientColors.last;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: isDark ? 0.22 : 0.10),
                accent.withValues(alpha: isDark ? 0.10 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.42 : 0.28),
              width: 1.1,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCompactBentoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.72)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
              width: 1.0,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
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
