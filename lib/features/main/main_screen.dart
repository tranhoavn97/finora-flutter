import '../../core/widgets/finora_notice.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/bank_notification_parser.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';
import '../notification/notification_screen.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex =
      0; // 0: Home/Dashboard, 1: Wealth & Transactions, 2: Planning & Budget, 3: Profile
  int _wealthHubTabIndex = 0; // 0: Giao dịch, 1: Ví tiền, 2: Đầu tư, 3: Sổ nợ
  StreamSubscription<ParsedBankTransaction>? _bankSyncSubscription;
  bool _wasBankSyncGranted = false;
  bool _showingBankInbox = false;
  bool _showingBankPrompt = false;
  final Set<String> _promptedBankIds = <String>{};
  StreamSubscription<void>? _bankInboxSubscription;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBankSync();
    BankSyncService()
        .isPermissionGranted()
        .then((granted) => _wasBankSyncGranted = granted);

    try {
      final tabParam = Uri.base.queryParameters['tab'];
      final subtabParam = Uri.base.queryParameters['subtab'];
      if (tabParam != null) {
        if (tabParam == 'wealth' || tabParam == '1') {
          _currentIndex = 1;
          if (subtabParam == 'wallet' ||
              subtabParam == 'wallets' ||
              subtabParam == '1') {
            _wealthHubTabIndex = 1;
          } else if (subtabParam == 'invest' ||
              subtabParam == 'assets' ||
              subtabParam == '2') {
            _wealthHubTabIndex = 2;
          } else if (subtabParam == 'loan' ||
              subtabParam == 'loans' ||
              subtabParam == '3') {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _checkBankSyncOnResume();
    }
  }

  Future<void> _checkBankSyncOnResume() async {
    final granted = await BankSyncService().isPermissionGranted();
    if (granted && !_wasBankSyncGranted) {
      _wasBankSyncGranted = true;
      await BankSyncService().requestPostNotifications();
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã cấp quyền đọc thông báo ngân hàng.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    _wasBankSyncGranted = granted;
    _promptedBankIds.clear();
    await BankSyncService().reconnect();
    if (mounted) {
      await _promptPendingBankTransactions();
    }
  }

  Future<void> _promptPendingBankTransactions({
    ParsedBankTransaction? priorityTx,
  }) async {
    if (!mounted ||
        widget.user == null ||
        !_foreground ||
        _showingBankPrompt ||
        _showingBankInbox) {
      return;
    }

    final bank = BankSyncService();
    ParsedBankTransaction? target = priorityTx;
    if (target == null) {
      for (final tx in bank.pending) {
        if (!_promptedBankIds.contains(tx.rawId)) {
          target = tx;
          break;
        }
      }
    }
    if (target == null && bank.unrecognized.isNotEmpty) {
      for (final entry in bank.unrecognized.entries) {
        if (!_promptedBankIds.contains(entry.key)) {
          target = BankNotificationParser.fromUnrecognized(
            rawId: entry.key,
            title: entry.value.title,
            text: entry.value.text,
          );
          break;
        }
      }
    }
    if (target == null) return;

    _showingBankPrompt = true;
    _promptedBankIds.add(target.rawId);
    try {
      await BankTransactionPromptSheet.show(
        context,
        transaction: target,
        userId: widget.user!.uid,
      );
    } finally {
      _showingBankPrompt = false;
    }

    if (mounted && _foreground) {
      // Prompt next pending bank notification if user saved/dismissed the previous one
      final hasMorePending =
          bank.pending.any((t) => !_promptedBankIds.contains(t.rawId));
      if (hasMorePending) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (mounted) {
          await _promptPendingBankTransactions();
        }
      }
    }
  }

  Future<void> _openBankInbox() async {
    if (!mounted || widget.user == null || _showingBankInbox) return;
    _showingBankInbox = true;
    try {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NotificationScreen(userId: widget.user!.uid)));
    } finally {
      _showingBankInbox = false;
    }
  }

  void _initBankSync() {
    if (widget.user == null) return;
    _bankInboxSubscription = BankSyncService().onInboxRequested.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _promptedBankIds.clear();
        final bank = BankSyncService();
        if (bank.pending.isNotEmpty || bank.unrecognized.isNotEmpty) {
          await _promptPendingBankTransactions();
        } else {
          await _openBankInbox();
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    _bankSyncSubscription =
        BankSyncService().onTransactionDetected.listen((tx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_foreground || _showingBankInbox) return;
        _promptPendingBankTransactions(priorityTx: tx);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    BankSyncService().initialize().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _promptPendingBankTransactions();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bankSyncSubscription?.cancel();
    _bankInboxSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid ?? '';
    final familyId = context.watch<FamilyProvider>().familyId;
    final name = widget.user?.displayName ??
        (widget.user?.email?.split('@').first ?? 'Bạn');

    final List<Widget> pages;
    pages = [
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
        userEmail: widget.user?.email ?? '',
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
          FinoraNotice.of(context)
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
                          onTap: (index) =>
                              setState(() => _currentIndex = index),
                          onAddTap: () {
                            showSuperActionSheet(context: context, userId: uid);
                          },
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
