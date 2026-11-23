import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/bank_sync_service.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_home_widget_card.dart';
import '../../core/widgets/finora_modal_scope.dart';
import '../../core/widgets/finora_notice.dart';
import '../../state/theme_studio_controller.dart';

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
  bool _postNotifGranted = false;
  bool _isChecking = false;

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
    final postGranted = await _service.isPostNotificationsGranted();
    await _service.checkPendingNotifications();
    if (mounted) {
      setState(() {
        _granted = granted;
        _postNotifGranted = postGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FinoraModalScope(
      child: Theme(
        data: FinoraModalScope.opaqueModalTheme(context),
        child: Builder(builder: _buildScopedContent),
      ),
    );
  }

  Widget _buildScopedContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController?>();
    final brandAccent = studio?.resolvedPrimary ?? const Color(0xFF059669);
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
                    : (isConnected ? brandAccent : const Color(0xFF0284C7)));

            final statusText = !isSupported
                ? 'Không hỗ trợ trên nền tảng này'
                : (!_granted
                    ? 'Chưa cấp quyền'
                    : (isConnected ? 'Đang hoạt động' : 'Đã cấp quyền • Sẵn sàng'));

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
                                Flexible(
                                  child: Text(
                                    'Đọc biến động số dư',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
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
                                Expanded(
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
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
                      // Section 0: OS Status Bar & Launcher Icon Badge Notifications
                      _buildSystemNotificationCard(
                        isDark: isDark,
                        isSupported: isSupported,
                        accent: brandAccent,
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Connection & Permissions Card
                      _buildServiceStatusCard(
                        isDark: isDark,
                        statusColor: statusColor,
                        isConnected: isConnected,
                        isSupported: isSupported,
                      ),
                      const SizedBox(height: 16),

                      // Section 1b: Real Recognition Queue Status
                      _buildRecognitionQueueCard(isDark),
                      const SizedBox(height: 16),

                      // Section 1c: Home Screen Widgets (5x2 & 5x4)
                      const FinoraHomeWidgetCard(),
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

  Widget _buildSystemNotificationCard({
    required bool isDark,
    required bool isSupported,
    required Color accent,
  }) {
    final badgeColor =
        _postNotifGranted ? accent : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.45 : 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: isDark ? 0.12 : 0.06),
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
                  color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
                child: Icon(
                  _postNotifGranted
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: badgeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông báo & Số trên biểu tượng app',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13.8,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !isSupported
                          ? 'Chỉ khả dụng trên thiết bị Android.'
                          : (_postNotifGranted
                              ? 'Đang bật: hiện banner thanh trạng thái & đếm số ngoài icon FINORA.'
                              : 'Đang tắt trên thiết bị: hãy bật để nhận thông báo thanh trạng thái & số đếm ngoài icon.'),
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.4,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSupported)
                Switch.adaptive(
                  value: _postNotifGranted,
                  activeThumbColor: accent,
                  activeTrackColor: accent.withValues(alpha: 0.45),
                  onChanged: (_) async {
                    HapticFeedback.selectionClick();
                    if (_postNotifGranted) {
                      await _service.openNotificationSettings();
                    } else {
                      final ok = await _service.requestPostNotifications();
                      if (!ok) {
                        await _service.openNotificationSettings();
                      }
                      await _service.updateAppBadge();
                    }
                    await _refresh();
                  },
                ),
            ],
          ),
          if (isSupported) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (!_postNotifGranted)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final ok = await _service.requestPostNotifications();
                        if (!ok) {
                          await _service.openNotificationSettings();
                        }
                        await _service.updateAppBadge();
                        await _refresh();
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Bật thông báo ngay',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 11),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await _service.openNotificationSettings();
                        await _refresh();
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cài đặt thông báo máy',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.55)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 11),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final pendingTotal = _service.totalBadgeCount;
                        final testBadge = pendingTotal > 0 ? pendingTotal : 1;
                        final shown = await _service.showSystemNotification(
                          title: 'FINORA • Kiểm tra thông báo',
                          body:
                              'Thanh trạng thái & số đếm ($testBadge) trên icon FINORA đang hoạt động bình thường.',
                          channel: 'bank',
                          fromBankSync: true,
                        );
                        await _service.updateAppBadge(testBadge);
                        if (!mounted) return;
                        FinoraNotice.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              shown
                                  ? 'Đã gửi thông báo thanh trạng thái & cập nhật số ($testBadge) lên icon!'
                                  : 'Hệ thống đang chặn thông báo. Hãy bật trong Cài đặt thông báo máy.',
                            ),
                            backgroundColor: shown
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Thử thông báo',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 11),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
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
                                  : 'Đã sẵn sàng nhận thông báo')),
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
                              : 'Quyền hệ thống đã kích hoạt. Dịch vụ tự bắt biến động khi có thông báo ngân hàng mới tới.'),
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
                    shape: const StadiumBorder(),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : () async {
                        HapticFeedback.selectionClick();
                        setState(() => _isChecking = true);
                        await _service.reconnect();
                        for (int i = 0; i < 4 && !_service.connected; i++) {
                          await Future.delayed(const Duration(milliseconds: 250));
                          await _service.checkPendingNotifications();
                        }
                        await _service.requestPostNotifications();
                        await _refresh();
                        final isOk = _service.connected;
                        if (!mounted) return;
                        setState(() => _isChecking = false);
                        if (isOk || _service.connected) {
                          FinoraNotice.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Dịch vụ đọc biến động số dư đã kết nối thành công!'),
                              backgroundColor: Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          FinoraNotice.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi yêu cầu kết nối lại tới hệ thống Android. Dịch vụ sẽ tự kích hoạt khi có thông báo ngân hàng mới.'),
                              backgroundColor: Color(0xFF0284C7),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: _isChecking
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF059669),
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: Text(
                        _isChecking ? 'Đang kiểm tra...' : 'Kiểm tra lại',
                        style: const TextStyle(
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
              'Thông báo gần nhất: ${DateFormat('HH:mm • dd/MM/yyyy').format(_service.lastReceivedAt!)}',
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

  Widget _buildRecognitionQueueCard(bool isDark) {
    final pendingCount = _service.pending.length;
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inbox_rounded,
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
                  'Nhận diện ngân hàng',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendingCount == 0
                      ? 'Chưa có giao dịch chờ xử lý'
                      : 'Có $pendingCount giao dịch chờ xử lý trong hộp chờ',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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
            value: _service.pairTransfers,
            isDark: isDark,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              await _service.updateScanSettings(pairTransfers: v);
              if (mounted) setState(() {});
            },
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
            value: _service.detectCreditCardRepay,
            isDark: isDark,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              await _service.updateScanSettings(detectCreditCardRepay: v);
              if (mounted) setState(() {});
            },
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
          activeThumbColor: const Color(0xFF059669),
          activeTrackColor: const Color(0xFF059669).withValues(alpha: 0.45),
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
