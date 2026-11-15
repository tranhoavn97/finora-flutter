import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/dashboard_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../services/bank_sync_service.dart';
import '../services/home_widget_sync_service.dart';
import 'finora_notice.dart';

/// Hiển thị xem trước & nút ghim nhanh 2 mẫu Widget màn hình chính Android (5×2 & 5×4)
/// giúp theo dõi chi tiêu trực tiếp và các biến động số dư cần ghi chép.
class FinoraHomeWidgetCard extends StatefulWidget {
  const FinoraHomeWidgetCard({super.key});

  @override
  State<FinoraHomeWidgetCard> createState() => _FinoraHomeWidgetCardState();
}

class _FinoraHomeWidgetCardState extends State<FinoraHomeWidgetCard> {
  final _widgetSync = HomeWidgetSyncService();
  final _bank = BankSyncService();
  bool _canPin = false;
  bool _pinning5x2 = false;
  bool _pinning5x4 = false;

  @override
  void initState() {
    super.initState();
    _checkCanPin();
  }

  Future<void> _checkCanPin() async {
    final supported = await _widgetSync.canPinWidgets();
    if (mounted) setState(() => _canPin = supported);
  }

  Future<void> _handlePin(String widgetType) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (widgetType == '5x4') {
        _pinning5x4 = true;
      } else {
        _pinning5x2 = true;
      }
    });

    final dash = Provider.of<DashboardProvider?>(context, listen: false);
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    if (dash != null) {
      await _widgetSync.sync(
        dashboardData: dash.data,
        pendingCount: _bank.pending.length + _bank.unrecognizedCount,
        hideAmounts: studio?.isPrivacyShieldActive ?? false,
        force: true,
      );
    }
    final ok = await _widgetSync.requestPinWidget(widgetType);

    if (!mounted) return;
    setState(() {
      _pinning5x2 = false;
      _pinning5x4 = false;
    });

    if (ok) {
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi yêu cầu ghim Widget FINORA $widgetType ra màn hình chính!',
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _widgetSync.supported
                ? 'Hãy nhấn giữ vùng trống trên màn hình chính → chọn Widget → chọn FINORA $widgetType.'
                : 'Widget màn hình chính khả dụng khi chạy app Android trên điện thoại.',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _fmtVnd(num amount, bool hidden) {
    if (hidden) return '•••••• đ';
    return '${NumberFormat('#,##0', 'vi_VN').format(amount.round()).replaceAll(',', '.')} đ';
  }

  String _fmtCompact(num amount, bool hidden) {
    if (hidden) return '••••';
    final v = amount.abs();
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')}tr';
    }
    if (v >= 1000) return '${(v / 1000).round()}k';
    return '${v.round()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController?>();
    final dash = context.watch<DashboardProvider?>();
    final accent = studio?.resolvedPrimary ?? const Color(0xFF059669);
    final hideAmounts = studio?.isPrivacyShieldActive ?? false;

    return AnimatedBuilder(
      animation: _bank,
      builder: (context, _) {
        final data = dash?.data ?? const DashboardData();
        final pendingTotal = _bank.pending.length + _bank.unrecognizedCount;
        final snap = HomeWidgetSyncService.buildPayload(
          dashboardData: data,
          pendingCount: pendingTotal,
          hideAmounts: hideAmounts,
        );
        final todayExp = (snap['todayExpense'] as num?) ?? 0;
        final monthExp = (snap['monthExpense'] as num?) ?? 0;
        final monthInc = (snap['monthIncome'] as num?) ?? 0;
        final balance = (snap['totalBalance'] as num?) ?? 0;
        final recent = (snap['recent'] as List?) ?? const [];
        final firstPending = _bank.pending.firstOrNull;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    ),
                    child: Icon(
                      Icons.widgets_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Widget màn hình chính (5×2 & 5×4)',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13.8,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Theo dõi chi tiêu trực tiếp & số dư ngân hàng cần ghi chép ngay ngoài màn hình.',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.2,
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

              // Live miniature preview 5x2
              _buildPreviewCardFrame(
                title: 'MẪU 5×2 • GỌN & TRỰC QUAN',
                accent: accent,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'FINORA',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '+ Ghi',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _miniTile(
                            label: 'CHI HÔM NAY',
                            value: todayExp > 0
                                ? '-${_fmtVnd(todayExp, hideAmounts)}'
                                : _fmtVnd(0, hideAmounts),
                            valueColor: const Color(0xFFFB7185),
                            sub:
                                'Tháng: ${_fmtCompact(monthExp, hideAmounts)} • Ví: ${_fmtCompact(balance, hideAmounts)}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _miniTile(
                            label: 'CẦN GHI CHÉP ($pendingTotal)',
                            value: firstPending != null
                                ? '${firstPending.bankName} • ${_fmtCompact(firstPending.amount, hideAmounts)}'
                                : 'Không có biến động chờ',
                            valueColor: pendingTotal > 0
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF34D399),
                            sub: pendingTotal > 0
                                ? 'Chạm mở hộp chờ ghi sổ →'
                                : 'Đã đồng bộ đầy đủ',
                            amberHighlight: pendingTotal > 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Live miniature preview 5x4
              _buildPreviewCardFrame(
                title: 'MẪU 5×4 • ĐẦY ĐỦ CHI TIÊU & SỐ DƯ CHỜ',
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _miniKpi(
                            'HÔM NAY',
                            todayExp > 0
                                ? '-${_fmtCompact(todayExp, hideAmounts)}'
                                : '0đ',
                            const Color(0xFFFB7185),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniKpi(
                            'THÁNG NÀY',
                            _fmtCompact(monthExp, hideAmounts),
                            Colors.white,
                            sub: 'Thu +${_fmtCompact(monthInc, hideAmounts)}',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniKpi(
                            'TỔNG SỐ DƯ',
                            _fmtCompact(balance, hideAmounts),
                            const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pendingTotal > 0
                            ? const Color(0x26F59E0B)
                            : const Color(0x1F10B981),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pendingTotal > 0
                              ? const Color(0x66FBBF24)
                              : const Color(0x4D34D399),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 13,
                            color: pendingTotal > 0
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pendingTotal > 0
                                  ? 'Số dư cần ghi chép: $pendingTotal biến động chờ'
                                  : 'Số dư cần ghi chép: Đã ghi đủ ✓',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 10.2,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recent.isNotEmpty
                          ? 'Chi gần đây: ${recent.take(2).map((e) => (e as Map)['title']).join(' • ')}'
                          : 'Chi gần đây: Hiển thị 3 giao dịch mới nhất',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        color: Color(0xFFCBD5E1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pin pill buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _pinning5x2 ? null : () => _handlePin('5x2'),
                      icon: _pinning5x2
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_to_home_screen_rounded,
                              size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ghim 5×2',
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _pinning5x4 ? null : () => _handlePin('5x4'),
                      icon: _pinning5x4
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.dashboard_customize_rounded,
                              size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ghim 5×4',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 11),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_widgetSync.supported && !_canPin) ...[
                const SizedBox(height: 8),
                Text(
                  'Mẹo: Nhấn giữ màn hình chính → chọn Widget → kéo FINORA 5×2 hoặc FINORA 5×4 ra ngoài.',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.8,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewCardFrame({
    required String title,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1420), Color(0xFF0E1D2A)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  Widget _miniTile({
    required String label,
    required String value,
    required Color valueColor,
    required String sub,
    bool amberHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: amberHighlight
            ? const Color(0x22F59E0B)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: amberHighlight
              ? const Color(0x59FBBF24)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: amberHighlight
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFCBD5E1),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _miniKpi(
    String label,
    String value,
    Color color, {
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null)
            Text(
              sub,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF34D399),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
