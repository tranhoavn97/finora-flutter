import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/finora_navigation.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/super_action_sheet.dart';
import '../../state/auth_provider.dart';
import '../../state/family_provider.dart';
import '../auth/auth_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../planning/planning_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wealth_hub_screen.dart';

class MainScreen extends StatefulWidget {
  final User? user;
  const MainScreen({super.key, this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex =
      0; // 0: Home/Dashboard, 1: Wealth & Transactions, 2: Planning & Budget, 3: Profile
  int _wealthHubTabIndex = 0; // 0: Giao dịch, 1: Ví tiền, 2: Đầu tư, 3: Sổ nợ

  @override
  void initState() {
    super.initState();
    try {
      final tabParam = Uri.base.queryParameters['tab'];
      final subtabParam = Uri.base.queryParameters['subtab'];
      if (tabParam != null) {
        if (tabParam == 'wealth' || tabParam == '1') {
          _currentIndex = 1;
          if (subtabParam == 'wallet' || subtabParam == 'wallets' || subtabParam == '1') {
            _wealthHubTabIndex = 1;
          } else if (subtabParam == 'invest' || subtabParam == 'assets' || subtabParam == '2') {
            _wealthHubTabIndex = 2;
          } else if (subtabParam == 'loan' || subtabParam == 'loans' || subtabParam == '3') {
            _wealthHubTabIndex = 3;
          }
        } else if (tabParam == 'planning' || tabParam == '2') {
          _currentIndex = 2;
        } else if (tabParam == 'profile' || tabParam == '3') {
          _currentIndex = 3;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid ?? 'guest_hoa_tran';
    final familyId = context.watch<FamilyProvider>().familyId;
    final name = widget.user?.displayName ??
        (widget.user?.email?.split('@').first ?? 'Hòa Trần');

    final pages = [
      DashboardScreen(
        userId: uid,
        familyId: familyId,
        userName: name,
        userPhotoUrl: widget.user?.photoURL,
        onViewPlanning: () => setState(() => _currentIndex = 2),
        onViewWallets: () => setState(() {
          _currentIndex = 1;
          _wealthHubTabIndex = 1;
        }),
        onViewAssets: () => setState(() {
          _currentIndex = 1;
          _wealthHubTabIndex = 2;
        }),
        onViewLoans: () => setState(() {
          _currentIndex = 1;
          _wealthHubTabIndex = 3;
        }),
        onViewAllTransactions: () => setState(() {
          _currentIndex = 1;
          _wealthHubTabIndex = 0;
        }),
      ),
      WealthHubScreen(
        key: ValueKey('wealth_hub_$_wealthHubTabIndex'),
        userId: uid,
        familyId: familyId,
        isRoot: true,
        initialTabIndex: _wealthHubTabIndex,
      ),
      PlanningHubScreen(
        userId: uid,
        familyId: familyId,
        isRoot: true,
      ),
      ProfileScreen(
        userId: uid,
        userEmail: widget.user?.email ?? 'tranhoavn97@gmail.com',
        userName: name,
        userPhotoUrl: widget.user?.photoURL,
        isRoot: true,
        onSignOut: () {
          if (widget.user != null) {
            context.read<AuthProvider>().signOut();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          }
        },
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Bạn đang ở trang Tổng quan'),
              duration: Duration(seconds: 1),
            ));
        }
      },
      child: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardOpen = bottomInset > 60;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // 1. Pages inside ambient floating background extending full height
                Positioned.fill(
                  child: AmbientFloatingBackground(
                    child: FinoraFluidTabSwitcher(
                      currentIndex: _currentIndex,
                      children: pages,
                    ),
                  ),
                ),

                // 2. Truly floating liquid glass navigation island (auto-hides when typing/searching)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    offset: isKeyboardOpen ? const Offset(0, 1.4) : Offset.zero,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isKeyboardOpen ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: IgnorePointer(
                        ignoring: isKeyboardOpen,
                        child: FinoraNavigation(
                          index: _currentIndex,
                          onTap: (index) => setState(() => _currentIndex = index),
                          onAddTap: () =>
                              showSuperActionSheet(context: context, userId: uid),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
