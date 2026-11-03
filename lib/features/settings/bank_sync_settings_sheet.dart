import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/services/bank_sync_service.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';

/// Trang / Bottom Sheet Cài Đặt Đọc Biến Động Số Dư (BETA)
/// Tích hợp toàn bộ quyền thông báo, kiểm tra kết nối dịch vụ ngầm,
/// cài đặt quét ví điện tử (MoMo, ZaloPay, Viettel Money, VNPay) & cam kết bảo mật.
class BankSyncSettingsSheet extends StatefulWidget {
  final String userId;
  const BankSyncSettingsSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, {required String userId}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BankSyncSettingsSheet(userId: userId),
      ),
    );
  }

  @override
  State<BankSyncSettingsSheet> createState() => _BankSyncSettingsSheetState();
}

class _BankSyncSettingsSheetState extends State<BankSyncSettingsSheet>
    with WidgetsBindingObserver {
  final _service = BankSyncService();
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _service.isPermissionGranted();
    await _service.checkPendingNotifications();
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: screenH * 0.88,
        child: AnimatedBuilder(
          animation: _service,
          builder: (context, _) {
            final isConnected = _service.connected;
            final isSupported = _service.supported;
            final statusColor = !isSupported
                ? const Color(0xFF64748B)
                : (!_granted
                    ? const Color(0xFFE11D48)
                    : (isConnected
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706)));

            final statusText = !isSupported
                ? 'Không hỗ trợ trên nền tảng này'
                : (!_granted
                    ? 'Chưa cấp quyền'
                    : (isConnected ? 'Đang hoạt động' : 'Cần kết nối lại'));

            return Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Đọc biến động số dư',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'BETA',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),

                // Body ListView
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Section 1: Connection & Permissions Card
                      _buildServiceStatusCard(
                        isDark: isDark,
                        statusColor: statusColor,
                        isConnected: isConnected,
                        isSupported: isSupported,
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Wallet & App Scan Settings
                      _buildScanSettingsCard(isDark),
                      const SizedBox(height: 16),

                      // Section 3: Supported Banks & E-Wallets
                      _buildSupportedAppsCard(isDark),
                      const SizedBox(height: 16),

                      // Section 4: Security & Privacy Guarantee
                      _buildPrivacyGuaranteeCard(isDark),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard({
    required bool isDark,
    required Color statusColor,
    required bool isConnected,
    required bool isSupported,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                ),
                child: Icon(
                  !isSupported
                      ? Icons.phonelink_erase_rounded
                      : (!_granted
                          ? Icons.notifications_paused_rounded
                          : (isConnected
                              ? Icons.verified_user_rounded
                              : Icons.sync_problem_rounded)),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !isSupported
                          ? 'Chỉ khả dụng trên thiết bị Android'
                          : (!_granted
                              ? 'Chưa cấp quyền Đọc thông báo'
                              : (isConnected
                                  ? 'Dịch vụ đang lắng nghe biến động'
                                  : 'Dịch vụ chưa kết nối lại')),
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !_granted
                          ? 'Cần cấp quyền để Finora tự bắt thông báo số dư từ ngân hàng và ví.'
                          : (isConnected
                              ? 'Tự động bóc tách Mã GD, số tiền và giữ lại để bạn kiểm tra.'
                              : 'Nếu Android vừa khởi động lại hoặc tắt app ngầm, hãy kết nối lại.'),
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        height: 1.35,
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
          const SizedBox(height: 14),

          // Action Buttons
          if (isSupported) ...[
            if (!_granted)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await _service.requestPermission();
                    await _refresh();
                  },
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text(
                    'Cấp quyền đọc thông báo',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await _service.reconnect();
                        await _service.requestPostNotifications();
                        await _refresh();
                      },
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text(
                        'Kiểm tra lại',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _service.openAppInfo();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text(
                        'Cài đặt bị hạn chế',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],

          if (_service.lastReceivedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Thông báo gần nhất: ',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanSettingsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0D9488)
                      .withValues(alpha: isDark ? 0.22 : 0.12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Cài đặt quét ứng dụng & ví điện tử',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            title: 'Ví điện tử (MoMo, ZaloPay, Viettel Money, VNPay)',
            subtitle:
                'Tự động nhận diện biến động trừ tiền, chuyển tiền, nạp rút và thanh toán QR',
            value: _service.scanEWallets,
            isDark: isDark,
            onChanged: (v) {
              _service.updateScanSettings(scanEWallets: v);
              setState(() {});
            },
          ),
          Divider(
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          _buildToggleTile(
            title: 'Ghép cặp chuyển khoản cùng máy (Transfer Pairing)',
            subtitle:
                'Tự động khớp khi chuyển tiền giữa 2 tài khoản ngân hàng trên cùng điện thoại',
            value: true,
            isDark: isDark,
            onChanged: null, // Always enabled intelligence
          ),
          Divider(
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          _buildToggleTile(
            title: 'Nhận diện thanh toán thẻ tín dụng (Credit Card)',
            subtitle:
                'Tách riêng dòng tiền trả nợ thẻ, không tính 2 lần vào chi tiêu thực tế',
            value: true,
            isDark: isDark,
            onChanged: null, // Always enabled intelligence
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11,
                  height: 1.35,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          activeColor: const Color(0xFF059669),
          onChanged: onChanged == null
              ? null
              : (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
        ),
      ],
    );
  }

  Widget _buildSupportedAppsCard(bool isDark) {
    const apps = [
      'Vietcombank',
      'Techcombank',
      'MB Bank',
      'ACB',
      'VPBank',
      'BIDV',
      'TPBank',
      'VietinBank',
      'MoMo',
      'ZaloPay',
      'Viettel Money',
      'VNPay',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0284C7)
                      .withValues(alpha: isDark ? 0.22 : 0.12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF0284C7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ngân hàng & Ví điện tử hỗ trợ',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: apps.map((app) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BankIcon(bankName: app, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      app,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyGuaranteeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết an toàn & Riêng tư tuyệt đối',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '100% dữ liệu thông báo được bóc tách nội bộ trực tiếp trên điện thoại của bạn. FINORA tuyệt đối không thu thập mật khẩu, mã OTP hay lịch sử tài khoản ngân hàng. Giao dịch chỉ được lưu khi bạn bấm xác nhận.',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
