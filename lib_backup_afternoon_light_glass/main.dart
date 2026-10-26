import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/budget_provider.dart';
import 'state/dashboard_provider.dart';
import 'state/more_provider.dart';
import 'state/theme_controller.dart';
import 'state/transaction_provider.dart';
import 'state/wallet_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/main/main_screen.dart';
import 'features/splash/splash_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final theme = ThemeController();
    await theme.load();
    runApp(FinoraApp(themeController: theme));
  } catch (e, st) {
    runApp(_StartupErrorApp(error: '$e', stack: '$st'));
  }
}

/// Shown if startup (e.g. Firebase init) fails — so the app never closes silently.
class _StartupErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const _StartupErrorApp({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1838),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lỗi khởi động Finora',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(error, style: const TextStyle(color: Color(0xFFFF8A9A), fontSize: 13)),
                const SizedBox(height: 16),
                SelectableText(stack, style: const TextStyle(color: Color(0xFFB6C8EA), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FinoraApp extends StatelessWidget {
  final ThemeController themeController;
  const FinoraApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => MoreProvider()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Finora',
          debugShowCheckedModeBanner: false,
          theme: buildFinoraTheme(Brightness.light),
          darkTheme: buildFinoraTheme(Brightness.dark),
          themeMode: theme.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Routes between the auth screen and the main app based on Firebase auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const AuthScreen();
        return MainScreen(user: user);
      },
    );
  }
}
