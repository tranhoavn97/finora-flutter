import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finora/core/widgets/adaptive_glass_surface.dart';
import 'package:finora/core/widgets/avatar_crop_sheet.dart';
import 'package:finora/core/widgets/bank_icon.dart';
import 'package:finora/core/widgets/finora_member_filter.dart';
import 'package:finora/core/widgets/finora_modal_scope.dart';
import 'package:finora/core/widgets/glass_widgets.dart';
import 'package:finora/core/widgets/premium_widgets.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/features/notification/notification_screen.dart';
import 'package:finora/features/profile/profile_screen.dart';
import 'package:finora/features/transaction/transaction_detail_sheet.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';

const String _kSamplePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

Uint8List _samplePngBytes() => base64Decode(_kSamplePngBase64);

class _TestTxProvider extends TransactionProvider {
  _TestTxProvider() {
    isRefreshing = false;
  }

  @override
  List<Wallet> get wallets => const [
        Wallet(
          id: 'w_ncb',
          name: 'NCB Izimobile',
          bankName: 'NCB',
          bankCode: 'NCB',
          balance: 2734539,
          type: 'bank',
          owner: 'husband',
        ),
      ];
}

class _TestMoreProvider extends MoreProvider {
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Scoped glassOpacity & modal opacity isolation', () {
    testWidgets(
      'Main screen cards & segmented controls follow glassOpacity while modals/bottom sheets remain 100% opaque',
      (tester) async {
        final studio = ThemeStudioController();
        await studio.setGlassOpacity(0.25);

        expect(studio.getCardFillColor(false).a, closeTo(0.25, 0.02));
        expect(
          studio.getCardFillColor(false, forceOpaque: true).a,
          closeTo(1.0, 0.001),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeStudioController>.value(
            value: studio,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (outerContext) => Column(
                    children: [
                      const AdaptiveGlassSurface(
                        key: ValueKey('main_card'),
                        color: Colors.white,
                        child: Text('Main Card'),
                      ),
                      FinoraSegmentedTabs(
                        key: const ValueKey('main_tabs'),
                        labels: const ['Tất cả', 'Chi tiêu'],
                        selectedIndex: 0,
                        onChanged: (_) {},
                      ),
                      FinoraMemberSegmentedFilter(
                        key: const ValueKey('member_tabs'),
                        selectedValue: 'all',
                        onChanged: (_) {},
                      ),
                      FinoraSeeAllButton(
                        key: const ValueKey('see_all_btn'),
                        onTap: () {},
                      ),
                      ElevatedButton(
                        key: const ValueKey('open_modal_btn'),
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: outerContext,
                            builder: (_) => FinoraModalScope(
                              child: GlassBottomSheet(
                                key: const ValueKey('modal_sheet'),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AdaptiveGlassSurface(
                                      key: ValueKey('modal_inner_card'),
                                      color: Colors.white,
                                      child: Text('Modal Card'),
                                    ),
                                    FinoraSegmentedTabs(
                                      key: const ValueKey('modal_tabs'),
                                      labels: const ['A', 'B'],
                                      selectedIndex: 0,
                                      onChanged: (_) {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('Mở modal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mainSurfaceContainer = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const ValueKey('main_card')),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.color != null || c.decoration is BoxDecoration);
        final mainColor = mainSurfaceContainer.color ??
            (mainSurfaceContainer.decoration as BoxDecoration).color!;
        expect(mainColor.a, closeTo(0.25, 0.02));

        final seeAllBox = tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('see_all_btn')),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration as BoxDecoration;
        expect(seeAllBox.color!.a, closeTo(0.25, 0.02));

        final memberContainer = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const ValueKey('member_tabs')),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.decoration is BoxDecoration);
        expect(
          (memberContainer.decoration as BoxDecoration).color!.a,
          closeTo(0.25, 0.02),
        );

        await tester.tap(find.byKey(const ValueKey('open_modal_btn')));
        await tester.pumpAndSettle();

        final modalSheetMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('modal_sheet')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(modalSheetMaterial.color!.a, closeTo(1.0, 0.001));

        final modalInnerContainer = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const ValueKey('modal_inner_card')),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.color != null || c.decoration is BoxDecoration);
        final modalInnerColor = modalInnerContainer.color ??
            (modalInnerContainer.decoration as BoxDecoration).color!;
        expect(modalInnerColor.a, closeTo(1.0, 0.001));

        final modalTabsContainer = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const ValueKey('modal_tabs')),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.decoration is BoxDecoration);
        expect(
          (modalTabsContainer.decoration as BoxDecoration).color!.a,
          closeTo(1.0, 0.001),
        );
      },
    );
  });

  group('Merged Notifications & Bank Sync + Full-Bleed Circular Icons', () {
    testWidgets(
      'ProfileScreen merges notifications & bank balance sync into one entry',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => _TestTxProvider(),
              ),
              ChangeNotifierProvider<ThemeStudioController>(
                create: (_) => ThemeStudioController(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ProfileScreen(
                  userId: 'u_test',
                  userEmail: 'test@finora.app',
                  userName: 'Hòa Trần',
                  isRoot: true,
                  onSignOut: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thông báo & Biến động số dư'), findsOneWidget);
        expect(
          find.text('Hoạt động, cảnh báo & đọc ngân hàng (BETA)'),
          findsOneWidget,
        );
        expect(find.text('Đọc biến động ngân hàng (BETA)'), findsNothing);
      },
    );

    testWidgets(
      'NotificationScreen renders unified header and read-balance CTA',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => _TestTxProvider(),
              ),
              ChangeNotifierProvider<ThemeStudioController>(
                create: (_) => ThemeStudioController(),
              ),
              ChangeNotifierProvider<MoreProvider>(
                create: (_) => _TestMoreProvider(),
              ),
            ],
            child: const MaterialApp(
              home: NotificationScreen(userId: 'u_test'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Thông báo & Số dư'), findsOneWidget);
        expect(find.text('Đọc số dư'), findsOneWidget);
      },
    );

    testWidgets(
      'BankIcon & BankIconAvatar render edge-to-edge full-bleed ClipOval when fullBleed is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BankIcon(
                    key: ValueKey('full_bleed_bank_icon'),
                    bankCode: 'NCB',
                    bankName: 'NCB',
                    size: 44,
                    fullBleed: true,
                  ),
                  BankIconAvatar(
                    key: ValueKey('full_bleed_avatar'),
                    bankCode: 'VCB',
                    size: 44,
                    fullBleed: true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final iconClip = find.descendant(
          of: find.byKey(const ValueKey('full_bleed_bank_icon')),
          matching: find.byType(ClipOval),
        );
        expect(iconClip, findsOneWidget);

        final avatarImg = tester.widget<Image>(
          find.descendant(
            of: find.byKey(const ValueKey('full_bleed_avatar')),
            matching: find.byType(Image),
          ),
        );
        expect(avatarImg.fit, BoxFit.cover);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('full_bleed_avatar')),
            matching: find.byType(Container),
          ),
          findsNothing,
        );
      },
    );
  });

  group('Redesigned Transaction Detail Sheet & Couple Avatars', () {
    testWidgets(
      'showTransactionDetailSheet renders redesigned opaque bento layout with member & NCB wallet',
      (tester) async {
        final studio = ThemeStudioController();
        await studio.setGlassOpacity(0.25);
        await studio.setHusbandAvatar('data:image/png;base64,$_kSamplePngBase64');

        final tx = TransactionModel(
          id: 'tx_ncb_1',
          userId: 'u_test',
          amount: 1000000,
          type: 'income',
          date: DateTime(2026, 11, 15, 0, 4).millisecondsSinceEpoch,
          note: 'TRAN MANH HOA chuyen tien',
          categoryId: 'thu_nhap',
          categoryName: 'Thu nhập',
          walletId: 'w_ncb',
          walletName: 'NCB Izimobile',
          owner: 'husband',
          bankTransactionCode: 'NCB998877',
          createdAt: 1,
          updatedAt: 1,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeStudioController>.value(
                value: studio,
              ),
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => _TestTxProvider(),
              ),
              ChangeNotifierProvider<WalletProvider>(
                create: (_) => WalletProvider(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const ValueKey('open_detail'),
                    onPressed: () => showTransactionDetailSheet(
                      context,
                      userId: 'u_test',
                      transaction: tx,
                    ),
                    child: const Text('Xem'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('open_detail')));
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết giao dịch'), findsOneWidget);
        expect(find.text('TIỀN VÀO · THU NHẬP'), findsOneWidget);
        expect(find.text('Thành viên'), findsOneWidget);
        expect(find.text('#NCB998877'), findsOneWidget);
        expect(find.text('Chỉnh sửa'), findsOneWidget);
        expect(find.text('Xóa'), findsOneWidget);

        expect(
          find.descendant(
            of: find.byType(FinoraMemberAvatar),
            matching: find.byType(Image),
          ),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'showFinoraAvatarCropSheet displays crop viewport and outputs PNG data URI on confirm',
      (tester) async {
        final sampleBytes = _samplePngBytes();
        String? croppedDataUri;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  key: const ValueKey('open_crop'),
                  onPressed: () async {
                    croppedDataUri = await showFinoraAvatarCropSheet(
                      context: context,
                      imageBytes: sampleBytes,
                      roleLabel: 'Chồng',
                      accentColor: const Color(0xFF0284C7),
                    );
                  },
                  child: const Text('Cắt ảnh'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('open_crop')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Let dart:ui image decoding complete on native engine thread
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Cắt & chỉnh sửa ảnh (Chồng)'), findsOneWidget);
        expect(find.text('Xoay 90°'), findsOneWidget);
        expect(find.text('Lật ngang'), findsOneWidget);
        expect(find.text('Lưu ảnh đã cắt'), findsOneWidget);

        await tester.tap(find.text('Lưu ảnh đã cắt'));
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(croppedDataUri, isNotNull);
        expect(croppedDataUri, startsWith('data:image/png;base64,'));
        expect(tryDecodeAvatarDataUri(croppedDataUri), isNotNull);
      },
    );
  });
}
