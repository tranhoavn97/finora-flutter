import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../asset/asset_screen.dart';
import 'wallet_screen.dart';

/// Màn hình Nguồn Tiền & Tài Sản (Khung Layout hợp nhất chuẩn Web)
/// Cho phép chuyển đổi linh hoạt giữa Ví tiền / Thẻ tín dụng và Tài sản đầu tư
class WalletAndAssetScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final int initialTabIndex; // 0: Ví tiền, 1: Tài sản

  const WalletAndAssetScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.initialTabIndex = 0,
  });

  @override
  State<WalletAndAssetScreen> createState() => _WalletAndAssetScreenState();
}

class _WalletAndAssetScreenState extends State<WalletAndAssetScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Segmented Tab Control
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2C) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        label: 'Ví tiền & Thẻ',
                        icon: LucideIcons.wallet,
                        isSelected: _selectedTab == 0,
                        isDark: isDark,
                        onTap: () {
                          if (_selectedTab != 0) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTab = 0);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _tabButton(
                        label: 'Tài sản tích luỹ',
                        icon: LucideIcons.coins,
                        isSelected: _selectedTab == 1,
                        isDark: isDark,
                        onTap: () {
                          if (_selectedTab != 1) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTab = 1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  WalletScreen(
                    userId: widget.userId,
                    familyId: widget.familyId,
                    isRoot: true,
                  ),
                  AssetScreen(
                    userId: widget.userId,
                    isTab: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF243045) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
              size: 17,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
