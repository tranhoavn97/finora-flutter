import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bank_sync_service.dart';
import 'glass_widgets.dart';

/// Luxury Executive Bottom Sheet prompting user to grant Notification Access
/// for automatic Vietnamese banking & wallet transaction capture.
class FinoraBankSyncPermissionDialog extends StatelessWidget {
  const FinoraBankSyncPermissionDialog({super.key});

  static const String prefKeyDismissed = 'finora_bank_sync_prompt_dismissed';

  static Future<bool> shouldPromptOnStartup() async {
    if (kIsWeb) return false;
    final granted = await BankSyncService().isPermissionGranted();
    if (granted) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getInt(prefKeyDismissed) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Prompt again after 24 hours if dismissed
    if (now - lastDismissed < 24 * 60 * 60 * 1000) {
      return false;
    }
    return true;
  }

  static Future<void> show(BuildContext context) async {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => const FinoraBankSyncPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GlassBottomSheet(
      showHandle: true,
      radius: 28,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header with Squircle Icon Badge
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(
                          alpha: isDark ? 0.30 : 0.12,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF059669),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tự động ghi chép thông báo',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nhận diện biến động số dư từ mọi ngân hàng',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. Bento Feature Points
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Hỗ trợ tất cả ngân hàng & ví',
                    subtitle:
                        'Vietcombank, Techcombank, MB, ACB, VPBank, MoMo, ZaloPay, SMS...',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    icon: Icons.shield_rounded,
                    iconColor: const Color(0xFF059669),
                    title: 'Bảo mật 100% trên thiết bị',
                    subtitle:
                        'Hoạt động hoàn toàn Offline, tuyệt đối không đọc mã OTP hoặc mật khẩu.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    icon: Icons.flash_on_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: 'Gợi ý lưu 1 chạm tức thì',
                    subtitle:
                        'Tự động phân tích danh mục thu chi ngay khi ngân hàng gửi thông báo.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. User Instruction Tip Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Khi bấm "Kích hoạt", hãy tìm FINORA trong Cài đặt thông báo và gạt bật cho phép.',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 Mẹo Android 13+: Nếu nút gạt bị mờ hoặc hiện "Ứng dụng bị hạn chế", chạm nút bên dưới để mở ngay Thông tin Finora > chạm 3 chấm góc phải trên cùng > chọn "Cho phép cài đặt bị hạn chế" (Allow restricted settings).',
                    style: TextStyle(
                      fontSize: 11.0,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await BankSyncService().openAppInfo();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 13.5,
                            color: isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mở Thông tin Finora để bấm 3 chấm gỡ hạn chế',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Action Buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF059669).withValues(alpha: 0.40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await BankSyncService().requestPermission();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Kích hoạt quyền đọc thông báo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  prefKeyDismissed,
                  DateTime.now().millisecondsSinceEpoch,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                'Để sau',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
