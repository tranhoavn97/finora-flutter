import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/core/utils/date_filter.dart';
import 'package:finora/core/widgets/bank_icon.dart';
import 'package:finora/core/widgets/subject_filter_pill.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/domain/finance/transaction_member.dart';
import 'package:finora/features/wallet/wallet_controls.dart';
import 'package:finora/features/wallet/wallet_screen.dart';
import 'package:finora/features/wallet/web_wallet_card.dart';
import 'package:finora/features/wallet/wealth_hub_screen.dart';
import 'package:finora/state/more_provider.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/wallet_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';

class _SampleWalletProvider extends WalletProvider {
  _SampleWalletProvider() {
    hasLoadedBalances = true;
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _SampleTransactionProvider extends TransactionProvider {
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

class _SampleMoreProvider extends MoreProvider {
  _SampleMoreProvider() {
    isRefreshing = false;
  }
  @override
  void load(String userId, {String? familyId, bool force = false}) {}
}

const _previewEnabled = bool.fromEnvironment('FINORA_UI_PREVIEW');

Future<void> _capturePreview(
    WidgetTester tester, String key, String name) async {
  if (!_previewEnabled) return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(ValueKey(key)));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../docs/ui-checks/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (_previewEnabled) {
      final font = FontLoader('FinoraPreview');
      font.addFont(File('C:/Windows/Fonts/segoeui.ttf')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)));
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(File(
              'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)));
      await icons.load();
    }
  });

  test('search ignores accents, case and combining marks across useful fields',
      () {
    final provider = TransactionProvider();
    addTearDown(provider.dispose);
    provider.selectedDateFilter = DateFilterOption.allTime;
    provider.transactions.addAll(const [
      TransactionModel(id: 'food', note: 'Ăn uống', amount: 85000),
      TransactionModel(id: 'category', categoryName: 'Điện nước'),
      TransactionModel(id: 'merchant', merchantName: 'Cửa hàng Đỏ'),
      TransactionModel(id: 'wallet', walletName: 'Tiết kiệm Vợ'),
    ]);
    for (final pair in [
      (' AN UONG ', 'food'),
      ('a\u0306n uo\u0302\u0301ng', 'food'),
      ('DIEN NUOC', 'category'),
      ('cua hang do', 'merchant'),
      ('tiet kiem vo', 'wallet'),
      ('85000', 'food'),
    ]) {
      provider.searchQuery = pair.$1;
      expect(provider.filteredTransactions.map((t) => t.id), [pair.$2]);
    }
    provider.searchQuery = 'không tồn tại';
    expect(provider.filteredTransactions, isEmpty);
  });

  test('unclassified and shared transactions never default to husband', () {
    final provider = TransactionProvider();
    addTearDown(provider.dispose);
    provider.selectedDateFilter = DateFilterOption.allTime;
    provider.transactions.addAll(const [
      TransactionModel(id: 'unknown'),
      TransactionModel(id: 'ai', creatorTag: 'AI'),
      TransactionModel(id: 'husband', owner: ' HUSBAND '),
      TransactionModel(id: 'wife', tags: ['VỢ']),
      TransactionModel(id: 'shared', owner: 'family'),
      TransactionModel(id: 'conflict', tags: ['Chồng', 'Vợ']),
    ]);
    for (final pair in [
      ('husband', {'husband'}),
      ('wife', {'wife'}),
      ('joint', {'shared'}),
      ('unknown', {'unknown', 'ai', 'conflict'}),
    ]) {
      provider.selectedMemberTag = pair.$1;
      expect(provider.filteredTransactions.map((t) => t.id).toSet(), pair.$2);
    }
    provider.selectedMemberTag = null;
    expect(provider.filteredTransactions, hasLength(6));
    expect(OwnerFilter.husband.matchTransaction(const TransactionModel()),
        isFalse);
    expect(
        OwnerFilter.joint
            .matchTransaction(const TransactionModel(owner: 'shared')),
        isTrue);
  });

  test('explicit attribution wins; destination and AI are not the spender', () {
    const wallets = {'w': Wallet(id: 'w', owner: 'wife', ownerName: 'Vợ')};
    expect(
        resolveTransactionMember(const TransactionModel(walletId: 'w'),
            walletMap: wallets),
        TransactionMember.wife);
    expect(
        resolveTransactionMember(
            const TransactionModel(creatorTag: 'Chồng', walletId: 'w'),
            walletMap: wallets),
        TransactionMember.husband);
    expect(
        resolveTransactionMember(
            const TransactionModel(fromOwner: 'Chồng', toOwner: 'Vợ')),
        TransactionMember.husband);
    expect(
        resolveTransactionMember(
            const TransactionModel(creatorTag: 'AI', owner: 'wife')),
        TransactionMember.wife);
    expect(resolveTransactionMember(const TransactionModel(toOwner: 'wife')),
        TransactionMember.unknown);
    expect(
        resolveTransactionMember(
            const TransactionModel(owner: 'wife', ownerName: 'Chồng')),
        TransactionMember.unknown);
  });

  test('legacy wallet display defaults are not member attribution', () {
    for (final pair in [
      (<String, dynamic>{}, TransactionMember.unknown),
      (<String, dynamic>{'owner': 'wife'}, TransactionMember.wife),
      (<String, dynamic>{'ownerName': 'Vợ'}, TransactionMember.wife),
    ]) {
      final wallet = Wallet.fromMap('legacy', pair.$1).copyWith(balance: 100);
      expect(
          resolveTransactionMember(const TransactionModel(walletId: 'legacy'),
              walletMap: {'legacy': wallet}),
          pair.$2);
    }
  });

  testWidgets('missing member renders unclassified; AI origin stays separate',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      SpenderBadgeWidget(isDark: false),
      SpenderBadgeWidget(
          isDark: true, tag: 'AI', member: TransactionMember.unknown),
    ]))));
    expect(find.text('Chưa phân loại'), findsNWidgets(2));
    expect(find.text('Chồng'), findsNothing);
  });

  for (final width in [240.0, 288.0, 390.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'many-card controls fit width $width dark=$dark at large text',
          (tester) async {
        var selected = 0;
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Scaffold(
                    body: SizedBox(
                        width: width,
                        child: WalletDeckIndicator(
                            count: 1000,
                            current: 499,
                            onSelect: (i) => selected = i))))));
        expect(tester.takeException(), isNull);
        final dots = find.byWidgetPredicate((w) =>
            w is InkWell && w.key.toString().contains('wallet-deck-page-'));
        expect(dots.evaluate().length, lessThanOrEqualTo(5));
        expect(dots.evaluate().length, greaterThan(0));
        for (final element in dots.evaluate()) {
          expect(tester.getSize(find.byWidget(element.widget)),
              const Size(44, 44));
        }
        await tester.tap(find.byTooltip('Ví tiếp theo'));
        expect(selected, 500);
        await tester.tap(find.byTooltip('Ví trước'));
        expect(selected, 498);
        await tester.tap(find.byKey(const ValueKey('wallet-deck-page-499')));
        expect(selected, 499);
      });
    }
  }

  testWidgets('indicator reaches ends and wraps without losing the active dot',
      (tester) async {
    for (final current in [0, 49]) {
      var selected = -1;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 288,
                  child: WalletDeckIndicator(
                      count: 50,
                      current: current,
                      onSelect: (i) => selected = i)))));
      expect(find.byKey(ValueKey('wallet-deck-page-$current')), findsOneWidget);
      await tester
          .tap(find.byTooltip(current == 0 ? 'Ví trước' : 'Ví tiếp theo'));
      expect(selected, current == 0 ? 49 : 0);
      expect(tester.takeException(), isNull);
    }
  });

  for (final width in [288.0, 390.0]) {
    testWidgets(
        'credit card retains all details and payment at width $width with large text',
        (tester) async {
      var payments = 0;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                  body: SizedBox(
                      width: width,
                      child: WebWalletCard(
                          wallet: const Wallet(
                              id: 'credit',
                              name: 'Thẻ tín dụng Vợ',
                              owner: 'wife',
                              ownerName: 'Vợ',
                              type: 'credit_card',
                              currentDebt: 2529292,
                              creditLimit: 20000000),
                          onHistory: () {},
                          onEdit: () {},
                          onDelete: () {},
                          onPay: () => payments++))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Dư nợ hiện tại'), findsOneWidget);
      expect(find.text('Còn khả dụng'), findsOneWidget);
      expect(payments, 0);
      await tester.tap(find.text('Trả nợ thẻ'));
      expect(payments, 1);
    });
  }

  for (final width in [288.0, 328.0, 390.0, 600.0]) {
    testWidgets(
        'real wallet toolbar fits width $width with large text and filter',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = _SampleWalletProvider();
      provider.isRefreshing = false;
      provider.wallets = const [
        Wallet(
            id: 'wife',
            name: 'Tiết kiệm Vợ',
            type: 'cash',
            owner: 'wife',
            ownerName: 'Vợ',
            balance: 12000000)
      ];
      final studio = ThemeStudioController();
      await studio.load();
      await studio.setWalletViewStyle(AppWalletViewStyle.compactList);
      final originalErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalErrorHandler?.call(details);
      };
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<WalletProvider>.value(value: provider),
            ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
          ],
          child: MaterialApp(
              theme: ThemeData(
                  fontFamily: _previewEnabled ? 'FinoraPreview' : null),
              home: MediaQuery(
                  data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: const TextScaler.linear(1.5)),
                  child: SizedBox(
                      width: width,
                      child: const RepaintBoundary(
                          key: ValueKey('wallet-preview'),
                          child: WalletScreen(
                              userId: 'sample', isRoot: true)))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Thành viên: Tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vợ (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Đang lọc: Vợ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 390) {
        await _capturePreview(
            tester, 'wallet-preview', 'finora-usability-wallet-20261011');
      }
      await tester.tap(find.byTooltip('Xem tất cả thành viên'));
      await tester.pumpAndSettle();
      expect(find.text('Đang lọc: Vợ'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      studio.dispose();
    });
  }

  for (final width in [288.0, 390.0]) {
    testWidgets('unclassified transaction and member filter fit width $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = _SampleTransactionProvider();
      final walletProvider = _SampleWalletProvider();
      final moreProvider = _SampleMoreProvider();
      provider.isRefreshing = false;
      provider.transactions.add(TransactionModel(
          id: 'unknown',
          note: 'Ăn uống',
          categoryName: 'Ăn uống',
          amount: 85000,
          date: DateTime.now().millisecondsSinceEpoch));
      final studio = ThemeStudioController();
      await studio.load();
      final originalErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalErrorHandler?.call(details);
      };
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(value: provider),
            ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
            ChangeNotifierProvider<MoreProvider>.value(value: moreProvider),
            ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
          ],
          child: MaterialApp(
              theme: ThemeData(
                  fontFamily: _previewEnabled ? 'FinoraPreview' : null),
              home: MediaQuery(
                  data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: const TextScaler.linear(1.5)),
                  child: const RepaintBoundary(
                      key: ValueKey('transaction-preview'),
                      child: WealthHubScreen(userId: 'sample'))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ăn uống'), findsWidgets);
      if (width == 390) {
        await _capturePreview(tester, 'transaction-preview',
            'finora-usability-transactions-20261011');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      walletProvider.dispose();
      moreProvider.dispose();
      studio.dispose();
    });
  }

  testWidgets('deck navigates and resets safely when cards are filtered',
      (tester) async {
    Widget sample(List<Wallet> cards) => MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 288,
                child: WalletCardDeck(
                    cards: cards,
                    builder: (_, w) => Container(
                        color: Colors.blue,
                        child: Center(child: Text(w.name)))))));
    final cards = List.generate(50, (i) => Wallet(id: '$i', name: 'Ví $i'));
    await tester.pumpWidget(sample(cards));
    await tester.tap(find.byTooltip('Ví tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 50'), findsOneWidget);
    await tester.pumpWidget(sample([cards.last, cards[1]]));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(sample([cards.last]));
    await tester.pumpAndSettle();
    expect(find.byType(WalletDeckIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real stacked wallet cards keep a bounded indicator and navigate',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _SampleWalletProvider();
    provider.isRefreshing = false;
    provider.wallets = List.generate(
        12,
        (i) => Wallet(
            id: '$i',
            name: i == 0 ? 'Techcombank Chồng' : 'Tiết kiệm ${i + 1}',
            type: 'bank',
            bankCode: i == 0 ? 'tcb' : 'mbbank',
            balance: 12000000 + i * 100000,
            accountNumber: '1565'));
    final studio = ThemeStudioController();
    await studio.load();
    await studio.setWalletViewStyle(AppWalletViewStyle.stackedDeck);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeStudioController>.value(value: studio),
        ],
        child: MaterialApp(
            theme:
                ThemeData(fontFamily: _previewEnabled ? 'FinoraPreview' : null),
            home: const RepaintBoundary(
                key: ValueKey('deck-preview'),
                child: WalletScreen(userId: 'sample', isRoot: true)))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 / 12'), findsOneWidget);
    await tester.tap(find.byTooltip('Ví tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capturePreview(
        tester, 'deck-preview', 'finora-usability-deck-20261011');
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    studio.dispose();
  });
}
