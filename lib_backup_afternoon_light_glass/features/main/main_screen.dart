import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../state/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../transaction/transaction_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../wallet/wallet_screen.dart';
import '../more/more_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  String get _userId => widget.user.uid;
  String get _name => widget.user.displayName ?? (widget.user.email?.split('@').first ?? '');

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        userId: _userId,
        userName: _name,
        userPhotoUrl: widget.user.photoURL,
        onViewAllTransactions: () => setState(() => _index = 1),
      ),
      TransactionScreen(userId: _userId),
      WalletScreen(userId: _userId),
      MoreScreen(
        userId: _userId,
        userEmail: widget.user.email ?? '',
        userName: _name,
        userPhotoUrl: widget.user.photoURL,
        onSignOut: () => context.read<AuthProvider>().signOut(),
      ),
    ];

    // Wrap the entire app screens inside the custom Gradient and FloatingBubbles background
    return GradientBackground(
      child: FloatingBubblesBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: _GlassBottomNav(
            index: _index,
            onTap: (i) => setState(() => _index = i),
            onAdd: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => AddTransactionPage(userId: _userId),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.home_rounded, 'Trang chủ'),
  _NavItem(Icons.receipt_long_rounded, 'Giao dịch'),
  _NavItem(Icons.account_balance_wallet_rounded, 'Ví tiền'),
  _NavItem(Icons.person_rounded, 'Cá nhân'),
];

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _GlassBottomNav({required this.index, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sleek frosted glass colors for the bottom navigation bar
    final navBg = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65);
    final borderColor = isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.40);

    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, bottom: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64, // Sleek docked navigation bar height
                child: Row(
                  children: [
                    _tab(context, 0),
                    _tab(context, 1),
                    _CenterFab(onTap: onAdd), // Center squircle FAB inside the main navigation Row
                    _tab(context, 2),
                    _tab(context, 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = index == i;
    // Premium navy blue when selected, subtle slate gray when inactive
    final color = selected 
        ? AppColors.accent 
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_navItems[i].icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              _navItems[i].label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});
  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(isDark ? 0.4 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

