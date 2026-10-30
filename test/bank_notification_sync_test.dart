import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/services/bank_notification_parser.dart';
import 'package:finora/core/services/bank_sync_service.dart';
import 'package:finora/features/settings/bank_sync_settings_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BankNotificationParser Tests', () {
    test('Correctly parses Techcombank expense and suggests food category', () {
      final parsed = BankNotificationParser.parse(
        rawId: 'tcb_1',
        packageName: 'vn.com.techcombank.bb.app',
        title: 'Techcombank',
        text:
            'Tài khoản 19034567890011: -45,000 VND luc 12:30 29/10/2026. ND: Com tam Cali.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode.toLowerCase(),
          anyOf(equals('tcb'), equals('techcombank')));
      expect(parsed.bankName, equals('Techcombank'));
      expect(parsed.amount, equals(45000.0));
      expect(parsed.isExpense, isTrue);
      expect(parsed.accountNumber, contains('19034567890011'));
      expect(parsed.suggestedCategoryId, equals('an_uong'));
    });

    test(
        'Correctly parses Vietcombank salary income and suggests salary category',
        () {
      final parsed = BankNotificationParser.parse(
        rawId: 'vcb_1',
        packageName: 'com.VCB',
        title: 'VCB Digibank',
        text:
            'SD TK 0071000123456 +2,500,000 VND vao 14:15 29/10/2026. Ref: Luong thuong thang 10.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode.toLowerCase(), equals('vcb'));
      expect(parsed.bankName, equals('Vietcombank'));
      expect(parsed.amount, equals(2500000.0));
      expect(parsed.isExpense, isFalse);
      expect(parsed.suggestedCategoryId, equals('luong'));
    });

    test('Correctly parses MB Bank expense and suggests shopping category', () {
      final parsed = BankNotificationParser.parse(
        rawId: 'mb_1',
        packageName: 'com.mbmobile',
        title: 'MB Bank',
        text:
            'TK 038100098765 -120,000 VND luc 09:45 29/10/2026. ND: Thanh toan Shopee ma don 9821.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode.toLowerCase(),
          anyOf(equals('mb'), equals('mbbank')));
      expect(parsed.bankName, equals('MB Bank'));
      expect(parsed.amount, equals(120000.0));
      expect(parsed.isExpense, isTrue);
      expect(parsed.suggestedCategoryId, equals('mua_sam'));
    });

    test('Correctly parses MoMo e-wallet coffee expense', () {
      final parsed = BankNotificationParser.parse(
        rawId: 'momo_1',
        packageName: 'com.mservice.momopay',
        title: 'MoMo',
        text:
            'Giao dịch thành công -65.000đ tại Highlands Coffee. Mã GD: 9281726.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.bankCode.toLowerCase(), equals('momo'));
      expect(parsed.amount, equals(65000.0));
      expect(parsed.isExpense, isTrue);
      expect(parsed.suggestedCategoryId, equals('ca_phe'));
    });

    test(
        'Strict Zero-Leakage: Drops any notification containing OTP or passwords',
        () {
      final otp1 = BankNotificationParser.parse(
        rawId: 'otp_1',
        packageName: 'com.VCB',
        title: 'VCB Digibank',
        text:
            'Ma OTP xac thuc giao dich cua quy khach la 849201. Khong chia se cho bat ky ai.',
      );
      expect(otp1, isNull);

      final otp2 = BankNotificationParser.parse(
        rawId: 'otp_2',
        packageName: 'vn.com.techcombank.bb.app',
        title: 'Techcombank',
        text: 'Mã xác thực Smart OTP là 192834 để chuyển khoản 500,000 VND.',
      );
      expect(otp2, isNull);
    });
  });

  test(
      'Reading native queue retains pending items; explicit ack removes only its ID',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('com.finora/bank_sync');
    final calls = <String>[];
    final queue = [
      jsonEncode({
        'id': 'durable_vcb_1',
        'package': 'com.VCB',
        'title': 'VCB',
        'text': 'TK 001100 +500,000 VND. ND: Thu nhap.',
        'timestamp': 1793300000000
      })
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'getPendingNotifications':
          return List<String>.of(queue);
        case 'getSyncStatus':
          return {'connected': true, 'lastReceivedAt': 1793300000000};
        case 'acknowledgeNotifications':
          expect((call.arguments as Map)['ids'], ['durable_vcb_1']);
          queue.clear();
          return true;
        default:
          return false;
      }
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = BankSyncService();
    await service.initialize();
    await service.checkPendingNotifications();
    expect(queue, hasLength(1));
    expect(service.pending.where((tx) => tx.rawId == 'durable_vcb_1'),
        hasLength(1));
    expect(calls, isNot(contains('clearPendingNotifications')));
    await service.acknowledge('durable_vcb_1');
    expect(service.pending, isEmpty);
    expect(queue, isEmpty);
  });

  group('BankSyncSettingsSheet Widget Tests', () {
    testWidgets('Shows real inbox and has no simulator controls',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: BankSyncSettingsSheet(userId: 'test_user'))));
      await tester.pumpAndSettle();
      expect(find.text('Nhận diện ngân hàng'), findsOneWidget);
      expect(
          find.textContaining('Chưa có giao dịch chờ xử lý'), findsOneWidget);
      expect(find.textContaining('SIMULATOR'), findsNothing);
      expect(find.text('Thử ngay'), findsNothing);
      expect(find.text('ĐANG CHẠY THẬT'), findsNothing);
    });
  });
}
