import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/dashboard_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../services/bank_sync_service.dart';
import '../services/home_widget_sync_service.dart';
import 'finora_notice.dart';

/// Hiển thị xem trước Frosted Glass có Linh thú sắc nét, bộ tùy chỉnh nội dung Widget
/// & bộ lọc thông báo điện thoại, cùng nút ghim nhanh 2 mẫu Widget màn hình chính Android (5×2 & 5×4).
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
  int _activeTab = 0; // 0 = Widget kính & linh thú, 1 = Tuỳ chỉnh thông báo

  @override
  void initState() {
    super.initState();
    _widgetSync.loadPreferences();
    _checkCanPin();
  }

  Future<void> _checkCanPin() async {
    final supported = await _widgetSync.canPinWidgets();
    if (mounted) setState(() => _canPin = supported);
  }

  Future<void> _updatePrefs(HomeWidgetPreferences next) async {
    HapticFeedback.selectionClick();
    final dash = Provider.of<DashboardProvider?>(context, listen: false);
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    await _widgetSync.updatePreferences(
      next,
      dashboardData: dash?.data,
      pendingCount: _bank.pending.length + _bank.unrecognizedCount,
      manualPendingCount: _bank.manualPendingCount,
      hideAmounts: studio?.isPrivacyShieldActive ?? false,
    );
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
    final accent = studio?.resolvedPrimary ?? const Color(0xFF059669);
    if (dash != null) {
      await _widgetSync.sync(
        dashboardData: dash.data,
        pendingCount: _bank.pending.length + _bank.unrecognizedCount,
        manualPendingCount: _bank.manualPendingCount,
        hideAmounts: studio?.isPrivacyShieldActive ?? false,
        preferences: _widgetSync.preferences,
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
          backgroundColor: accent,
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
      animation: Listenable.merge([_bank, _widgetSync]),
      builder: (context, _) {
        final prefs = _widgetSync.preferences;
        final data = dash?.data ?? const DashboardData();
        final pendingTotal = _bank.pending.length + _bank.unrecognizedCount;
        final snap = HomeWidgetSyncService.buildPayload(
          dashboardData: data,
          pendingCount: pendingTotal,
          hideAmounts: hideAmounts,
          preferences: prefs,
        );
        final todayExp = (snap['todayExpense'] as num?) ?? 0;
        final monthExp = (snap['monthExpense'] as num?) ?? 0;
        final monthInc = (snap['monthIncome'] as num?) ?? 0;
        final balance = (snap['totalBalance'] as num?) ?? 0;
        final recent = (snap['recent'] as List?) ?? const [];
        final firstPending = _bank.pending.firstOrNull;
        final mascotAsset = prefs.resolveMascotAsset(
          pendingCount: pendingTotal,
          todayExpense: todayExp,
        );
        final isLightGlass = prefs.isLightGlass;
        final glassTitleColor =
            isLightGlass ? const Color(0xFF0F172A) : Colors.white;
        final glassSubColor = isLightGlass
            ? const Color(0xFF334155)
            : const Color(0xFFCBD5E1);
        final glassMutedColor = isLightGlass
            ? const Color(0xFF475569)
            : const Color(0xFF94A3B8);
        final glassExpenseColor = isLightGlass
            ? const Color(0xFFE11D48)
            : const Color(0xFFFB7185);
        final glassEmeraldColor = isLightGlass
            ? const Color(0xFF059669)
            : const Color(0xFF34D399);

        final speechText = pendingTotal > 0
            ? 'Có $pendingTotal biến động mới cần ghi ✨'
            : (todayExp <= 0
                ? 'Tuyệt vời! Chưa phát sinh chi tiêu ✓'
                : 'Linh thú đang canh sổ hôm nay ✨');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.35 : 0.18),
                          const Color(0xFF38BDF8)
                              .withValues(alpha: isDark ? 0.22 : 0.12),
                        ],
                      ),
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
                          'Phong cách Kính mờ + Linh thú Finora sắc nét • Tùy chỉnh nội dung & thông báo.',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
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

              // Live Frosted Glass Preview 5x2
              _buildGlassWallpaperStage(
                prefs: prefs,
                title: 'MẪU 5×2 • GỌN & TRỰC QUAN',
                accent: accent,
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (prefs.showMascot)
                          _buildMascotHalo(
                            asset: mascotAsset,
                            size: 38,
                            isLightGlass: isLightGlass,
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FINORA',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: glassTitleColor,
                                ),
                              ),
                              Text(
                                pendingTotal > 0
                                    ? '$pendingTotal biến động chờ • ${snap['syncedAt']}'
                                    : 'Sổ gọn gàng • ${snap['syncedAt']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.2,
                                  color: glassSubColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (prefs.showQuickActions) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLightGlass
                                  ? Colors.white.withValues(alpha: 0.78)
                                  : Colors.white.withValues(alpha: 0.14),
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: glassTitleColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (prefs.showTodaySpend ||
                            prefs.showMonthSummary ||
                            prefs.showTotalBalance)
                          Expanded(
                            child: _miniTile(
                              label: prefs.showTodaySpend
                                  ? 'CHI HÔM NAY'
                                  : (prefs.showTotalBalance
                                      ? 'TỔNG SỐ DƯ'
                                      : 'CHI THÁNG NÀY'),
                              value: prefs.showTodaySpend
                                  ? (todayExp > 0
                                      ? '-${_fmtVnd(todayExp, hideAmounts)}'
                                      : _fmtVnd(0, hideAmounts))
                                  : (prefs.showTotalBalance
                                      ? _fmtVnd(balance, hideAmounts)
                                      : _fmtVnd(monthExp, hideAmounts)),
                              valueColor: prefs.showTodaySpend
                                  ? glassExpenseColor
                                  : (prefs.showTotalBalance
                                      ? glassEmeraldColor
                                      : glassTitleColor),
                              sub: [
                                if (prefs.showMonthSummary)
                                  'Tháng: ${_fmtCompact(monthExp, hideAmounts)}',
                                if (prefs.showTotalBalance &&
                                    prefs.showTodaySpend)
                                  'Ví: ${_fmtCompact(balance, hideAmounts)}',
                              ].join(' • '),
                              isLightGlass: isLightGlass,
                            ),
                          ),
                        if ((prefs.showTodaySpend ||
                                prefs.showMonthSummary ||
                                prefs.showTotalBalance) &&
                            prefs.showPendingBank)
                          const SizedBox(width: 8),
                        if (prefs.showPendingBank)
                          Expanded(
                            child: _miniTile(
                              label: 'CẦN GHI CHÉP ($pendingTotal)',
                              value: firstPending != null
                                  ? '${firstPending.bankName} • ${_fmtCompact(firstPending.amount, hideAmounts)}'
                                  : 'Không có biến động chờ',
                              valueColor: pendingTotal > 0
                                  ? (isLightGlass
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFFCD34D))
                                  : glassEmeraldColor,
                              sub: pendingTotal > 0
                                  ? 'Chạm mở hộp chờ ghi sổ →'
                                  : 'Đã đồng bộ đầy đủ',
                              amberHighlight: pendingTotal > 0,
                              isLightGlass: isLightGlass,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Live Frosted Glass Preview 5x4
              _buildGlassWallpaperStage(
                prefs: prefs,
                title: 'MẪU 5×4 • ĐẦY ĐỦ CHI TIÊU & SỐ DƯ CHỜ',
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (prefs.showMascot)
                          _buildMascotHalo(
                            asset: mascotAsset,
                            size: 44,
                            isLightGlass: isLightGlass,
                          ),
                        if (prefs.showMascot) const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FINORA • ${snap['syncedAt']}',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: glassTitleColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isLightGlass
                                      ? Colors.white.withValues(alpha: 0.78)
                                      : Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isLightGlass
                                        ? const Color(0x5510B981)
                                        : Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Text(
                                  speechText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w700,
                                    color: isLightGlass
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (prefs.showTodaySpend ||
                        prefs.showMonthSummary ||
                        prefs.showTotalBalance) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (prefs.showTodaySpend)
                            Expanded(
                              child: _miniKpi(
                                'HÔM NAY',
                                todayExp > 0
                                    ? '-${_fmtCompact(todayExp, hideAmounts)}'
                                    : '0đ',
                                glassExpenseColor,
                                isLightGlass: isLightGlass,
                              ),
                            ),
                          if (prefs.showTodaySpend && prefs.showMonthSummary)
                            const SizedBox(width: 6),
                          if (prefs.showMonthSummary)
                            Expanded(
                              child: _miniKpi(
                                'THÁNG NÀY',
                                _fmtCompact(monthExp, hideAmounts),
                                glassTitleColor,
                                sub: 'Thu +${_fmtCompact(monthInc, hideAmounts)}',
                                isLightGlass: isLightGlass,
                              ),
                            ),
                          if ((prefs.showTodaySpend ||
                                  prefs.showMonthSummary) &&
                              prefs.showTotalBalance)
                            const SizedBox(width: 6),
                          if (prefs.showTotalBalance)
                            Expanded(
                              child: _miniKpi(
                                'TỔNG SỐ DƯ',
                                _fmtCompact(balance, hideAmounts),
                                glassEmeraldColor,
                                isLightGlass: isLightGlass,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (prefs.showPendingBank) ...[
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: pendingTotal > 0
                              ? (isLightGlass
                                  ? const Color(0xDDFFFBEB)
                                  : const Color(0x26F59E0B))
                              : (isLightGlass
                                  ? const Color(0xDDECFDF5)
                                  : const Color(0x1F10B981)),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: pendingTotal > 0
                                ? const Color(0x77F59E0B)
                                : const Color(0x5510B981),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 13,
                              color: pendingTotal > 0
                                  ? (isLightGlass
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFFCD34D))
                                  : glassEmeraldColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pendingTotal > 0
                                    ? 'Số dư cần ghi chép: $pendingTotal biến động chờ'
                                    : 'Số dư cần ghi chép: Đã ghi đủ ✓',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10.2,
                                  fontWeight: FontWeight.w700,
                                  color: glassTitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (prefs.showRecentTx) ...[
                      const SizedBox(height: 6),
                      Text(
                        recent.isNotEmpty
                            ? 'Chi gần đây: ${recent.take(2).map((e) => (e as Map)['title']).join(' • ')}'
                            : 'Chi gần đây: Hiển thị 3 giao dịch mới nhất',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 10,
                          color: glassMutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pin pill buttons right under previews for 1-tap pinning
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
              const SizedBox(height: 12),

              // Customization Mode Switcher (Widget Glass & Mascot | Notification Filters)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabPill(
                        label: 'Kính & Linh thú',
                        icon: Icons.auto_awesome_rounded,
                        selected: _activeTab == 0,
                        accent: accent,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _tabPill(
                        label: 'Tuỳ chỉnh thông báo',
                        icon: Icons.notifications_active_outlined,
                        selected: _activeTab == 1,
                        accent: accent,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_activeTab == 0)
                _buildWidgetCustomizationPanel(prefs, isDark, accent)
              else
                _buildNotificationCustomizationPanel(prefs, isDark, accent),
            ],
          ),
        );
      },
    );
  }

  Widget _tabPill({
    required String label,
    required IconData icon,
    required bool selected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? accent
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCustomizationPanel(
    HomeWidgetPreferences prefs,
    bool isDark,
    Color accent,
  ) {
    const glassChoices = [
      (
        'glass_frost',
        'Kính mờ tối',
        [Color(0xFF0A1526), Color(0xFF0B2B2B)],
      ),
      (
        'glass_crystal',
        'Kính pha lê',
        [Color(0xFFF8FAFC), Color(0xFFD1FAE5)],
      ),
      (
        'glass_aurora',
        'Kính ngọc bảo',
        [Color(0xFF031E18), Color(0xFF0A2E42)],
      ),
    ];

    const moodChoices = [
      ('auto', 'Tự động', 'assets/mascot/mascot_happy.png'),
      ('happy', 'Vui vẻ', 'assets/mascot/mascot_happy.png'),
      ('focused', 'Kiểm tra', 'assets/mascot/mascot_focused.png'),
      ('celebrate', 'Ăn mừng', 'assets/mascot/mascot_celebrate.png'),
      ('confident', 'Tự tin', 'assets/mascot/mascot_confident.png'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONG CÁCH KÍNH',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: glassChoices.map((g) {
            final selected = prefs.glassStyle == g.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => _updatePrefs(prefs.copyWith(glassStyle: g.$1)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: isDark ? 0.22 : 0.10)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? accent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE2E8F0)),
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: g.$3),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          g.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? accent
                                : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Mascot toggle + mood selector
        Row(
          children: [
            Expanded(
              child: Text(
                'HIỂN THỊ LINH THÚ FINORA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            Switch.adaptive(
              value: prefs.showMascot,
              activeThumbColor: accent,
              activeTrackColor: accent.withValues(alpha: 0.35),
              onChanged: (v) => _updatePrefs(prefs.copyWith(showMascot: v)),
            ),
          ],
        ),
        if (prefs.showMascot) ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moodChoices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final m = moodChoices[idx];
                final selected = prefs.mascotMood == m.$1;
                return GestureDetector(
                  onTap: () => _updatePrefs(prefs.copyWith(mascotMood: m.$1)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: isDark ? 0.24 : 0.12)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? accent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          m.$3,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          m.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? accent
                                : (isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),

        Text(
          'CHỌN THÔNG TIN HIỂN THỊ TRÊN WIDGET',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _widgetToggleChip(
              label: 'Chi hôm nay',
              selected: prefs.showTodaySpend,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showTodaySpend: !prefs.showTodaySpend),
              ),
            ),
            _widgetToggleChip(
              label: 'Tổng tháng',
              selected: prefs.showMonthSummary,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showMonthSummary: !prefs.showMonthSummary),
              ),
            ),
            _widgetToggleChip(
              label: 'Tổng số dư',
              selected: prefs.showTotalBalance,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showTotalBalance: !prefs.showTotalBalance),
              ),
            ),
            _widgetToggleChip(
              label: 'Số dư chờ ghi',
              selected: prefs.showPendingBank,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showPendingBank: !prefs.showPendingBank),
              ),
            ),
            _widgetToggleChip(
              label: 'GD gần đây',
              selected: prefs.showRecentTx,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showRecentTx: !prefs.showRecentTx),
              ),
            ),
            _widgetToggleChip(
              label: 'Nút + Ghi',
              selected: prefs.showQuickActions,
              accent: accent,
              isDark: isDark,
              onTap: () => _updatePrefs(
                prefs.copyWith(showQuickActions: !prefs.showQuickActions),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationCustomizationPanel(
    HomeWidgetPreferences prefs,
    bool isDark,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHỌN LOẠI THÔNG BÁO MUỐN NHẬN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        _notifSwitchRow(
          icon: Icons.trending_down_rounded,
          iconColor: const Color(0xFFE11D48),
          title: 'Biến động trừ tiền / chi tiêu',
          subtitle: 'Báo ngay khi ngân hàng hoặc ví trừ tiền',
          value: prefs.notifyBankExpense,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyBankExpense: v)),
        ),
        _notifSwitchRow(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF059669),
          title: 'Biến động nhận tiền / thu nhập',
          subtitle: 'Báo ngay khi có tiền cộng vào tài khoản',
          value: prefs.notifyBankIncome,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyBankIncome: v)),
        ),
        _notifSwitchRow(
          icon: Icons.pie_chart_outline_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Cảnh báo vượt hạn mức ngân sách',
          subtitle: 'Nhắc khi chi tiêu sắp chạm hoặc vượt mức',
          value: prefs.notifyBudgetAlert,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyBudgetAlert: v)),
        ),
        _notifSwitchRow(
          icon: Icons.handshake_outlined,
          iconColor: const Color(0xFF0284C7),
          title: 'Nhắc lịch sổ nợ & Ví gia đình',
          subtitle: 'Nhắc ngày thu/trả nợ và hoạt động chung',
          value: prefs.notifyLoanReminder,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyLoanReminder: v)),
        ),
        _notifSwitchRow(
          icon: Icons.visibility_outlined,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Hiển thị rõ số tiền trên thông báo',
          subtitle: 'Tắt để che số tiền riêng tư ngoài màn hình khóa',
          value: prefs.notifyShowAmount,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyShowAmount: v)),
        ),
        _notifSwitchRow(
          icon: Icons.mark_chat_unread_outlined,
          iconColor: const Color(0xFF10B981),
          title: 'Số đếm thông báo trên icon FINORA',
          subtitle: 'Hiển thị badge số biến động chờ ghi ngoài màn hình',
          value: prefs.notifyAppBadge,
          accent: accent,
          isDark: isDark,
          onChanged: (v) => _updatePrefs(prefs.copyWith(notifyAppBadge: v)),
        ),
      ],
    );
  }

  Widget _widgetToggleChip({
    required String label,
    required bool selected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.24 : 0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 13,
              color: selected
                  ? accent
                  : (isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? accent
                    : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.2,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMascotHalo({
    required String asset,
    required double size,
    required bool isLightGlass,
  }) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isLightGlass
              ? [
                  const Color(0x4410B981),
                  const Color(0xCCFFFFFF),
                  const Color(0x88E0F2FE),
                ]
              : [
                  const Color(0x5534D399),
                  const Color(0x28FFFFFF),
                  const Color(0x12FFFFFF),
                ],
        ),
        border: Border.all(
          color: isLightGlass
              ? const Color(0x9910B981)
              : Colors.white.withValues(alpha: 0.32),
        ),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildGlassWallpaperStage({
    required HomeWidgetPreferences prefs,
    required String title,
    required Color accent,
    required Widget child,
  }) {
    final isLightGlass = prefs.isLightGlass;
    final wallpaperColors = isLightGlass
        ? const [Color(0xFFBFDBFE), Color(0xFFD1FAE5), Color(0xFFFEF3C7)]
        : const [Color(0xFF1E3A5F), Color(0xFF0F4C5C), Color(0xFF312E81)];

    final glassColors = switch (prefs.glassStyle) {
      'glass_crystal' => const [
          Color(0xDCF8FAFC),
          Color(0xE2EFF6FF),
          Color(0xDCECFDF5),
        ],
      'glass_aurora' => const [
          Color(0xC8031E18),
          Color(0xD006372C),
          Color(0xC00A2E42),
        ],
      _ => const [
          Color(0xC40A1526),
          Color(0xCC0F2336),
          Color(0xBC0B2B2B),
        ],
    };

    final glassBorderColor = switch (prefs.glassStyle) {
      'glass_crystal' => const Color(0xCCFFFFFF),
      'glass_aurora' => const Color(0x6E34D399),
      _ => const Color(0x52FFFFFF),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: wallpaperColors,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: glassColors,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: glassBorderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLightGlass ? 0.08 : 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isLightGlass
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 7),
            child,
          ],
        ),
      ),
    );
  }

  Widget _miniTile({
    required String label,
    required String value,
    required Color valueColor,
    required String sub,
    bool amberHighlight = false,
    bool isLightGlass = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: amberHighlight
            ? (isLightGlass
                ? const Color(0xD6FFFBEB)
                : const Color(0x24F59E0B))
            : (isLightGlass
                ? Colors.white.withValues(alpha: 0.68)
                : Colors.white.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: amberHighlight
              ? const Color(0x66F59E0B)
              : (isLightGlass
                  ? const Color(0x66CBD5E1)
                  : Colors.white.withValues(alpha: 0.16)),
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
                  ? (isLightGlass
                      ? const Color(0xFFB45309)
                      : const Color(0xFFFCD34D))
                  : (isLightGlass
                      ? const Color(0xFF475569)
                      : const Color(0xFF94A3B8)),
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
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 9,
                color: isLightGlass
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniKpi(
    String label,
    String value,
    Color color, {
    String? sub,
    bool isLightGlass = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: isLightGlass
            ? Colors.white.withValues(alpha: 0.68)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isLightGlass
              ? const Color(0x66CBD5E1)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isLightGlass
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
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
              style: TextStyle(
                fontSize: 8.5,
                color: isLightGlass
                    ? const Color(0xFF059669)
                    : const Color(0xFF34D399),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
