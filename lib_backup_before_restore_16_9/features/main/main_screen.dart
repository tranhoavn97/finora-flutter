import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/finora_navigation.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/super_action_sheet.dart';
import '../../state/auth_provider.dart';
import '../../state/family_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../more/management_hub_screen.dart';
import '../transaction/transaction_screen.dart';
import '../wallet/wallet_screen.dart';

class MainScreen extends StatefulWidget {
  final User? user;
  final String? demoUserId;
  final String? demoUserName;
  const MainScreen({super.key, this.user, this.demoUserId, this.demoUserName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex =
      0; // 0: Home, 1: Transaction, 2: Wallet & Assets, 3: Management Hub

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid ?? widget.demoUserId ?? 'demo_user_123';
    final familyId = context.watch<FamilyProvider>().familyId;
    final name = widget.user?.displayName ??
        (widget.user?.email?.split('@').first ?? widget.demoUserName ?? 'Hòa Trần');

    final pages = [
      DashboardScreen(
        userId: uid,
        familyId: familyId,
        userName: name,
        userPhotoUrl: widget.user?.photoURL,
        onViewAllTransactions: () => setState(() => _currentIndex = 1),
        onViewWallets: () => setState(() => _currentIndex = 2),
      ),
      TransactionScreen(
        userId: uid,
        familyId: familyId,
        isTab: true,
      ),
      WalletScreen(userId: uid, familyId: familyId, isRoot: true),
      ManagementHubScreen(
        userId: uid,
        userEmail: widget.user?.email ?? 'tranhoavn97@gmail.com',
        userName: name,
        userPhotoUrl: widget.user?.photoURL,
        onSignOut: () => context.read<AuthProvider>().signOut(),
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Pages inside ambient blurred background extending full height
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FinoraBlurredMeshBackdrop(isDark: isDark),
                  FinoraFluidTabSwitcher(
                      currentIndex: _currentIndex, children: pages),
                ],
              ),
            ),

            // 2. Truly floating liquid glass navigation island
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FinoraNavigation(
                index: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                onAddTap: () =>
                    showSuperActionSheet(context: context, userId: uid),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
