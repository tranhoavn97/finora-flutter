import '../../core/widgets/finora_notice.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/bank_notification_parser.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/services/home_widget_sync_service.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';
import '../notification/notification_screen.dart';
import '../../core/widgets/finora_navigation.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/super_action_sheet.dart';
import '../../data/models/finance_models.dart';
import '../../state/auth_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/family_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../data/services/supabase_bridge.dart';
import '../../data/services/qr_payment_draft_store.dart';
import '../qr_pay/qr_confirm_expense_sheet.dart';
import '../auth/auth_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../planning/planning_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../transaction/add_transaction_page.dart';
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
  DateTime? _lastBackPressTime;
  StreamSubscription<ParsedBankTransaction>? _bankSyncSubscription;
  bool _wasBankSyncGranted = false;
  bool _showingBankInbox = false;
  bool _showingBankPrompt = false;
  bool _showingQrResumeSheet = false;
  final Set<String> _promptedBankIds = <String>{};
  final Set<String> _promptedQrDraftIds = <String>{};
  StreamSubscription<void>? _bankInboxSubscription;
  StreamSubscription<String>? _launchActionSubscription;
  VoidCallback? _bankListener;
  String _lastMoreSyncSig = '';
  bool _checkingShownNotifs = false;
  bool _openingQuickAdd = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBankSync();
    BankSyncService()
        .isPermissionGranted()
        .then((granted) => _wasBankSyncGranted = granted);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (QrPaymentDraftStore.pendingAutoResumeInSession) {
        _checkPendingQrDrafts();
      } else {
        // Clean up any stale uncompleted drafts from previous app sessions
        // so the QR confirm sheet never pops up unexpectedly on cold start.
        final uid = widget.user?.uid ?? '';
        QrPaymentDraftStore.clear('guest');
        QrPaymentDraftStore.clear('');
        if (uid.isNotEmpty) {
          QrPaymentDraftStore.clear(uid);
        }
      }
    });

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
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.uid != widget.user?.uid) {
      unawaited(BankSyncService().bindUser(widget.user?.uid));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkPendingQrDrafts();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _checkBankSyncOnResume();
      _checkPendingQrDrafts();
      final uid = widget.user?.uid ?? '';
      if (uid.isNotEmpty) {
        unawaited(SupabaseBridge.refreshUserCollections(userId: uid));
      }
      if (mounted) {
        unawaited(
            context.read<ThemeStudioController>().refreshMemberAvatars());
      }
    }
  }

  Future<void> _checkPendingQrDrafts() async {
    if (!QrPaymentDraftStore.pendingAutoResumeInSession) {
      return;
    }
    if (!mounted || !_foreground || _showingQrResumeSheet || _showingBankPrompt) {
      return;
    }
    QrPaymentDraftStore.pendingAutoResumeInSession = false;
    final uid = widget.user?.uid ?? '';
    final effectiveUid = uid.isEmpty ? 'guest' : uid;
    try {
      // Migrate any guest or empty-uid drafts to the logged-in user
      if (uid.isNotEmpty) {
        for (final key in const ['guest', '']) {
          final guestDrafts = await QrPaymentDraftStore.list(key);
          for (final d in guestDrafts) {
            await QrPaymentDraftStore.save(uid, d);
            await QrPaymentDraftStore.remove(key, d.id);
          }
        }
      }
      final drafts = await QrPaymentDraftStore.list(effectiveUid);
      if (!mounted || !_foreground || _showingQrResumeSheet) return;
      QrPaymentDraft? target;
      for (final d in drafts) {
        if (!_promptedQrDraftIds.contains(d.id)) {
          target = d;
          break;
        }
      }
      if (target == null) return;
      _showingQrResumeSheet = true;
      _promptedQrDraftIds.add(target.id);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: QrConfirmExpenseSheet(
            qrData: target!.data,
            userId: uid,
            resumeDraft: target,
          ),
        ),
      );
    } catch (_) {
    } finally {
      _showingQrResumeSheet = false;
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
    await BankSyncService().reconnect();
    await BankSyncService().consumeLaunchAction();
    await _syncWidgetsFromCurrentState();
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
    if (target != null && target.amount <= 0) return;
    if (target != null &&
        (_promptedBankIds.contains(target.rawId) ||
            bank.wasAutoPrompted(target.rawId))) {
      return;
    }
    if (target == null) {
      for (final tx in bank.pending) {
        if (tx.amount > 0 &&
            !_promptedBankIds.contains(tx.rawId) &&
            !bank.wasAutoPrompted(tx.rawId)) {
          target = tx;
          break;
        }
      }
    }
    if (target == null || target.amount <= 0) return;

    _showingBankPrompt = true;
    _promptedBankIds.add(target.rawId);
    try {
      await bank.markAutoPrompted(target.rawId);
      if (!mounted || !_foreground) return;
      await BankTransactionPromptSheet.show(
        context,
        transaction: target,
        userId: widget.user!.uid,
      );
    } finally {
      _showingBankPrompt = false;
    }

    // Other items remain in the inbox. Never chain popups after dismissal.
  }

  Future<void> _openBankInbox({int initialTab = 0}) async {
    if (!mounted || widget.user == null || _showingBankInbox) return;
    _showingBankInbox = true;
    try {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NotificationScreen(
                userId: widget.user!.uid,
                initialTab: initialTab,
              )));
    } finally {
      _showingBankInbox = false;
    }
  }

  Future<void> _handleLaunchAction(String action) async {
    if (!mounted || widget.user == null) return;
    if (action == 'open_bank_inbox') {
      await _openBankInbox(initialTab: 0);
    } else if (action == 'open_activity_notifications') {
      await _openBankInbox(initialTab: 1);
    } else if (action == 'open_dashboard') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (mounted && _currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
    } else if (action == 'add_transaction') {
      if (_openingQuickAdd) return;
      _openingQuickAdd = true;
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(userId: widget.user!.uid),
          ),
        );
      } finally {
        _openingQuickAdd = false;
      }
    }
  }

  Future<void> _ensurePostNotificationsPermissionOnStart() async {
    final bank = BankSyncService();
    if (!bank.supported) return;
    try {
      final alreadyGranted = await bank.isPostNotificationsGranted();
      if (alreadyGranted) {
        await bank.updateAppBadge();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      const key = 'finora_post_notif_prompted_v1';
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      final ok = await bank.requestPostNotifications();
      if (ok) {
        await bank.updateAppBadge();
      }
    } catch (_) {}
  }

  Future<void> _syncWidgetsFromCurrentState() async {
    if (!mounted) return;
    final dash = Provider.of<DashboardProvider?>(context, listen: false);
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final bank = BankSyncService();
    if (dash == null) return;
    await HomeWidgetSyncService().sync(
      dashboardData: dash.data,
      pendingCount: bank.pending.length + bank.unrecognizedCount,
      manualPendingCount: bank.manualPendingCount,
      hideAmounts: studio?.isPrivacyShieldActive ?? false,
    );
  }

  Future<void> _dispatchNewStatusBarNotifications(
    List<AppNotification> unreadItems,
  ) async {
    if (_checkingShownNotifs || unreadItems.isEmpty) return;
    final bank = BankSyncService();
    if (!bank.supported) return;
    _checkingShownNotifs = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'finora_shown_system_notifs_v1';
      final shown = (prefs.getStringList(key) ?? const <String>[]).toSet();
      final cutoffMs = DateTime.now()
          .subtract(const Duration(hours: 48))
          .millisecondsSinceEpoch;

      final toPost = <AppNotification>[];
      for (final item in unreadItems) {
        if (item.id.isEmpty || shown.contains(item.id)) continue;
        if (item.createdAt > 0 && item.createdAt < cutoffMs) {
          shown.add(item.id);
          continue;
        }
        toPost.add(item);
      }

      if (toPost.isNotEmpty) {
        final granted = await bank.isPostNotificationsGranted();
        final notifPrefs = await HomeWidgetSyncService().loadPreferences();
        if (granted) {
          for (final item in toPost.take(3)) {
            if (!notifPrefs.allowsActivityNotification(item)) {
              shown.add(item.id);
              continue;
            }
            final title = (item.title ?? '').trim().isNotEmpty
                ? item.title!.trim()
                : 'FINORA Thông báo';
            final body = !notifPrefs.notifyShowAmount
                ? 'Bạn có thông báo tài chính mới trong FINORA • Chạm để xem.'
                : ((item.message ?? '').trim().isNotEmpty
                    ? item.message!.trim()
                    : 'Bạn có thông báo tài chính mới.');
            await bank.showSystemNotification(
              title: title,
              body: body,
              channel: 'activity',
              id: (item.id.hashCode & 0x7FFF) + 5000,
              fromBankSync: false,
              action: 'open_activity_notifications',
            );
            shown.add(item.id);
          }
        }
      }
      final trimmed = shown.toList();
      await prefs.setStringList(
        key,
        trimmed.length > 80 ? trimmed.sublist(trimmed.length - 80) : trimmed,
      );
    } catch (_) {
    } finally {
      _checkingShownNotifs = false;
    }
  }

  void _initBankSync() {
    if (widget.user == null) return;
    _bankListener = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncWidgetsFromCurrentState();
      });
    };
    BankSyncService().addListener(_bankListener!);

    _bankInboxSubscription = BankSyncService().onInboxRequested.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openBankInbox();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    _launchActionSubscription = BankSyncService().onLaunchAction.listen((action) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleLaunchAction(action);
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
      unawaited(BankSyncService().bindUser(widget.user?.uid));
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _promptPendingBankTransactions();
          _ensurePostNotificationsPermissionOnStart();
          _syncWidgetsFromCurrentState();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bankSyncSubscription?.cancel();
    _bankInboxSubscription?.cancel();
    _launchActionSubscription?.cancel();
    if (_bankListener != null) {
      BankSyncService().removeListener(_bankListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid ?? '';
    final familyId = context.watch<FamilyProvider>().familyId;
    final more = context.watch<MoreProvider?>();
    context.watch<DashboardProvider?>();
    context.watch<ThemeStudioController?>();

    if (more != null) {
      final unread = more.notifications.where((n) => !n.isRead).toList();
      final sig = unread.map((n) => '${n.id}:${n.createdAt}').join('|');
      if (sig != _lastMoreSyncSig) {
        _lastMoreSyncSig = sig;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(BankSyncService().setUnreadActivityCount(unread.length));
          unawaited(_dispatchNewStatusBarNotifications(unread));
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWidgetsFromCurrentState();
    });

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

    void handleBackOrExit() {
      if (_currentIndex != 0) {
        setState(() => _currentIndex = 0);
      } else {
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) >
                const Duration(milliseconds: 2000)) {
          _lastBackPressTime = now;
          HapticFeedback.lightImpact();
          FinoraNotice.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vuốt lần nữa để thoát FINORA',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor:
                    const Color(0xFF0F172A).withValues(alpha: 0.94),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              ),
            );
        } else {
          // Lần vuốt thứ 2 trong vòng 2 giây: Thoát app mượt mà tối ưu cho Android 17
          HapticFeedback.heavyImpact();
          SystemNavigator.pop();
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackOrExit();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardOpen = bottomInset > 60;

          if (isWide) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AmbientFloatingBackground(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131A22).withValues(alpha: 0.96)
                            : Colors.white.withValues(alpha: 0.96),
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? const Color(0xFF25303E)
                                : const Color(0xFFE2EAE6),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _currentIndex = index),
                          backgroundColor: Colors.transparent,
                          labelType: NavigationRailLabelType.all,
                          indicatorColor: const Color(0xFF0F6E56)
                              .withValues(alpha: isDark ? 0.28 : 0.14),
                          selectedIconTheme: IconThemeData(
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F6E56),
                          ),
                          selectedLabelTextStyle: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F6E56),
                          ),
                          unselectedLabelTextStyle: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF556862),
                          ),
                          leading: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 16),
                            child: FloatingActionButton(
                              heroTag: 'wide_rail_add_fab',
                              backgroundColor: const Color(0xFF0F6E56),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              onPressed: () {
                                showSuperActionSheet(
                                    context: context, userId: uid);
                              },
                              child: const Icon(Icons.add_rounded, size: 26),
                            ),
                          ),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(Icons.home_rounded),
                              label: Text('Tổng quan'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.account_balance_wallet_outlined),
                              selectedIcon:
                                  Icon(Icons.account_balance_wallet_rounded),
                              label: Text('Sổ & Ví'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.insights_outlined),
                              selectedIcon: Icon(Icons.insights_rounded),
                              label: Text('Báo cáo'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.person_outline_rounded),
                              selectedIcon: Icon(Icons.person_rounded),
                              label: Text('Cá nhân'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: FinoraFluidTabSwitcher(
                        currentIndex: _currentIndex,
                        children: pages,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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
