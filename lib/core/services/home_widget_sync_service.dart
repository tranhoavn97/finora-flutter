import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/finance_models.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/dashboard_provider.dart';

/// User-customizable settings for both Android Home Screen Widgets (glass style,
/// Finora mascot display, visible KPI/feed sections) and push notification filters.
class HomeWidgetPreferences {
  final String glassStyle; // glass_frost | glass_crystal | glass_aurora
  final bool showMascot;
  final String mascotMood; // auto | happy | focused | celebrate | confident
  final bool showTodaySpend;
  final bool showMonthSummary;
  final bool showTotalBalance;
  final bool showPendingBank;
  final bool showRecentTx;
  final bool showQuickActions;

  // Notification customization ("tuỳ chỉnh được thông báo những gì")
  final bool notifyBankExpense;
  final bool notifyBankIncome;
  final bool notifyBudgetAlert;
  final bool notifyLoanReminder;
  final bool notifyShowAmount;
  final bool notifyAppBadge;

  const HomeWidgetPreferences({
    this.glassStyle = 'glass_frost',
    this.showMascot = true,
    this.mascotMood = 'auto',
    this.showTodaySpend = true,
    this.showMonthSummary = true,
    this.showTotalBalance = true,
    this.showPendingBank = true,
    this.showRecentTx = true,
    this.showQuickActions = true,
    this.notifyBankExpense = true,
    this.notifyBankIncome = true,
    this.notifyBudgetAlert = true,
    this.notifyLoanReminder = true,
    this.notifyShowAmount = true,
    this.notifyAppBadge = true,
  });

  bool get isLightGlass => glassStyle == 'glass_crystal';

  HomeWidgetPreferences copyWith({
    String? glassStyle,
    bool? showMascot,
    String? mascotMood,
    bool? showTodaySpend,
    bool? showMonthSummary,
    bool? showTotalBalance,
    bool? showPendingBank,
    bool? showRecentTx,
    bool? showQuickActions,
    bool? notifyBankExpense,
    bool? notifyBankIncome,
    bool? notifyBudgetAlert,
    bool? notifyLoanReminder,
    bool? notifyShowAmount,
    bool? notifyAppBadge,
  }) {
    return HomeWidgetPreferences(
      glassStyle: glassStyle ?? this.glassStyle,
      showMascot: showMascot ?? this.showMascot,
      mascotMood: mascotMood ?? this.mascotMood,
      showTodaySpend: showTodaySpend ?? this.showTodaySpend,
      showMonthSummary: showMonthSummary ?? this.showMonthSummary,
      showTotalBalance: showTotalBalance ?? this.showTotalBalance,
      showPendingBank: showPendingBank ?? this.showPendingBank,
      showRecentTx: showRecentTx ?? this.showRecentTx,
      showQuickActions: showQuickActions ?? this.showQuickActions,
      notifyBankExpense: notifyBankExpense ?? this.notifyBankExpense,
      notifyBankIncome: notifyBankIncome ?? this.notifyBankIncome,
      notifyBudgetAlert: notifyBudgetAlert ?? this.notifyBudgetAlert,
      notifyLoanReminder: notifyLoanReminder ?? this.notifyLoanReminder,
      notifyShowAmount: notifyShowAmount ?? this.notifyShowAmount,
      notifyAppBadge: notifyAppBadge ?? this.notifyAppBadge,
    );
  }

  Map<String, dynamic> toWidgetStyleMap() => <String, dynamic>{
        'glassStyle': glassStyle,
        'showMascot': showMascot,
        'mascotMood': mascotMood,
        'showTodaySpend': showTodaySpend,
        'showMonthSummary': showMonthSummary,
        'showTotalBalance': showTotalBalance,
        'showPendingBank': showPendingBank,
        'showRecentTx': showRecentTx,
        'showQuickActions': showQuickActions,
      };

  Map<String, dynamic> toNotificationPrefsMap() => <String, dynamic>{
        'notifyBankExpense': notifyBankExpense,
        'notifyBankIncome': notifyBankIncome,
        'notifyBudgetAlert': notifyBudgetAlert,
        'notifyLoanReminder': notifyLoanReminder,
        'notifyShowAmount': notifyShowAmount,
        'notifyAppBadge': notifyAppBadge,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...toWidgetStyleMap(),
        ...toNotificationPrefsMap(),
      };

  factory HomeWidgetPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HomeWidgetPreferences();
    const validStyles = {'glass_frost', 'glass_crystal', 'glass_aurora'};
    const validMoods = {'auto', 'happy', 'focused', 'celebrate', 'confident'};
    final rawStyle = json['glassStyle']?.toString() ?? 'glass_frost';
    final rawMood = json['mascotMood']?.toString() ?? 'auto';
    return HomeWidgetPreferences(
      glassStyle: validStyles.contains(rawStyle) ? rawStyle : 'glass_frost',
      showMascot: json['showMascot'] is bool ? json['showMascot'] as bool : true,
      mascotMood: validMoods.contains(rawMood) ? rawMood : 'auto',
      showTodaySpend:
          json['showTodaySpend'] is bool ? json['showTodaySpend'] as bool : true,
      showMonthSummary: json['showMonthSummary'] is bool
          ? json['showMonthSummary'] as bool
          : true,
      showTotalBalance: json['showTotalBalance'] is bool
          ? json['showTotalBalance'] as bool
          : true,
      showPendingBank: json['showPendingBank'] is bool
          ? json['showPendingBank'] as bool
          : true,
      showRecentTx:
          json['showRecentTx'] is bool ? json['showRecentTx'] as bool : true,
      showQuickActions: json['showQuickActions'] is bool
          ? json['showQuickActions'] as bool
          : true,
      notifyBankExpense: json['notifyBankExpense'] is bool
          ? json['notifyBankExpense'] as bool
          : true,
      notifyBankIncome: json['notifyBankIncome'] is bool
          ? json['notifyBankIncome'] as bool
          : true,
      notifyBudgetAlert: json['notifyBudgetAlert'] is bool
          ? json['notifyBudgetAlert'] as bool
          : true,
      notifyLoanReminder: json['notifyLoanReminder'] is bool
          ? json['notifyLoanReminder'] as bool
          : true,
      notifyShowAmount: json['notifyShowAmount'] is bool
          ? json['notifyShowAmount'] as bool
          : true,
      notifyAppBadge: json['notifyAppBadge'] is bool
          ? json['notifyAppBadge'] as bool
          : true,
    );
  }

  /// Resolves the active mascot asset path for Flutter previews matching Android native logic.
  String resolveMascotAsset({
    required int pendingCount,
    required num todayExpense,
  }) {
    switch (mascotMood) {
      case 'happy':
        return 'assets/mascot/mascot_happy.png';
      case 'focused':
        return 'assets/mascot/mascot_focused.png';
      case 'celebrate':
        return 'assets/mascot/mascot_celebrate.png';
      case 'confident':
        return 'assets/mascot/mascot_confident.png';
      default:
        if (pendingCount > 0) return 'assets/mascot/mascot_focused.png';
        if (todayExpense <= 0) return 'assets/mascot/mascot_celebrate.png';
        return 'assets/mascot/mascot_happy.png';
    }
  }

  /// Checks whether an in-app activity notification should post to the Android status bar.
  bool allowsActivityNotification(AppNotification item) {
    final typeLower = (item.type ?? '').toLowerCase();
    final combined =
        '${item.type ?? ''} ${item.title ?? ''} ${item.message ?? ''}'
            .toLowerCase();
    final isBudget = typeLower.contains('budget') ||
        combined.contains('ngân sách') ||
        combined.contains('hạn mức');
    if (isBudget) return notifyBudgetAlert;
    return notifyLoanReminder;
  }
}

/// Synchronizes live spending metrics, wallet balance, pending bank queue count,
/// frosted glass + mascot style, and notification preferences to Android Home Screen Widgets.
class HomeWidgetSyncService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.finora/home_widget');
  static const String _prefsKey = 'finora_home_widget_custom_prefs_v1';
  static final HomeWidgetSyncService _instance =
      HomeWidgetSyncService._internal();
  factory HomeWidgetSyncService() => _instance;
  HomeWidgetSyncService._internal();

  String _lastSignature = '';
  HomeWidgetPreferences _preferences = const HomeWidgetPreferences();
  bool _prefsLoaded = false;

  // Cached latest data so preference updates immediately refresh native widgets.
  DashboardData? _lastDashboardData;
  int _lastPendingCount = 0;
  int _lastManualPendingCount = 0;
  bool _lastHideAmounts = false;

  HomeWidgetPreferences get preferences => _preferences;

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<HomeWidgetPreferences> loadPreferences({bool force = false}) async {
    if (_prefsLoaded && !force) return _preferences;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_prefsKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _preferences = HomeWidgetPreferences.fromJson(decoded);
        }
      }
      _prefsLoaded = true;
      notifyListeners();
    } catch (_) {}
    return _preferences;
  }

  Future<void> updatePreferences(
    HomeWidgetPreferences next, {
    DashboardData? dashboardData,
    int? pendingCount,
    int? manualPendingCount,
    bool? hideAmounts,
  }) async {
    _preferences = next;
    _prefsLoaded = true;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (_) {}

    if (supported) {
      try {
        await _channel.invokeMethod(
          'updateNotificationPrefs',
          next.toNotificationPrefsMap(),
        );
      } catch (_) {}
    }

    final dash = dashboardData ?? _lastDashboardData;
    if (dash != null) {
      await sync(
        dashboardData: dash,
        pendingCount: pendingCount ?? _lastPendingCount,
        manualPendingCount: manualPendingCount ?? _lastManualPendingCount,
        hideAmounts: hideAmounts ?? _lastHideAmounts,
        preferences: next,
        force: true,
      );
    } else if (supported) {
      await refreshWidgets();
    }
  }

  /// Pure snapshot payload builder shared between native sync and unit tests.
  static Map<String, dynamic> buildPayload({
    required DashboardData dashboardData,
    required int pendingCount,
    int manualPendingCount = 0,
    required bool hideAmounts,
    HomeWidgetPreferences? preferences,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    var todayExpense = 0;
    var todayCount = 0;

    for (final t in dashboardData.allTransactions) {
      if (t.date <= 0) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      if (dt.year == ref.year && dt.month == ref.month && dt.day == ref.day) {
        todayCount++;
        final normalized = WalletRepository.normalizeTransactionType(t.type);
        if (normalized == 'expense') {
          todayExpense += t.amount.abs();
        }
      }
    }

    final recent = dashboardData.recentTransactions.take(3).map((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      final type = WalletRepository.normalizeTransactionType(t.type);
      final cleanNote = (t.note ?? '').trim();
      final title = cleanNote.isNotEmpty
          ? cleanNote
          : (t.categoryName?.trim().isNotEmpty == true
              ? t.categoryName!.trim()
              : (type == 'transfer' ? 'Chuyển khoản' : 'Giao dịch'));
      final walletLabel = (t.walletName ?? t.fromWalletName ?? '').trim();
      final metaParts = <String>[
        if (t.categoryName != null &&
            t.categoryName!.trim().isNotEmpty &&
            cleanNote.isNotEmpty)
          t.categoryName!.trim(),
        if (walletLabel.isNotEmpty) walletLabel,
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}',
      ];
      return <String, dynamic>{
        'title': title,
        'meta': metaParts.join(' • '),
        'amount': type == 'income' ? t.amount.abs() : -t.amount.abs(),
        'type': type,
      };
    }).toList();

    final hh = ref.hour.toString().padLeft(2, '0');
    final mm = ref.minute.toString().padLeft(2, '0');
    final activePrefs = preferences ?? const HomeWidgetPreferences();

    return <String, dynamic>{
      'todayExpense': todayExpense.toDouble(),
      'todayCount': todayCount,
      'monthExpense': dashboardData.currentMonthExpenses.abs().toDouble(),
      'monthIncome': dashboardData.currentMonthIncome.abs().toDouble(),
      'totalBalance': dashboardData.totalWalletBalance.toDouble(),
      'hideAmounts': hideAmounts,
      'pendingCount': pendingCount < 0 ? 0 : pendingCount,
      'manualPendingCount': manualPendingCount < 0 ? 0 : manualPendingCount,
      'syncedAt': '$hh:$mm',
      'recent': recent,
      'widgetStyle': activePrefs.toWidgetStyleMap(),
    };
  }

  Future<void> sync({
    required DashboardData dashboardData,
    required int pendingCount,
    int manualPendingCount = 0,
    required bool hideAmounts,
    HomeWidgetPreferences? preferences,
    bool force = false,
  }) async {
    _lastDashboardData = dashboardData;
    _lastPendingCount = pendingCount;
    _lastManualPendingCount = manualPendingCount;
    _lastHideAmounts = hideAmounts;

    if (!supported) return;
    if (!_prefsLoaded && preferences == null) {
      await loadPreferences();
    }
    final activePrefs = preferences ?? _preferences;
    final payload = buildPayload(
      dashboardData: dashboardData,
      pendingCount: pendingCount,
      manualPendingCount: manualPendingCount,
      hideAmounts: hideAmounts,
      preferences: activePrefs,
    );
    final signature = jsonEncode(<String, dynamic>{
      'todayExpense': payload['todayExpense'],
      'todayCount': payload['todayCount'],
      'monthExpense': payload['monthExpense'],
      'monthIncome': payload['monthIncome'],
      'totalBalance': payload['totalBalance'],
      'hideAmounts': payload['hideAmounts'],
      'pendingCount': payload['pendingCount'],
      'manualPendingCount': payload['manualPendingCount'],
      'recent': payload['recent'],
      'widgetStyle': payload['widgetStyle'],
    });
    if (!force && signature == _lastSignature) return;
    _lastSignature = signature;

    try {
      await _channel.invokeMethod('syncWidgetData', {
        'payload': jsonEncode(payload),
      });
      await _channel.invokeMethod(
        'updateNotificationPrefs',
        activePrefs.toNotificationPrefsMap(),
      );
    } catch (_) {}
  }

  Future<void> refreshWidgets() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('refreshWidgets');
    } catch (_) {}
  }

  Future<bool> canPinWidgets() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('canPinWidgets') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests the Android launcher to pin the 5x2 or 5x4 FINORA Home Widget.
  Future<bool> requestPinWidget(String widgetType) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPinWidget', {
            'widgetType': widgetType == '5x4' ? '5x4' : '5x2',
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
