import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_colors.dart';

class FinoraNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  const FinoraNavigation(
      {super.key,
      required this.index,
      required this.onTap,
      required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enlarged = MediaQuery.textScalerOf(context).scale(12) > 18;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF101726)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE8EDF9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    _tab(context, 0, Icons.home_outlined, Icons.home_rounded, 'Trang chủ', enlarged),
                    _tab(context, 1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Giao dịch', enlarged),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: 'Thêm giao dịch',
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onAddTap,
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 50,
                                height: 50,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _tab(context, 2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Ví tiền', enlarged),
                    _tab(context, 3, Icons.person_outline_rounded, Icons.person_rounded, 'Cá nhân', enlarged),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int tab, IconData icon, IconData activeIcon,
      String label, bool enlarged) {
    final selected = index == tab;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (dark ? Colors.white : AppColors.primaryDark)
        : (dark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary);
    final activeBg = dark ? const Color(0xFF1E3A8A) : AppColors.primary.withValues(alpha: 0.12);

    return Expanded(
        child: Semantics(
            selected: selected,
            button: true,
            label: label,
            child: Tooltip(
                message: label,
                child: InkWell(
                    onTap: () {
                      if (!selected) HapticFeedback.selectionClick();
                      onTap(tab);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: selected
                                        ? activeBg
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16)),
                                child: Icon(selected ? activeIcon : icon,
                                    size: 22, color: color)),
                            const SizedBox(height: 2),
                            Text(label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: color))
                          ])),
                    )))));
  }
}
