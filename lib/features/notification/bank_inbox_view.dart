import '../../core/widgets/adaptive_glass_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/services/bank_notification_parser.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';

class BankInboxView extends StatefulWidget {
  final String userId;
  final double? topPadding;
  const BankInboxView({super.key, required this.userId, this.topPadding});

  @override
  State<BankInboxView> createState() => _BankInboxViewState();
}

class _BankInboxViewState extends State<BankInboxView> {
  final _bank = BankSyncService();
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _bank.isPermissionGranted();
    await _bank.reconnect();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _review(ParsedBankTransaction tx) async {
    await BankTransactionPromptSheet.show(
      context,
      transaction: tx,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bank,
      builder: (context, _) {
        final pending = _bank.pending;
        final unrecognized = _bank.unrecognized;
        final totalCount = pending.length + unrecognized.length;

        return RefreshIndicator(
          color: const Color(0xFF059669),
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, widget.topPadding ?? 14, 16, 36),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              if (totalCount > 0) ...[
                // Action toolbar moved out of header: Xoá tất cả giao dịch chờ
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.80)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã bóc tách $totalCount biến động',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor:
                                  isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              title: const Text('Xoá tất cả giao dịch chờ?'),
                              content: Text(
                                  'Bỏ qua toàn bộ $totalCount biến động số dư đang chờ? Các giao dịch này sẽ không được ghi vào sổ.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Huỷ'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                  ),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Xoá tất cả'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _bank.acknowledgeAll();
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: isDark ? 0.20 : 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFFE11D48),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Xoá tất cả',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFFB7185)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (totalCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.18 : 0.10),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 30,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Không có giao dịch ngân hàng chờ xử lý',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khi ngân hàng hoặc ví điện tử báo biến động số dư, Finora sẽ tự bóc tách Mã GD và giữ lại ở đây để bạn kiểm tra.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ...pending.map(
                (tx) => _PendingTile(
                  tx: tx,
                  onReview: () => _review(tx),
                  onDismiss: () => _bank.acknowledge(tx.rawId),
                ),
              ),
              if (unrecognized.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thông báo ngân hàng chưa đọc được số tiền (${unrecognized.length})',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...unrecognized.entries.map(
                  (entry) => _UnrecognizedTile(
                    rawId: entry.key,
                    title: entry.value.title,
                    text: entry.value.text,
                    onReview: () => _review(
                      BankNotificationParser.fromUnrecognized(
                        rawId: entry.key,
                        title: entry.value.title,
                        text: entry.value.text,
                      ),
                    ),
                    onAcknowledge: () => _bank.acknowledge(entry.key),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool? granted;
  final bool connected;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onOpenPasteModal;
  const _StatusCard({
    required this.granted,
    required this.connected,
    required this.error,
    required this.onRefresh,
    required this.onOpenPasteModal,
  });

  @override
  Widget build(BuildContext context) {
    final bank = BankSyncService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsPermission = !kIsWeb && granted == false;
    final Color statusColor = kIsWeb
        ? const Color(0xFF059669)
        : (needsPermission
            ? const Color(0xFFE11D48)
            : (connected ? const Color(0xFF059669) : const Color(0xFFD97706)));

    final title = kIsWeb
        ? 'Đồng bộ Mã giao dịch Ngân hàng (Web & Mobile)'
        : (needsPermission
            ? 'Chưa bật quyền đọc thông báo ngân hàng'
            : connected
                ? 'Đang lắng nghe Ngân hàng · Ví điện tử'
                : 'Dịch vụ đọc thông báo chưa kết nối');
    final subtitle = error ??
        (kIsWeb
            ? 'Dán nhanh nội dung SMS/thông báo ngân hàng để tự động gán Mã giao dịch chính & ghi chú riêng.'
            : (needsPermission
                ? 'Bật quyền Thông báo thiết bị & ứng dụng cho Finora để tự nhận biến động số dư.'
                : connected
                    ? 'Tự động nhận diện Thu/Chi, Chuyển khoản cùng máy, Trả thẻ tín dụng.'
                    : 'Nếu Android vừa khởi động lại hoặc chặn dịch vụ chạy nền, hãy chạm kết nối lại.'));

    return AdaptiveGlassSurface(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  needsPermission
                      ? Icons.notifications_paused_rounded
                      : (connected || kIsWeb
                          ? Icons.verified_user_rounded
                          : Icons.sync_problem_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
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
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (kIsWeb) {
                    onOpenPasteModal();
                  } else if (needsPermission) {
                    bank.requestPermission();
                  } else if (!connected) {
                    bank.openAppInfo();
                  } else {
                    onRefresh();
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Text(
                    kIsWeb
                        ? 'Dán thông báo'
                        : (needsPermission
                            ? 'Cấp quyền'
                            : connected
                                ? 'Làm mới'
                                : 'Mở cài đặt'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!kIsWeb && needsPermission) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                    : const Color(0xFFFFF1F2).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security_update_good_rounded,
                        size: 16,
                        color: Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bị báo "Ứng dụng bị hạn chế" trên Android 13+?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF881337),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () =>
                            _showRestrictedSettingsGuide(context, isDark),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Xem 3 bước ›',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Do cài file APK ngoài CH Play, Android khóa tạm nút gạt. Bạn chỉ cần bấm Bước 1 → chọn menu ⋮ góc trên phải (hoặc kéo xuống cuối) → bật "Cho phép cài đặt bị hạn chế", sau đó bấm Bước 2.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.38,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            bank.openAppInfo();
                          },
                          child: AdaptiveGlassSurface(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFE11D48)
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.settings_applications_rounded,
                                  size: 15,
                                  color: Color(0xFFE11D48),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Bước 1: Mở TT Ứng dụng',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            bank.requestPermission();
                          },
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_active_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Bước 2: Bật Thông báo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (!kIsWeb) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onOpenPasteModal,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669)
                        .withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_paste_go_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Dán nhanh thông báo Ngân hàng / Ví điện tử',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRestrictedSettingsGuide(BuildContext context, bool isDark) {
    final bank = BankSyncService();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AdaptiveGlassSurface(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cách gỡ "Ứng dụng bị hạn chế" (Android 13+)',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Từ Android 13 trở lên, khi cài ứng dụng bằng file APK, hệ điều hành sẽ làm mờ nút "Cho phép truy cập thông báo" cho tới khi bạn xác nhận 1 lần duy nhất trong Thông tin ứng dụng:',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  isDark: isDark,
                  step: '1',
                  title: 'Mở trang Thông tin ứng dụng (App Info) của Finora',
                  desc:
                      'Bấm nút "Bước 1: Mở TT Ứng dụng" bên dưới (hoặc vào Cài đặt máy → Ứng dụng → Finora).',
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  isDark: isDark,
                  step: '2',
                  title: 'Bật "Cho phép cài đặt bị hạn chế"',
                  desc:
                      '• Máy Samsung / OPPO / Vivo / Pixel: Bấm biểu tượng 3 chấm (⋮) ở góc trên bên phải màn hình → chọn "Cho phép cài đặt bị hạn chế" (Allow restricted settings).\n• Máy Xiaomi / HyperOS: Kéo xuống dưới cùng trang Thông tin ứng dụng → bật "Cho phép cài đặt bị hạn chế" và xác nhận vân tay/mật khẩu.',
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  isDark: isDark,
                  step: '3',
                  title: 'Quay lại bật "Cho phép truy cập thông báo"',
                  desc:
                      'Bấm nút "Bước 2: Bật Thông báo" → gạt công tắc Finora sang BẬT. Từ lúc này Finora sẽ tự động đọc biến động số dư 100%.',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          bank.openAppInfo();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.settings_applications_rounded,
                            size: 18),
                        label: const Text('Bước 1: Mở TT App'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          bank.requestPermission();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: const Color(0xFF059669),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.notifications_active_rounded,
                            size: 18),
                        label: const Text('Bước 2: Bật quyền'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow({
    required bool isDark,
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE11D48),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingTile extends StatelessWidget {
  final ParsedBankTransaction tx;
  final VoidCallback onReview;
  final VoidCallback onDismiss;
  const _PendingTile({
    required this.tx,
    required this.onReview,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.isTransfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isTransfer
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48));
    final sign = isTransfer ? '⇄ ' : (isIncome ? '+' : '-');
    final timeStr = DateFormat('HH:mm • dd/MM/yyyy').format(tx.timestamp);
    final acct = tx.accountNumber?.trim() ?? '';
    final txCode =
        tx.transactionCode.trim().isNotEmpty ? tx.transactionCode.trim() : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: AdaptiveGlassSurface(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: BankIcon(
                          bankCode: tx.bankCode,
                          bankName: tx.bankName,
                          size: 28,
                        ),
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
                                  tx.matchedTransferBankName != null
                                      ? '${tx.bankName} → ${tx.matchedTransferBankName}'
                                      : tx.bankName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
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
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tx.isCreditCardPayment
                                      ? 'Trả thẻ TD'
                                      : (isTransfer
                                          ? 'CK nội bộ'
                                          : (isIncome
                                              ? 'Thu nhập'
                                              : 'Chi tiêu')),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (acct.isNotEmpty) ...[
                                Text(
                                  'TK $acct',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  timeStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sign${formatVND(tx.amount.round())}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (txCode.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Mã GD chính: $txCode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx.note,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDismiss();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTransfer
                                  ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                                  : (isIncome
                                      ? const [
                                          Color(0xFF059669),
                                          Color(0xFF047857)
                                        ]
                                      : const [
                                          Color(0xFFE11D48),
                                          Color(0xFFBE123C)
                                        ]),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Kiểm tra & ghi vào sổ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnrecognizedTile extends StatelessWidget {
  final String rawId;
  final String title;
  final String text;
  final VoidCallback onReview;
  final VoidCallback onAcknowledge;
  const _UnrecognizedTile({
    required this.rawId,
    required this.title,
    required this.text,
    required this.onReview,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: AdaptiveGlassSurface(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD97706).withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Thông báo ngân hàng' : title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onAcknowledge();
                      },
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        child: Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF047857)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Chọn danh mục & Lưu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
