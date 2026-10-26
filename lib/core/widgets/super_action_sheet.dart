import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../theme/finora_tokens.dart';
import 'glass_widgets.dart';
import '../../features/transaction/add_transaction_page.dart';
import '../../features/ai/ai_advisor_screen.dart';
import '../../features/qr_pay/qr_scanner_screen.dart';
import '../../features/loan/loan_screen.dart';

/// FINORA Design System 2026 — Super Action Sheet (+)
/// Board 03 Screen 01: Khay tác vụ nhanh phong cách Ledger 2026
void showSuperActionSheet({
  required BuildContext context,
  required String userId,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.38),
    isScrollControlled: true,
    builder: (sheetContext) => _SuperActionSheetContent(
      userId: userId,
      parentContext: context,
    ),
  );
}

class _SuperActionSheetContent extends StatelessWidget {
  final String userId;
  final BuildContext parentContext;

  const _SuperActionSheetContent({
    required this.userId,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: FinoraTokens.line(isDark),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: FinoraTokens.line(isDark),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tác vụ nhanh',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FinoraTokens.ink(isDark),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chọn loại ghi chép bạn muốn thực hiện',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      color: FinoraTokens.inkSecondary(isDark),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FinoraTokens.sunken(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FinoraTokens.line(isDark),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: FinoraTokens.ink(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Action Cards
          _buildActionCard(
            context: context,
            isDark: isDark,
            title: 'Ghi chép giao dịch',
            subtitle: 'Chi tiêu, thu nhập hoặc chuyển khoản nội bộ',
            icon: LucideIcons.pencil,
            tileBg: FinoraTokens.ink(isDark),
            tileFg: FinoraTokens.bg(isDark),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionPage(userId: userId),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildActionCard(
            context: context,
            isDark: isDark,
            title: 'Quét mã VietQR',
            subtitle: 'Đọc QR thanh toán, tự động bóc tách hoá đơn',
            icon: LucideIcons.qr_code,
            tileBg: FinoraTokens.moss,
            tileFg: Colors.white,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => QrScannerScreen(userId: userId),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildActionCard(
            context: context,
            isDark: isDark,
            title: 'Ghi sổ nợ / Cho vay',
            subtitle: 'Theo dõi tiến độ trả và nhắc nợ thông minh',
            icon: LucideIcons.handshake,
            tileBg: FinoraTokens.sunken(isDark),
            tileFg: FinoraTokens.ink(isDark),
            onTap: () {
              Navigator.of(context).pop();
              showFinoraGlassModalBottomSheet(
                context: parentContext,
                showHandle: false,
                builder: (_) => AddLoanSheet(
                  userId: userId,
                  initialType: 'lent',
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildActionCard(
            context: context,
            isDark: isDark,
            title: 'Cố vấn Finora AI',
            subtitle: 'Bóc tách cơ cấu chi & gợi ý tiết kiệm thông minh',
            icon: LucideIcons.sparkles,
            tileBg: FinoraTokens.sunken(isDark),
            tileFg: FinoraTokens.ink(isDark),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => AiAdvisorScreen(
                    userId: userId,
                    screenContext: 'Hành động nhanh',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildActionCard(
            context: context,
            isDark: isDark,
            title: 'Ghi nhận Đầu tư',
            subtitle: 'Vàng, cổ phiếu, quỹ tích lũy, BĐS',
            icon: LucideIcons.trending_up,
            tileBg: FinoraTokens.sunken(isDark),
            tileFg: FinoraTokens.ink(isDark),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionPage(
                    userId: userId,
                    initialType: 'investment',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tileBg,
    required Color tileFg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FinoraTokens.sunken(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FinoraTokens.line(isDark).withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: tileFg,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FinoraTokens.ink(isDark),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        color: FinoraTokens.inkSecondary(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: FinoraTokens.inkTertiary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
