import 'package:firebase_auth/firebase_auth.dart' show User;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/family_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../transaction/transaction_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0: Home, 1: Transaction, 2: Wallet, 3: Profile
  String? _loadedScopeId;

  void _loadSharedScope(String scopeId) {
    if (_loadedScopeId == scopeId) return;
    _loadedScopeId = scopeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load(scopeId, force: true);
      context.read<TransactionProvider>().load(scopeId, force: true);
      context.read<WalletProvider>().load(scopeId, force: true);
      context.read<BudgetProvider>().load(scopeId, force: true);
      context.read<MoreProvider>().load(scopeId, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user.uid;
    final familyProv = context.watch<FamilyProvider>();
    final scopeId = (familyProv.familyId != null && familyProv.familyId!.isNotEmpty)
        ? familyProv.familyId!
        : uid;
    _loadSharedScope(scopeId);

    final accountName = widget.user.displayName?.trim();
    final emailName = widget.user.email?.split('@').first.trim();
    final name = accountName?.isNotEmpty == true
        ? accountName!
        : (emailName?.isNotEmpty == true ? emailName! : 'Bạn');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      DashboardScreen(
        userId: scopeId,
        userName: name,
        userPhotoUrl: widget.user.photoURL,
        onViewAllTransactions: () => setState(() => _currentIndex = 1),
        onViewWallets: () => setState(() => _currentIndex = 2),
      ),
      TransactionScreen(userId: scopeId),
      WalletScreen(userId: scopeId, isRoot: true),
      ProfileScreen(
        userId: scopeId,
        userEmail: widget.user.email ?? '',
        userName: name,
        userPhotoUrl: widget.user.photoURL,
        isRoot: true,
        onSignOut: () => context.read<AuthProvider>().signOut(),
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                    .withValues(alpha: isDark ? 0.88 : 0.82),
                borderRadius: BorderRadius.circular(38),
                border: Border.all(
                    color:
                        Colors.white.withValues(alpha: isDark ? 0.18 : 0.62)),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF0369A1).withValues(alpha: 0.16),
                      blurRadius: 32,
                      offset: const Offset(0, 12))
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    targetIndex: 0,
                    label: 'Trang chủ',
                    icon: Icons.home_rounded,
                    selected: _currentIndex == 0,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    targetIndex: 1,
                    label: 'Giao dịch',
                    icon: Icons.receipt_long_rounded,
                    selected: _currentIndex == 1,
                    isDark: isDark,
                  ),
                  // Center Floating Plus Button
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => AddTransactionPage(userId: scopeId),
                          ),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0284C7),
                                Color(0xFF0EA5E9),
                                Color(0xFF06B6D4)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x550284C7),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                  _buildNavItem(
                    targetIndex: 2,
                    label: 'Ví tiền',
                    icon: Icons.account_balance_wallet_outlined,
                    selected: _currentIndex == 2,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    targetIndex: 3,
                    label: 'Cá nhân',
                    icon: Icons.person_outline_rounded,
                    selected: _currentIndex == 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int targetIndex,
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFF0284C7);
    final inactiveColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = targetIndex),
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF06B6D4)])
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: activeColor.withValues(alpha: .28),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : inactiveColor,
                size: 21,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
