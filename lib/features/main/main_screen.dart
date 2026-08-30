import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../state/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../transaction/transaction_screen.dart';
import '../ai/ai_advisor_screen.dart';
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
  int _previousIndex = 0;

  String get _userId => widget.user.uid;
  String get _name =>
      widget.user.displayName ?? (widget.user.email?.split('@').first ?? '');

  void _onTabChanged(int i) {
    if (_index == i) return;
    setState(() {
      if (_index != 2) {
        _previousIndex = _index;
      }
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: const ValueKey('main-tab-dashboard'),
        userId: _userId,
        userName: _name,
        userPhotoUrl: widget.user.photoURL,
        onViewAllTransactions: () => _onTabChanged(1),
      ),
      TransactionScreen(
        key: const ValueKey('main-tab-transactions'),
        userId: _userId,
      ),
      AiAdvisorScreen(
        key: const ValueKey('main-tab-ai-advisor'),
        userId: _userId,
        isTab: true,
        onBack: () => setState(() => _index = _previousIndex),
      ),
      WalletScreen(
        key: const ValueKey('main-tab-wallets'),
        userId: _userId,
      ),
      MoreScreen(
        key: const ValueKey('main-tab-profile'),
        userId: _userId,
        userEmail: widget.user.email ?? '',
        userName: _name,
        userPhotoUrl: widget.user.photoURL,
        onSignOut: () => context.read<AuthProvider>().signOut(),
      ),
    ];

    // Wrap the entire app screens inside the custom Gradient and FloatingBubbles background
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = _index == 2 ? _previousIndex : 0);
        }
      },
      child: GradientBackground(
        child: FloatingBubblesBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: _index == 2
                ? null
                : _GlassBottomNav(index: _index, onTap: _onTabChanged),
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
  _NavItem(Icons.history_rounded, 'Lịch sử'),
  _NavItem(Icons.auto_awesome_rounded, 'Trợ lý AI'),
  _NavItem(Icons.credit_card_rounded, 'Tài khoản'),
  _NavItem(Icons.person_rounded, 'Cá nhân'),
];

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
            decoration: BoxDecoration(
              color: bg.withOpacity(isDark ? .74 : .70),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .28 : .12),
                    blurRadius: 30,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Row(children: [
              _tab(context, 0),
              _tab(context, 1),
              _tab(context, 2),
              _tab(context, 3),
              _tab(context, 4)
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = index == i;
    final isAi = i == 2;
    final color = isAi
        ? Colors.white
        : selected
            ? AppColors.accent
            : (isDark
                ? const Color(0xFF64748B)
                : const Color(0xFF94A3B8));

    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isAi
                ? null
                : selected
                    ? AppColors.accent.withOpacity(isDark ? 0.16 : 0.10)
                    : Colors.transparent,
            gradient: isAi
                ? const LinearGradient(
                    colors: [Color(0xFF0A84FF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            shape: isAi ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isAi ? null : BorderRadius.circular(18),
            boxShadow: isAi
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_navItems[i].icon, color: color, size: isAi ? 22 : 21),
              const SizedBox(height: 3),
              Text(
                _navItems[i].label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
