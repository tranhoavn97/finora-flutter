import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finora/core/services/bank_sync_service.dart';
import 'package:finora/core/services/home_widget_sync_service.dart';
import 'package:finora/core/widgets/finora_home_widget_card.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/features/settings/bank_sync_settings_sheet.dart';
import 'package:finora/state/dashboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bankChannel = MethodChannel('com.finora/bank_sync');
  const widgetChannel = MethodChannel('com.finora/home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bankChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
    await BankSyncService().acknowledgeAll();
    await BankSyncService().setUnreadActivityCount(0);
    debugDefaultTargetPlatformOverride = null;
  });

  test('HomeWidgetSyncService computes live today spend, balance & recent items',
      () {
    final now = DateTime(2026, 11, 15, 22, 18);
    final yesterday = DateTime(2026, 11, 14, 10, 0);

    final data = DashboardData(
      totalWalletBalance: 24500000,
      currentMonthIncome: 15200000,
      currentMonthExpenses: 8420000,
      allTransactions: [
        TransactionModel(
          id: 't1',
          amount: 55000,
          type: 'expense',
          date: now.millisecondsSinceEpoch,
          categoryName: 'Ăn uống',
          note: 'Cà phê sáng',
          walletName: 'Vietcombank',
        ),
        TransactionModel(
          id: 't2',
          amount: 190000,
          type: 'expense',
          date: now.millisecondsSinceEpoch - 3600000,
          categoryName: 'Mua sắm',
          note: 'Siêu thị',
          walletName: 'NCB',
        ),
        TransactionModel(
          id: 't3',
          amount: 1000000,
          type: 'income',
          date: now.millisecondsSinceEpoch - 1800000,
          categoryName: 'Chuyển đến',
          note: 'Nhận chuyển khoản',
          walletName: 'NCB',
        ),
        TransactionModel(
          id: 't4',
          amount: 500000,
          type: 'expense',
          date: yesterday.millisecondsSinceEpoch,
          categoryName: 'Xăng xe',
          walletName: 'Tiền mặt',
        ),
      ],
      recentTransactions: [
        TransactionModel(
          id: 't1',
          amount: 55000,
          type: 'expense',
          date: now.millisecondsSinceEpoch,
          categoryName: 'Ăn uống',
          note: 'Cà phê sáng',
          walletName: 'Vietcombank',
        ),
        TransactionModel(
          id: 't3',
          amount: 1000000,
          type: 'income',
          date: now.millisecondsSinceEpoch - 1800000,
          categoryName: 'Chuyển đến',
          note: 'Nhận chuyển khoản',
          walletName: 'NCB',
        ),
      ],
    );

    final payload = HomeWidgetSyncService.buildPayload(
      dashboardData: data,
      pendingCount: 2,
      hideAmounts: false,
      now: now,
    );

    expect(payload['todayExpense'], 245000.0);
    expect(payload['todayCount'], 3);
    expect(payload['monthExpense'], 8420000.0);
    expect(payload['monthIncome'], 15200000.0);
    expect(payload['totalBalance'], 24500000.0);
    expect(payload['pendingCount'], 2);
    expect(payload['hideAmounts'], false);
    expect(payload['syncedAt'], '22:18');

    final recent = payload['recent'] as List<dynamic>;
    expect(recent, hasLength(2));
    expect((recent[0] as Map)['title'], 'Cà phê sáng');
    expect((recent[0] as Map)['amount'], -55000);
    expect((recent[1] as Map)['amount'], 1000000);
  });

  test('BankSyncService syncs combined badge count (bank pending + activity unread)',
      () async {
    final badgeCalls = <Map<String, dynamic>>[];
    final notifCalls = <Map<String, dynamic>>[];
    var postGranted = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bankChannel, (call) async {
      switch (call.method) {
        case 'isPostNotificationsGranted':
          return postGranted;
        case 'updateAppBadge':
          badgeCalls.add(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        case 'setExtraBadgeCount':
          return true;
        case 'showSystemNotification':
          notifCalls.add(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        case 'consumeLaunchAction':
          return null;
        case 'consumeBankInboxRequest':
          return false;
        case 'updateScanSettings':
          return true;
        case 'getPendingNotifications':
          return [
            jsonEncode({
              'id': 'ncb-badge-1',
              'package': 'com.ncb.izimobile',
              'title': 'Nhận chuyển khoản',
              'text': 'Phát sinh: +1,000,000 VND\nSố dư: +2,734,539 VND',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          ];
        case 'getSyncStatus':
          return {'connected': true, 'lastReceivedAt': 0};
        case 'acknowledgeNotifications':
          return true;
      }
      return null;
    });

    final service = BankSyncService();
    await service.initialize();
    expect(service.pending, hasLength(1));

    await service.setUnreadActivityCount(3);
    expect(service.totalBadgeCount, 4);
    expect(badgeCalls.last['count'], 4);
    expect(badgeCalls.last['extraCount'], 3);

    // Unrecognized native notifications must NOT be double-counted in native extraCount
    await service.acknowledgeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bankChannel, (call) async {
      switch (call.method) {
        case 'isPostNotificationsGranted':
          return postGranted;
        case 'updateAppBadge':
          badgeCalls.add(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        case 'showSystemNotification':
          notifCalls.add(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        case 'consumeLaunchAction':
          return null;
        case 'consumeBankInboxRequest':
          return false;
        case 'updateScanSettings':
          return true;
        case 'getPendingNotifications':
          return [
            jsonEncode({
              'id': 'ncb-unrec-1',
              'package': 'com.ncb.izimobile',
              'title': 'NCB iziMobile',
              'text': 'Thông báo bảo trì hệ thống định kỳ',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          ];
        case 'getSyncStatus':
          return {'connected': true, 'lastReceivedAt': 0};
        case 'acknowledgeNotifications':
          return true;
      }
      return null;
    });
    await service.checkPendingNotifications();
    expect(service.unrecognizedCount, 1);
    expect(service.totalBadgeCount, 4); // 1 unrecognized + 3 unread activity
    expect(badgeCalls.last['count'], 4);
    // Native queue already holds ncb-unrec-1, so extraCount must only include unread activity (3)
    expect(badgeCalls.last['extraCount'], 3);

    final shown = await service.showSystemNotification(
      title: 'Test',
      body: 'Body',
      channel: 'bank',
      fromBankSync: true,
    );
    expect(shown, isTrue);
    expect(notifCalls.single['channel'], 'bank');
    expect(notifCalls.single['fromBankSync'], isTrue);

    await service.acknowledgeAll();
    expect(service.pending, isEmpty);
    expect(service.unrecognizedCount, 0);
    expect(service.totalBadgeCount, 3);
    expect(badgeCalls.last['count'], 3);
    expect(badgeCalls.last['extraCount'], 3);

    postGranted = false;
    expect(await service.isPostNotificationsGranted(), isFalse);
  });

  testWidgets('FinoraHomeWidgetCard renders 5x2 & 5x4 previews and pins widgets',
      (tester) async {
    try {
      final pinnedTypes = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, (call) async {
        if (call.method == 'canPinWidgets') return true;
        if (call.method == 'syncWidgetData') return true;
        if (call.method == 'requestPinWidget') {
          pinnedTypes.add((call.arguments as Map)['widgetType'].toString());
          return true;
        }
        return null;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinoraHomeWidgetCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Widget màn hình chính (5×2 & 5×4)'), findsOneWidget);
      expect(find.text('MẪU 5×2 • GỌN & TRỰC QUAN'), findsOneWidget);
      expect(
        find.text('MẪU 5×4 • ĐẦY ĐỦ CHI TIÊU & SỐ DƯ CHỜ'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Ghim 5×2'));
      await tester.tap(find.text('Ghim 5×2'));
      await tester.pump();
      await tester.ensureVisible(find.text('Ghim 5×4'));
      await tester.tap(find.text('Ghim 5×4'));
      await tester.pump();

      expect(pinnedTypes, ['5x2', '5x4']);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('BankSyncSettingsSheet shows bright notification toggle & test actions',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      var postEnabled = true;
      var openedSettings = false;
      var testedNotif = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bankChannel, (call) async {
        switch (call.method) {
          case 'isPermissionGranted':
            return true;
          case 'isPostNotificationsGranted':
            return postEnabled;
          case 'openNotificationSettings':
            openedSettings = true;
            return true;
          case 'showSystemNotification':
            testedNotif = true;
            return true;
          case 'updateAppBadge':
            return true;
          case 'getPendingNotifications':
            return <String>[];
          case 'getSyncStatus':
            return {'connected': true, 'lastReceivedAt': 0};
        }
        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, (call) async {
        if (call.method == 'canPinWidgets') return true;
        return true;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BankSyncSettingsSheet(userId: 'u1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông báo & Số trên biểu tượng app'), findsOneWidget);
      expect(find.text('Cài đặt thông báo máy'), findsOneWidget);
      expect(find.text('Thử thông báo'), findsOneWidget);

      await tester.tap(find.text('Thử thông báo'));
      await tester.pump();
      expect(testedNotif, isTrue);

      await tester.tap(find.text('Cài đặt thông báo máy'));
      await tester.pump();
      expect(openedSettings, isTrue);

      postEnabled = false;
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('HomeWidgetPreferences resolves mascot moods, glass payload, and notification filters',
      () {
    const base = HomeWidgetPreferences(
      glassStyle: 'glass_crystal',
      showMascot: true,
      mascotMood: 'auto',
      showRecentTx: false,
      notifyBudgetAlert: false,
      notifyLoanReminder: true,
      notifyShowAmount: false,
    );

    expect(base.isLightGlass, isTrue);
    expect(
      base.resolveMascotAsset(pendingCount: 2, todayExpense: 50000),
      'assets/mascot/mascot_focused.png',
    );
    expect(
      base.resolveMascotAsset(pendingCount: 0, todayExpense: 0),
      'assets/mascot/mascot_celebrate.png',
    );
    expect(
      base.resolveMascotAsset(pendingCount: 0, todayExpense: 120000),
      'assets/mascot/mascot_happy.png',
    );

    final payload = HomeWidgetSyncService.buildPayload(
      dashboardData: const DashboardData(),
      pendingCount: 1,
      hideAmounts: false,
      preferences: base,
    );
    final styleMap = payload['widgetStyle'] as Map<String, dynamic>;
    expect(styleMap['glassStyle'], 'glass_crystal');
    expect(styleMap['showMascot'], isTrue);
    expect(styleMap['showRecentTx'], isFalse);

    const budgetNotif = AppNotification(
      id: 'n1',
      type: 'budget_warning',
      title: 'Cảnh báo ngân sách Ăn uống',
      message: 'Đã vượt 90% hạn mức',
    );
    const loanNotif = AppNotification(
      id: 'n2',
      type: 'loan_reminder',
      title: 'Nhắc lịch thu nợ',
      message: 'Đến hạn thu nợ hôm nay',
    );
    expect(base.allowsActivityNotification(budgetNotif), isFalse);
    expect(base.allowsActivityNotification(loanNotif), isTrue);

    final roundTripped = HomeWidgetPreferences.fromJson(base.toJson());
    expect(roundTripped.glassStyle, 'glass_crystal');
    expect(roundTripped.showRecentTx, isFalse);
    expect(roundTripped.notifyBudgetAlert, isFalse);
    expect(roundTripped.notifyShowAmount, isFalse);
  });

  testWidgets('FinoraHomeWidgetCard allows customizing glass style and notification filters',
      (tester) async {
    try {
      final notifPrefCalls = <Map<String, dynamic>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, (call) async {
        if (call.method == 'canPinWidgets') return true;
        if (call.method == 'updateNotificationPrefs') {
          notifPrefCalls.add(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        }
        return true;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinoraHomeWidgetCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch glass style to Kính pha lê
      await tester.ensureVisible(find.text('Kính pha lê'));
      await tester.tap(find.text('Kính pha lê'));
      await tester.pumpAndSettle();
      expect(HomeWidgetSyncService().preferences.glassStyle, 'glass_crystal');

      // Switch to Notification customization tab
      await tester.ensureVisible(find.text('Tuỳ chỉnh thông báo'));
      await tester.tap(find.text('Tuỳ chỉnh thông báo'));
      await tester.pumpAndSettle();
      expect(find.text('CHỌN LOẠI THÔNG BÁO MUỐN NHẬN'), findsOneWidget);
      expect(find.text('Biến động trừ tiền / chi tiêu'), findsOneWidget);
      expect(find.text('Hiển thị rõ số tiền trên thông báo'), findsOneWidget);

      // Toggle the first switch (Biến động trừ tiền / chi tiêu)
      final firstSwitch = find.byType(Switch).first;
      await tester.ensureVisible(firstSwitch);
      await tester.tap(firstSwitch);
      await tester.pumpAndSettle();
      expect(HomeWidgetSyncService().preferences.notifyBankExpense, isFalse);
      expect(notifPrefCalls.isNotEmpty, isTrue);
      expect(notifPrefCalls.last['notifyBankExpense'], isFalse);

      // Restore defaults so later tests aren't affected
      await HomeWidgetSyncService()
          .updatePreferences(const HomeWidgetPreferences());
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
