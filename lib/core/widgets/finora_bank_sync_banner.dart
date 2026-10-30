import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bank_sync_service.dart';
import '../widgets/finora_bank_sync_permission_dialog.dart';
import '../../features/settings/bank_sync_settings_sheet.dart';

/// Executive Banner on Dashboard displaying the bank notification sync status.
/// Prominently invites user to activate permission if not granted, or offers
/// access to the durable inbox when permission is granted.
class FinoraBankSyncBanner extends StatefulWidget {
  final String userId;

  const FinoraBankSyncBanner({
    super.key,
    required this.userId,
  });

  @override
  State<FinoraBankSyncBanner> createState() => _FinoraBankSyncBannerState();
}

class _FinoraBankSyncBannerState extends State<FinoraBankSyncBanner>
    with WidgetsBindingObserver {
  bool _isGranted = false;
  bool _isDismissed = false;
  bool _isLoading = true;

  static const String _prefDismissedKey = 'finora_bank_banner_dismissed_time';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isGranted = false;
          _isLoading = false;
        });
      }
      return;
    }

    final granted = await BankSyncService().isPermissionGranted();
    final prefs = await SharedPreferences.getInstance();
    final dismissedTime = prefs.getInt(_prefDismissedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Dismiss for 12 hours if user closed it
    final dismissed = !granted && (now - dismissedTime < 12 * 60 * 60 * 1000);

    if (mounted) {
      setState(() {
        _isGranted = granted;
        _isDismissed = dismissed;
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefDismissedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (mounted) {
      setState(() {
        _isDismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!BankSyncService().supported) return const SizedBox.shrink();
    if (_isLoading || _isDismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isGranted) {
      return _buildActivationPrompt(context, isDark);
    } else {
      return _buildActiveIndicator(context, isDark);
    }
  }

  /// Banner when permission has not been granted yet
  Widget _buildActivationPrompt(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF064E3B).withValues(alpha: 0.45),
                  const Color(0xFF022C22).withValues(alpha: 0.65),
                ]
              : [
                  const Color(0xFFECFDF5),
                  const Color(0xFFD1FAE5).withValues(alpha: 0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFF059669).withValues(alpha: isDark ? 0.35 : 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(
              alpha: isDark ? 0.20 : 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bell squircle badge with pulse aura
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF003D35)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669)
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 22,
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
                                  'Tự động nhận diện giao dịch',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF064E3B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Đọc biến động số dư từ Vietcombank, Techcombank, MB, MoMo... ngay khi có thông báo.',
                              style: TextStyle(
                                fontSize: 12.0,
                                height: 1.35,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dismiss close button
                      InkWell(
                        onTap: _dismissBanner,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF059669)
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Security badge pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF047857),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bóc tách trên máy • Bỏ qua OTP',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Activate button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            FinoraBankSyncPermissionDialog.show(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF047857)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Cấp quyền ngay',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  /// Compact active status indicator when permission is granted
  Widget _buildActiveIndicator(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFF059669).withValues(alpha: isDark ? 0.25 : 0.20),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đã cấp quyền đọc thông báo',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Mở Ngân hàng để xem giao dịch chờ ghi',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Persistent bank inbox
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                BankSyncSettingsSheet.show(context, userId: widget.userId);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ngân hàng',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
