import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/services/bank_notification_source.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/services/bank_sync_service.dart';
import 'package:finora/core/widgets/adaptive_glass_surface.dart';
import 'package:finora/core/widgets/glass_widgets.dart';
import 'package:finora/core/widgets/finora_transaction_success_modal.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/core/widgets/bank_transaction_prompt_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'Bank-looking chat and shopping notifications never enter financial queue',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({
      'finora_scan_ecommerce': true,
      'finora_scan_all_apps': true,
      'finora_bank_auto_prompted_v1': ['previously-shown'],
    });
    const channel = MethodChannel('com.finora/bank_sync');
    final queue = [
      for (final pkg in [
        'com.facebook.katana',
        'com.zing.zalo',
        'com.shopee.vn',
        'com.ss.android.ugc.trill',
        'com.android.chrome',
        'com.VCB'
      ])
        jsonEncode({
          'id': 'source-$pkg',
          'package': pkg,
          'title': 'Vietcombank',
          'text': 'GD: -50.000 VND. ND: Thanh toan an trua',
          'timestamp': 1793400000000
        }),
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'getPendingNotifications' ? queue : false);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = BankSyncService();
    await service.initialize();
    expect(service.pending.map((e) => e.rawId), ['source-com.VCB']);
    expect(service.scanEcommerce, false);
    expect(service.scanAllApps, false);
    expect(service.wasAutoPrompted('previously-shown'), true);
    await service.markAutoPrompted('source-com.VCB');
    await service.loadScanSettings();
    expect(service.wasAutoPrompted('source-com.VCB'), true);
    expect(
        (await SharedPreferences.getInstance())
            .getStringList('finora_bank_auto_prompted_v1'),
        contains('source-com.VCB'));
    expect(queue, hasLength(6)); // No source ledger or queue was deleted.
  });

  test('SMS requires exact sender and wallet setting applies to push and SMS',
      () {
    expect(
        BankNotificationSource.accepts(
            'com.google.android.apps.messaging', 'VCB'),
        true);
    expect(
        BankNotificationSource.accepts(
            'com.google.android.apps.messaging', 'Bạn nói VCB'),
        false);
    expect(BankNotificationSource.accepts('com.zing.zalo', 'VCB'), false);
    expect(
        BankNotificationSource.accepts('com.mservice.momotransfer', 'MoMo',
            wallets: false),
        false);
    expect(
        BankNotificationSource.accepts(
            'com.google.android.apps.messaging', 'MoMo',
            wallets: false),
        false);
  });

  test(
      'Account number without currency and signed balance are not expense amounts',
      () {
    for (final text in [
      'Số dư: -50.000 VND',
      'SD: -50.000 VND',
      'Bạn đã chuyển 012345678901 đến tài khoản thụ hưởng'
    ]) {
      expect(
          BankNotificationParser.parse(
              rawId: 'negative',
              packageName: 'com.VCB',
              title: 'VCB',
              text: text),
          isNull,
          reason: text);
    }
  });

  testWidgets(
      'Body below Scaffold appbar adds only six pixels, including system inset',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final studio = ThemeStudioController();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: studio,
        child: MaterialApp(
            home: GlassScaffold(
                appBar: const GlassTopBar(title: 'Tiêu đề'),
                body: Builder(
                    builder: (context) => Padding(
                        padding: EdgeInsets.only(
                            top: GlassScaffold.topInset(context)),
                        child: const Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                                key: ValueKey('first-card'),
                                width: 100,
                                height: 40))))))));
    await tester.pump();
    final bar = tester.getRect(find.byType(GlassTopBar));

    expect(
        tester.getTopLeft(find.byKey(const ValueKey('first-card'))).dy -
            bar.bottom,
        6);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Opacity and low blur persist and change neutral surface without fading text',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'finora_studio_glass_opacity': 0.07,
      'finora_studio_glass_blur': 8.0,
    });
    var studio = ThemeStudioController();
    await studio.load();
    expect(studio.glassOpacity, .07);
    expect(studio.glassBlur, 8);
    await studio.setGlassOpacity(0);
    await studio.setGlassBlur(0);
    studio = ThemeStudioController();
    await studio.load();
    expect(studio.glassOpacity, 0);
    expect(studio.glassBlur, 0);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: studio,
        child: const MaterialApp(
            home: Scaffold(
                body: AdaptiveGlassSurface(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Text('Dễ đọc'))))));
    final surface = find.descendant(
        of: find.byType(AdaptiveGlassSurface),
        matching: find.byType(Container));
    expect(
        (tester.widget<Container>(surface.last).decoration as BoxDecoration)
            .color!
            .a,
        0);
    expect(find.text('Dễ đọc'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    await studio.setGlassOpacity(.35);
    await studio.setGlassBlur(8);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
        (tester.widget<Container>(surface.last).decoration as BoxDecoration)
            .color!
            .a,
        closeTo(.35, .005));
  });

  testWidgets(
      'Ghi tiếp stays visible and tappable on narrow display with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? result;
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await FinoraTransactionSuccessModal.show(context,
                          transaction: const TransactionModel(
                              amount: 50000, categoryName: 'Ăn uống'));
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final button =
        find.byKey(const ValueKey('finora-tx-success-add-another-button'));
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('Ghi tiếp')).width,
        lessThan(tester.getRect(button).width));
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets(
      'Automatic modal fills same screen for all types and retains full message with keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const fullMessage =
        'VCB\nGD -50.000 VND\nNội dung dài còn nguyên dòng cuối: FT123456';
    for (final type in ['expense', 'income', 'transfer']) {
      await tester.pumpWidget(ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider(),
          child: MaterialApp(
              home: Scaffold(
                  body: Builder(
                      builder: (context) => TextButton(
                          child: const Text('Open'),
                          onPressed: () => BankTransactionPromptSheet.show(
                              context,
                              userId: 'test',
                              transaction: ParsedBankTransaction(
                                  rawId: type,
                                  packageName: 'com.VCB',
                                  bankCode: 'vcb',
                                  bankName: 'Vietcombank',
                                  suggestedCategoryName: 'Khác',
                                  suggestedCategoryIcon: 'wallet',
                                  amount: 50000,
                                  type: type,
                                  note: '',
                                  rawNotificationText: fullMessage,
                                  timestamp: DateTime(2026, 10, 31)))))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BankTransactionPromptSheet)),
          const Size(390, 844));
      expect(find.text(fullMessage), findsOneWidget);
      final label = find.text('Chi tiêu');
      final tab = find
          .ancestor(of: label, matching: find.byType(GestureDetector))
          .first;
      expect(
          find.descendant(of: tab, matching: find.byType(Icon)), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
