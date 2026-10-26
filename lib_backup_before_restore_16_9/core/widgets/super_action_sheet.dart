import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_colors.dart';
import '../../features/transaction/add_transaction_page.dart';
import '../../features/asset/asset_screen.dart';
import '../../features/ai/ai_advisor_screen.dart';

import '../../features/wallet/add_wallet_page.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/goal/goal_screen.dart';
import '../../features/loan/loan_screen.dart';

void showSuperActionSheet({
  required BuildContext context,
  required String userId,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (ctx) => _SuperActionSheetContent(userId: userId),
  );
}

class _SuperActionSheetContent extends StatelessWidget {
  final String userId;
  const _SuperActionSheetContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Single drag handle bar
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hành động nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Đóng',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Ghi chép giao dịch
            _actionTile(
              context: context,
              title: 'Ghi chép giao dịch',
              subtitle: 'Thêm khoản chi tiêu, thu nhập hoặc chuyển tiền',
              icon: Icons.edit_calendar_rounded,
              gradient: const [Color(0xFF059669), Color(0xFF10B981)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddTransactionPage(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 2. Thêm ví / tài khoản ngân hàng
            _actionTile(
              context: context,
              title: 'Thêm ví & Thẻ thanh toán',
              subtitle: 'Tiền mặt, tài khoản ngân hàng, thẻ tín dụng',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const [Color(0xFF2563EB), Color(0xFF38BDF8)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddWalletPage(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 3. Thêm tài sản đầu tư
            _actionTile(
              context: context,
              title: 'Thêm tài sản tích luỹ & Đầu tư',
              subtitle: 'Vàng, BĐS, Sổ tiết kiệm, Dây hụi, Cổ phiếu...',
              icon: Icons.trending_up_rounded,
              gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddAssetPage(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 4. Ghi nhận nợ / cho vay
            _actionTile(
              context: context,
              title: 'Khoản vay & Sổ nợ',
              subtitle: 'Ghi nhận vay mượn hoặc người khác mượn tiền',
              icon: Icons.handshake_rounded,
              gradient: const [Color(0xFFEA580C), Color(0xFFFB923C)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoanScreen(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 5. Thiết lập ngân sách
            _actionTile(
              context: context,
              title: 'Thiết lập ngân sách',
              subtitle: 'Kiểm soát hạn mức chi tiêu mỗi tháng',
              icon: Icons.pie_chart_rounded,
              gradient: const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BudgetScreen(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 6. Mục tiêu tiết kiệm
            _actionTile(
              context: context,
              title: 'Mục tiêu tiết kiệm',
              subtitle: 'Cột mốc tài chính và kế hoạch tích luỹ',
              icon: Icons.flag_rounded,
              gradient: const [Color(0xFF059669), Color(0xFF34D399)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GoalScreen(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),

            // 7. Trợ lý AI
            _actionTile(
              context: context,
              title: 'Trợ lý AI & Bóc tách hoá đơn',
              subtitle: 'Hỏi đáp tài chính NLP hoặc quét tự động',
              icon: Icons.auto_awesome_rounded,
              gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AiAdvisorScreen(userId: userId),
                  ),
                );
              },
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: secondaryTextColor, size: 22),
          ],
        ),
      ),
    );
  }
}
