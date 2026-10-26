import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thanh Navigation Bar Siêu Sang Trọng (Apple Liquid Glass Luxury Dock) chuẩn Web/Mobile 3.0
class FinoraNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const FinoraNavigation({
    super.key,
    required this.index,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: dark
              ? const Color(0xFF131A26).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.94),
          border: Border.all(
            color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF0F172A))
                  .withValues(alpha: dark ? 0.40 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF0F172A))
                  .withValues(alpha: dark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _tab(context, 0, Icons.grid_view_rounded, Icons.grid_view_rounded,
                      'Tổng quan'),
                  _tab(context, 1, Icons.receipt_long_rounded,
                      Icons.receipt_long_rounded, 'Giao dịch'),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: 'Ghi chép nhanh',
                        child: InkResponse(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onAddTap();
                          },
                          radius: 28,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.50),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _tab(context, 2, Icons.account_balance_wallet_rounded,
                      Icons.account_balance_wallet_rounded, 'Nguồn tiền'),
                  _tab(context, 3, Icons.widgets_rounded,
                      Icons.widgets_rounded, 'Tiện ích'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int tab, IconData icon, IconData activeIcon,
      String label) {
    final selected = index == tab;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF4F46E5); // Indigo-600 matching Web
    final inactiveColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkResponse(
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onTap(tab);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

