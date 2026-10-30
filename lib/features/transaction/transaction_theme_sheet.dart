import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/theme_studio_controller.dart';

/// Modal Tùy Biến Theme & Phong Cách Danh Sách Giao Dịch (Redesigned Bento Preview Studio)
Future<void> showTransactionThemeModal(BuildContext context) async {
  HapticFeedback.mediumImpact();
  await showFinoraGlassModalBottomSheet<void>(
    context: context,
    showHandle: true,
    builder: (ctx) => const _TransactionThemeModalContent(),
  );
}

class _TransactionThemeModalContent extends StatelessWidget {
  const _TransactionThemeModalContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController>();
    final currentStyle = studio.transactionListStyle;

    final styles = [
      (
        AppTransactionListStyle.modernStreamlined,
        '1. Pha lê Zenvest',
        'Avatar Vợ/Chồng lồng góc & chip ví rút gọn',
        Icons.auto_awesome_mosaic_rounded,
        const Color(0xFF00866A),
      ),
      (
        AppTransactionListStyle.bentoCards,
        '2. Hộp Ngọc Bento',
        'Thẻ Bento 2 tầng bo 24px, huy hiệu Vợ/Chồng nổi',
        Icons.dashboard_customize_rounded,
        const Color(0xFF0EA5E9),
      ),
      (
        AppTransactionListStyle.timelineRail,
        '3. Trục Thời Gian',
        'Cột giờ HH:mm bên trái nối hạt ngọc phát sáng',
        Icons.timeline_rounded,
        const Color(0xFF8B5CF6),
      ),
      (
        AppTransactionListStyle.magazineLedger,
        '4. Sổ Cái Hoàng Gia',
        'Ruy-băng màu dọc 6px & chữ số kế toán',
        Icons.menu_book_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        AppTransactionListStyle.compactTable,
        '5. Bảng Vi Mạch',
        'Siêu gọn 1 dòng: Avatar Vợ/Chồng + Tên + Ví ngắn',
        Icons.table_rows_rounded,
        const Color(0xFFEC4899),
      ),
      (
        AppTransactionListStyle.minimalDivided,
        '6. Lụa Phẳng Tinh Khiết',
        'Không khung hộp, kẻ chỉ mảnh kèm avatar Vợ/Chồng',
        Icons.horizontal_rule_rounded,
        const Color(0xFF64748B),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Banner with 3D Finora Mascot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF063B2D), Color(0xFF0F6E56), Color(0xFF2E1065)]
                    : const [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFEDE9FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const FinoraMascotImage(
                  pose: FinoraMascotPose.happy,
                  size: 48,
                  withGlow: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: isDark ? 0.25 : 0.16),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'FINORA STUDIO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF0F6E56),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giao diện danh sách giao dịch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Áp dụng đồng bộ cho Trang chủ & Sổ giao dịch',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Live Preview Strip of Selected Style
          _buildLivePreviewStrip(context, currentStyle, isDark),

          const SizedBox(height: 14),

          // 3. 2-Column Visual Bento Grid of 6 Styles
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: styles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final (style, title, subtitle, icon, accent) = styles[index];
              final isSelected = currentStyle == style;
              return _buildStyleBentoCard(
                context: context,
                style: style,
                isDark: isDark,
                isSelected: isSelected,
                title: title,
                subtitle: subtitle,
                icon: icon,
                accentColor: accent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  studio.setTransactionListStyle(style);
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // 4. Done Button
          SizedBox(
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6E56), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text(
                  'Hoàn tất & Áp dụng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewStrip(
    BuildContext context,
    AppTransactionListStyle style,
    bool isDark,
  ) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  size: 13, color: Color(0xFF10B981)),
              const SizedBox(width: 5),
              Text(
                'XEM TRƯỚC TRỰC TIẾP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSampleTransactionPreview(style, isDark),
        ],
      ),
    );
  }

  Widget _buildSampleTransactionPreview(
    AppTransactionListStyle style,
    bool isDark,
  ) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardSurface = isDark ? const Color(0xFF1E293B) : Colors.white;

    Widget rowContent({bool compact = false}) {
      return Row(
        children: [
          Container(
            width: compact ? 28 : 34,
            height: compact ? 28 : 34,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
            ),
            child: Icon(
              Icons.coffee_rounded,
              size: compact ? 15 : 18,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cà phê Highlands sáng',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Ăn uống · Vietcombank · 08:30',
                  style: TextStyle(
                    fontSize: compact ? 9.5 : 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-55.000 ₫',
            style: TextStyle(
              fontSize: compact ? 12 : 13.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFDC2626),
              fontFamily:
                  style == AppTransactionListStyle.magazineLedger ? 'monospace' : null,
            ),
          ),
        ],
      );
    }

    switch (style) {
      case AppTransactionListStyle.timelineRail:
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 28,
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: rowContent(),
              ),
            ),
          ],
        );

      case AppTransactionListStyle.bentoCards:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: rowContent(),
        );

      case AppTransactionListStyle.modernStreamlined:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: cardSurface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: rowContent(),
        );

      case AppTransactionListStyle.magazineLedger:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: cardSurface,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4.5, color: const Color(0xFFF59E0B)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: rowContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case AppTransactionListStyle.compactTable:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: rowContent(compact: true),
        );

      case AppTransactionListStyle.minimalDivided:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                width: 0.9,
              ),
            ),
          ),
          child: rowContent(),
        );
    }
  }

  Widget _buildStyleBentoCard({
    required BuildContext context,
    required AppTransactionListStyle style,
    required bool isDark,
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.22 : 0.10)
                : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.70)
                    : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.28 : 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon + Checkmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : accentColor,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : (isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                ],
              ),
              const Spacer(),
              // Miniature schematic wireframe
              _buildMiniWireframe(style, accentColor, isDark),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniWireframe(
    AppTransactionListStyle style,
    Color accent,
    bool isDark,
  ) {
    final barBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    switch (style) {
      case AppTransactionListStyle.timelineRail:
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                Container(width: 1.5, height: 10, color: accent.withValues(alpha: 0.4)),
                Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: barBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: barBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case AppTransactionListStyle.bentoCards:
        return Column(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        );
      case AppTransactionListStyle.modernStreamlined:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: barBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(height: 5, color: accent.withValues(alpha: 0.4)),
              const SizedBox(height: 3),
              Container(height: 5, color: accent.withValues(alpha: 0.2)),
            ],
          ),
        );
      case AppTransactionListStyle.magazineLedger:
        return Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      case AppTransactionListStyle.compactTable:
        return Column(
          children: [
            Container(height: 4, color: accent.withValues(alpha: 0.35)),
            const SizedBox(height: 3),
            Container(height: 4, color: barBg),
            const SizedBox(height: 3),
            Container(height: 4, color: barBg),
          ],
        );
      case AppTransactionListStyle.minimalDivided:
        return Column(
          children: [
            Container(height: 5, color: barBg),
            const SizedBox(height: 3),
            Container(height: 1, color: accent.withValues(alpha: 0.5)),
            const SizedBox(height: 3),
            Container(height: 5, color: barBg),
          ],
        );
    }
  }
}
