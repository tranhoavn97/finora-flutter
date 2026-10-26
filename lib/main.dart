import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/app_typography.dart';
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
import 'core/widgets/finora_loading_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable 120Hz ProMotion high-frequency touch resampling for ultra-smooth scrolling
  GestureBinding.instance.resamplingEnabled = true;
  AppErrorBoundary.initializeGlobalHandlers();

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
          AppTypography.activeFontFamily = studio.fontFamilyName;
          AppTypography.activeFontFamilyFallback = studio.fontFamilyFallback;

          return MaterialApp(
            title: 'Finora',
            debugShowCheckedModeBanner: false,
            theme: buildFinoraTheme(
              Brightness.light,
              palette: palette,
              buttonRadius: studio.getButtonRadius(),
              buttonHeight: studio.getButtonHeight(),
              buttonPadding: studio.getButtonPadding(),
              cardRadius: studio.cardCornerRadius,
              cardBorder: studio.getCardBorder(false),
              cardFillColor: studio.getCardFillColor(false),
              modalFillColor: studio.getModalFillColor(false),
              fontFamily: studio.fontFamilyName,
              fontFamilyFallback: studio.fontFamilyFallback,
            ),
            darkTheme: buildFinoraTheme(
              Brightness.dark,
              palette: palette,
              isAmoled: isAmoled,
              buttonRadius: studio.getButtonRadius(),
              buttonHeight: studio.getButtonHeight(),
              buttonPadding: studio.getButtonPadding(),
              cardRadius: studio.cardCornerRadius,
              cardBorder: studio.getCardBorder(true),
              cardFillColor: studio.getCardFillColor(true),
              modalFillColor: studio.getModalFillColor(true),
              fontFamily: studio.fontFamilyName,
              fontFamilyFallback: studio.fontFamilyFallback,
            ),
            themeMode: theme.themeMode,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
            ),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final isWide = mediaQuery.size.width > 520;
              // Combine system text scaler with user-configured font scale from ThemeStudioController
              final baseScale = mediaQuery.textScaler.scale(1.0);
              final effectiveScaler = TextScaler.linear(
                  (baseScale * studio.fontScale).clamp(0.85, 1.35));

              if (!isWide) {
                return AppErrorBoundary(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(textScaler: effectiveScaler),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              }

              // Web / Desktop: Centered luxury mobile device frame (max-width 460px)
              final isDark = Theme.of(context).brightness == Brightness.dark;
              const phoneWidth = 460.0;
              final phoneHeight = mediaQuery.size.height.clamp(680.0, 960.0);

              return AppErrorBoundary(
                child: Container(
                  color: isDark ? const Color(0xFF070B12) : const Color(0xFFE2E8F0),
                  child: Center(
                    child: Container(
                      width: phoneWidth,
                      height: phoneHeight,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          size: Size(phoneWidth, phoneHeight),
                          textScaler: effectiveScaler,
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
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
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinoraBrandLogo(width: 192, height: 60),
              SizedBox(height: 28),
              FinoraPulseLoading(
                size: 56,
                message: 'Đang tải dữ liệu tài chính FINORA...',
              ),
            ],
          ),
        ),
      );
}
