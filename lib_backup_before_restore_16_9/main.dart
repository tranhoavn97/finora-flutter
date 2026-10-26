import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/error_boundary.dart';
import 'state/auth_provider.dart';
import 'state/family_provider.dart';
import 'state/budget_provider.dart';
import 'state/dashboard_provider.dart';
import 'state/more_provider.dart';
import 'state/theme_controller.dart';
import 'state/transaction_provider.dart';
import 'state/wallet_provider.dart';
import 'state/widget_style_controller.dart';
import 'state/theme_studio_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/main/main_screen.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';
import 'core/widgets/app_logo.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorBoundary.initializeGlobalHandlers();
  await initializeDateFormatting('vi', null);

  // Android Luxury Experience: Seamless edge-to-edge transparent system bars
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final theme = ThemeController();
    await theme.load();
    final widgetStyle = WidgetStyleController();
    await widgetStyle.load();
    final themeStudio = ThemeStudioController();
    await themeStudio.load();
    runApp(FinoraApp(
        themeController: theme,
        widgetStyleController: widgetStyle,
        themeStudioController: themeStudio));
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
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(error,
                    style: const TextStyle(
                        color: Color(0xFFFF8A9A), fontSize: 13)),
                const SizedBox(height: 16),
                SelectableText(stack,
                    style: const TextStyle(
                        color: Color(0xFFB6C8EA), fontSize: 11)),
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
  final WidgetStyleController widgetStyleController;
  final ThemeStudioController themeStudioController;
  const FinoraApp({
    super.key,
    required this.themeController,
    required this.widgetStyleController,
    required this.themeStudioController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: widgetStyleController),
        ChangeNotifierProvider.value(value: themeStudioController),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => MoreProvider()),
      ],
      child: Consumer2<ThemeController, ThemeStudioController>(
        builder: (context, theme, studio, _) {
          final palette = studio.currentPaletteMeta;
          final isAmoled = theme.isAmoled;
          return MaterialApp(
            title: 'Finora',
            debugShowCheckedModeBanner: false,
            theme: buildFinoraTheme(Brightness.light, palette: palette),
            darkTheme: buildFinoraTheme(Brightness.dark,
                palette: palette, isAmoled: isAmoled),
            themeMode: theme.themeMode,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              // Protect luxury layout against excessive system font scaling that causes overflows
              final clampedScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.25,
              );
              return AppErrorBoundary(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaler: clampedScaler),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const SplashScreen(),
          );
        },
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
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const FinoraLoadingScreen();
        }
        final user = snapshot.data;
        if (user == null) return const AuthScreen();
        return _FamilyInitGate(user: user);
      },
    );
  }
}

class _FamilyInitGate extends StatefulWidget {
  final User user;
  const _FamilyInitGate({required this.user});

  @override
  State<_FamilyInitGate> createState() => _FamilyInitGateState();
}

class _FamilyInitGateState extends State<_FamilyInitGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().init(widget.user);
    });
  }

  @override
  void didUpdateWidget(covariant _FamilyInitGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      context.read<FamilyProvider>().init(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyProv = context.watch<FamilyProvider>();
    if (familyProv.isLoading && familyProv.familyId == null) {
      return const FinoraLoadingScreen();
    }
    return MainScreen(user: widget.user);
  }
}

class FinoraLoadingScreen extends StatelessWidget {
  const FinoraLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FinoraBrandLogo(width: 192, height: 60),
          const SizedBox(height: 24),
          SizedBox(
              width: 100,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(minHeight: 3))),
        ])),
      );
}
