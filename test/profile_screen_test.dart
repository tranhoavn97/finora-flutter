import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/features/profile/profile_screen.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/state/transaction_provider.dart';
import 'package:finora/state/theme_studio_controller.dart';

class _TestTransactionProvider extends TransactionProvider {
  _TestTransactionProvider() {
    isRefreshing = false;
  }
  @override
  List<Wallet> get wallets => [
        const Wallet(id: 'w1', name: 'Ví tiền mặt', balance: 5000000, type: 'cash'),
        const Wallet(id: 'w2', name: 'Tài khoản Techcombank', balance: 15000000, type: 'bank'),
      ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildProfileHarness({
    double width = 390,
    double height = 1200,
    double textScale = 1.0,
    VoidCallback? onSignOut,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionProvider>(create: (_) => _TestTransactionProvider()),
        ChangeNotifierProvider<ThemeStudioController>(create: (_) => ThemeStudioController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: ProfileScreen(
              userId: 'test_user',
              userEmail: 'tranhoavn97@gmail.com',
              userName: 'Hòa Trần',
              isRoot: true,
              onSignOut: onSignOut ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ProfileScreen renders essential persona & settings, without redundant tabs or fake stats', (tester) async {
    await tester.pumpWidget(buildProfileHarness());
    await tester.pumpAndSettle();

    // 1. Verify User Persona
    expect(find.text('Hòa Trần'), findsOneWidget);
    expect(find.text('tranhoavn97@gmail.com'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('2 ví tài chính đang quản lý'), findsOneWidget);

    // 2. Verify AI Advisor banner
    expect(find.text('Trợ lý tài chính AI'), findsOneWidget);

    // 3. Verify Real Settings & Utilities
    expect(find.text('Danh mục thu chi'), findsOneWidget);
    expect(find.text('Thông báo & Nhắc nhở'), findsOneWidget);
    expect(find.text('Chế độ hiển thị & Giao diện'), findsOneWidget);
    expect(find.text('Nhật ký kiểm toán hoạt động'), findsOneWidget);
    expect(find.text('Thùng rác phục hồi 30 ngày'), findsOneWidget);

    // Scroll to see logout button
    await tester.scrollUntilVisible(find.text('Đăng xuất tài khoản'), 200);
    expect(find.text('Đăng xuất tài khoản'), findsOneWidget);

    // 4. Verify Redundant Dock items are NOT present
    expect(find.text('Tài sản & Đầu tư'), findsNothing);
    expect(find.text('Ngân sách chi tiêu'), findsNothing);
    expect(find.text('Mục tiêu tài chính'), findsNothing);
    expect(find.text('Khoản vay & Sổ nợ'), findsNothing);
    expect(find.text('Báo cáo & Phân tích'), findsNothing);

    // 5. Verify Fake stats are NOT present
    expect(find.text('91/100'), findsNothing);
    expect(find.text('Sức khoẻ AI'), findsNothing);
    expect(find.text('DIAMOND'), findsNothing);
  });

  testWidgets('ProfileScreen logout button triggers confirmation dialog', (tester) async {
    bool signedOut = false;
    await tester.pumpWidget(buildProfileHarness(onSignOut: () => signedOut = true));
    await tester.pumpAndSettle();

    final logoutButton = find.text('Đăng xuất tài khoản');
    await tester.scrollUntilVisible(logoutButton, 200);
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này trên thiết bị không?'), findsOneWidget);

    // Tap confirm 'Đăng xuất' button in dialog
    final confirmBtn = find.widgetWithText(ElevatedButton, 'Đăng xuất');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('ProfileScreen layout check at 320px width with textScaler 1.5', (tester) async {
    await tester.pumpWidget(buildProfileHarness(
      width: 320,
      height: 700,
      textScale: 1.5,
    ));
    await tester.pumpAndSettle();

    // Verify no overflow
    expect(tester.takeException(), isNull);
  });
}
