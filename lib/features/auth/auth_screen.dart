import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_typography.dart';
import '../../core/theme/finora_tokens.dart';
import '../../core/widgets/finora_notice.dart';
import '../../state/auth_provider.dart';
import '../../state/theme_studio_controller.dart';

enum AuthMode { login, signup, forgotPassword }

/// FINORA Luxury Bento & Crystal Quartz Authentication Screen (2026 Edition).
/// Redesigned Login, Registration, and Password Recovery experience with
/// dynamic palette sync, tactile segmented mode switcher, icon-pod inputs,
/// password strength meter, and official Google SSO.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _fullNameFocus = FocusNode();

  StreamSubscription? _sub;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    final auth = context.read<AuthProvider>();
    _sub = auth.events.listen((msg) {
      if (mounted) {
        _showToast(msg);
      }
    });

    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
    _fullNameFocus.addListener(() => setState(() {}));
    _passwordController.addListener(() {
      if (_mode == AuthMode.signup && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fullNameFocus.dispose();
    super.dispose();
  }

  String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';

  void _showToast(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    FinoraNotice.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFF10B981),
                  size: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: _font,
                    color: FinoraTokens.ink(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: FinoraTokens.line(isDark), width: 1.0),
          ),
          backgroundColor: FinoraTokens.surface(isDark),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) return;
    HapticFeedback.selectionClick();
    _animController.reset();
    setState(() {
      _mode = mode;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    _animController.forward();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty) {
      _showToast('Vui lòng nhập địa chỉ Email');
      _emailFocus.requestFocus();
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showToast('Định dạng email chưa hợp lệ');
      _emailFocus.requestFocus();
      return;
    }

    if (_mode == AuthMode.forgotPassword) {
      auth.sendPasswordResetEmail(email);
      return;
    }

    if (pass.isEmpty) {
      _showToast('Vui lòng nhập mật khẩu');
      _passwordFocus.requestFocus();
      return;
    }
    if (pass.length < 6) {
      _showToast('Mật khẩu tối thiểu từ 6 ký tự');
      _passwordFocus.requestFocus();
      return;
    }

    if (_mode == AuthMode.signup) {
      final name = _fullNameController.text.trim();
      if (name.isEmpty) {
        _showToast('Vui lòng nhập họ và tên');
        _fullNameFocus.requestFocus();
        return;
      }
      final confirm = _confirmPasswordController.text;
      if (confirm != pass) {
        _showToast('Mật khẩu xác nhận không khớp');
        _confirmPasswordFocus.requestFocus();
        return;
      }
      auth.signUpWithEmail(email, pass, name);
    } else {
      auth.signInWithEmail(email, pass);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final studio = Provider.of<ThemeStudioController?>(context);
    final primary = studio?.primaryColor ?? const Color(0xFF00866A);
    final secondary = studio?.secondaryColor ?? const Color(0xFF10B981);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF070D0C) : const Color(0xFFF4F8F6),
      body: Stack(
        children: [
          // 1. Crystal Quartz Multi-Orb Ambient Background
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -110,
                    left: -60,
                    width: 320,
                    height: 320,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: isDark ? 0.34 : 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: -90,
                    width: 290,
                    height: 290,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondary.withValues(alpha: isDark ? 0.24 : 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: 20,
                    right: 20,
                    height: 260,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF0284C7)
                                .withValues(alpha: isDark ? 0.18 : 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Scrollable Bento Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Bento Brand Card
                      _buildHeroBrandBanner(isDark, primary, secondary),
                      const SizedBox(height: 16),

                      // Main Glassmorphic Auth Card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFormCard(
                          isDark: isDark,
                          auth: auth,
                          primary: primary,
                          secondary: secondary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Feature Highlight Pills
                      _buildFeatureHighlights(isDark, primary),

                      const SizedBox(height: 14),

                      // Security Footer
                      _buildSecurityFooter(isDark, primary),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (auth.isLoading) _buildLoadingOverlay(isDark, primary),
        ],
      ),
    );
  }

  /// 1. Luxury Bento Hero Brand Banner
  Widget _buildHeroBrandBanner(bool isDark, Color primary, Color secondary) {
    String title;
    String subtitle;
    String badgeText;

    switch (_mode) {
      case AuthMode.login:
        badgeText = 'CHÀO MỪNG TRỞ LẠI';
        title = 'Đăng nhập Finora';
        subtitle =
            'Đồng bộ sổ thu chi gia đình, ngân hàng & kế hoạch tài chính thông minh';
        break;
      case AuthMode.signup:
        badgeText = 'KHỞI ĐẦU THỊNH VƯỢNG';
        title = 'Tạo tài khoản mới';
        subtitle =
            'Thiết lập không gian quản lý tài sản cá nhân & gia đình chỉ trong 30 giây';
        break;
      case AuthMode.forgotPassword:
        badgeText = 'BẢO MẬT TÀI KHOẢN';
        title = 'Khôi phục mật khẩu';
        subtitle =
            'Nhập địa chỉ email đã đăng ký để nhận liên kết đặt lại mật khẩu an toàn';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                      primary.withValues(alpha: 0.24), const Color(0xFF0E1A18)),
                  Color.alphaBlend(secondary.withValues(alpha: 0.14),
                      const Color(0xFF111E24)),
                ]
              : [
                  Colors.white.withValues(alpha: 0.94),
                  Color.alphaBlend(
                      primary.withValues(alpha: 0.07), Colors.white),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : primary.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Mascot App Icon with subtle quartz ring
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.45 : 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.5),
                  child: Image.asset(
                    'assets/mascot/app-icon.png',
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              primary.withValues(alpha: isDark ? 0.40 : 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 11,
                            color: isDark ? const Color(0xFF34D399) : primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              badgeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color:
                                    isDark ? const Color(0xFF34D399) : primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.18,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12.8,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Unified Glassmorphic Form Card
  Widget _buildFormCard({
    required bool isDark,
    required AuthProvider auth,
    required Color primary,
    required Color secondary,
  }) {
    final passwordStrength = _computePasswordStrength(_passwordController.text);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111C1A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE2ECE8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Segmented Pill Mode Switcher (Đăng nhập | Đăng ký)
              if (_mode != AuthMode.forgotPassword) ...[
                _buildSeamlessModeTabs(isDark, primary),
                const SizedBox(height: 20),
              ],

              // 2. Full Name (Signup only)
              if (_mode == AuthMode.signup) ...[
                _buildFieldLabel('HỌ VÀ TÊN HIỂN THỊ', isDark),
                const SizedBox(height: 7),
                _buildFieldInput(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  hint: 'Ví dụ: Nguyễn Minh Quân',
                  prefixIcon: LucideIcons.user,
                  isDark: isDark,
                  primary: primary,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
              ],

              // 3. Email Address
              _buildFieldLabel('ĐỊA CHỈ EMAIL', isDark),
              const SizedBox(height: 7),
              _buildFieldInput(
                controller: _emailController,
                focusNode: _emailFocus,
                hint: 'name@example.com',
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
                primary: primary,
              ),

              // 4. Password
              if (_mode != AuthMode.forgotPassword) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('MẬT KHẨU BẢO MẬT', isDark),
                    if (_mode == AuthMode.login)
                      GestureDetector(
                        onTap: () => _switchMode(AuthMode.forgotPassword),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                primary.withValues(alpha: isDark ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF34D399) : primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                _buildFieldInput(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hint: 'Nhập tối thiểu 6 ký tự',
                  prefixIcon: LucideIcons.lock,
                  isDark: isDark,
                  primary: primary,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                      color: isDark
                          ? const Color(0xFF8FA89F)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],

              // Password strength bar for Sign Up
              if (_mode == AuthMode.signup &&
                  _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPasswordStrengthBar(isDark, passwordStrength),
              ],

              // 5. Confirm Password (Signup only)
              if (_mode == AuthMode.signup) ...[
                const SizedBox(height: 14),
                _buildFieldLabel('NHẬP LẠI MẬT KHẨU', isDark),
                const SizedBox(height: 7),
                _buildFieldInput(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  hint: 'Nhập lại mật khẩu khớp ở trên',
                  prefixIcon: LucideIcons.shield_check,
                  isDark: isDark,
                  primary: primary,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? LucideIcons.eye_off
                          : LucideIcons.eye,
                      color: isDark
                          ? const Color(0xFF8FA89F)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ],

              // Remember session row on Login
              if (_mode == AuthMode.login) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? primary
                              : (isDark
                                  ? const Color(0xFF1A2825)
                                  : const Color(0xFFF1F5F3)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe
                                ? primary
                                : (isDark
                                    ? const Color(0xFF2D423C)
                                    : const Color(0xFFCBD5E1)),
                            width: 1.2,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Duy trì đăng nhập & đồng bộ tức thời trên thiết bị này',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 6. Primary Action Button
              _buildPrimaryActionButton(isDark, auth, primary, secondary),

              // 7. Google Sign-In & Divider
              if (_mode != AuthMode.forgotPassword) ...[
                const SizedBox(height: 18),
                _buildGoogleSection(isDark, auth, primary),
              ],

              // 8. Back to Login for Forgot Password Mode
              if (_mode == AuthMode.forgotPassword) ...[
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _switchMode(AuthMode.login),
                    icon: const Icon(LucideIcons.arrow_left, size: 16),
                    label: Text(
                      'Quay lại màn hình Đăng nhập',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? const Color(0xFF34D399) : primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented Mode Switcher (Đăng nhập | Đăng ký)
  Widget _buildSeamlessModeTabs(bool isDark, Color primary) {
    final isLogin = _mode == AuthMode.login;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172622) : const Color(0xFFEEF4F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF253A34) : const Color(0xFFDCE7E2),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.login),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isLogin
                      ? LinearGradient(
                          colors: isDark
                              ? [
                                  primary.withValues(alpha: 0.35),
                                  const Color(0xFF213832),
                                ]
                              : [Colors.white, Colors.white],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isLogin
                      ? Border.all(
                          color:
                              primary.withValues(alpha: isDark ? 0.50 : 0.20),
                          width: 1,
                        )
                      : null,
                  boxShadow: isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.28 : 0.06,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.log_in,
                      size: 15,
                      color: isLogin
                          ? (isDark ? const Color(0xFF34D399) : primary)
                          : (isDark
                              ? const Color(0xFF8FA89F)
                              : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13.5,
                        fontWeight: isLogin ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.15,
                        color: isLogin
                            ? (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))
                            : (isDark
                                ? const Color(0xFF8FA89F)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.signup),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: !isLogin
                      ? LinearGradient(
                          colors: isDark
                              ? [
                                  primary.withValues(alpha: 0.35),
                                  const Color(0xFF213832),
                                ]
                              : [Colors.white, Colors.white],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: !isLogin
                      ? Border.all(
                          color:
                              primary.withValues(alpha: isDark ? 0.50 : 0.20),
                          width: 1,
                        )
                      : null,
                  boxShadow: !isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.28 : 0.06,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.user_plus,
                      size: 15,
                      color: !isLogin
                          ? (isDark ? const Color(0xFF34D399) : primary)
                          : (isDark
                              ? const Color(0xFF8FA89F)
                              : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Đăng ký mới',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13.5,
                        fontWeight:
                            !isLogin ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.15,
                        color: !isLogin
                            ? (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))
                            : (isDark
                                ? const Color(0xFF8FA89F)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      ),
    );
  }

  /// Luxury Bento Input Field with Circular Icon Pod & Focus Glow
  Widget _buildFieldInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
    required Color primary,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172622) : const Color(0xFFF6FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? primary
              : (isDark ? const Color(0xFF263B35) : const Color(0xFFDDE7E3)),
          width: isFocused ? 1.6 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        cursorColor: primary,
        style: TextStyle(
          fontFamily: _font,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _font,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isFocused
                    ? primary.withValues(alpha: isDark ? 0.24 : 0.12)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                prefixIcon,
                size: 16,
                color: isFocused
                    ? (isDark ? const Color(0xFF34D399) : primary)
                    : (isDark
                        ? const Color(0xFF8FA89F)
                        : const Color(0xFF64748B)),
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 50, minHeight: 44),
          suffixIcon: suffixIcon,
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  int _computePasswordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[0-9]').hasMatch(pass)) {
      score++;
    }
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
    return score.clamp(1, 4);
  }

  Widget _buildPasswordStrengthBar(bool isDark, int score) {
    final labels = ['Yếu', 'Trung bình', 'Tốt', 'Rất mạnh'];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF059669),
    ];
    final activeColor = colors[(score - 1).clamp(0, 3)];
    final label = labels[(score - 1).clamp(0, 3)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < score;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active
                      ? activeColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Độ mạnh mật khẩu: $label',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: activeColor,
          ),
        ),
      ],
    );
  }

  /// Primary CTA Button with Crystal Quartz Gradient
  Widget _buildPrimaryActionButton(
    bool isDark,
    AuthProvider auth,
    Color primary,
    Color secondary,
  ) {
    String buttonText;
    IconData buttonIcon;
    switch (_mode) {
      case AuthMode.login:
        buttonText = 'Đăng nhập vào Finora';
        buttonIcon = LucideIcons.arrow_right;
        break;
      case AuthMode.signup:
        buttonText = 'Tạo tài khoản miễn phí';
        buttonIcon = LucideIcons.sparkles;
        break;
      case AuthMode.forgotPassword:
        buttonText = 'Gửi liên kết khôi phục';
        buttonIcon = LucideIcons.send;
        break;
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(primary, Colors.black, 0.15)!,
            primary,
            secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.42 : 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: auth.isLoading ? null : _submit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: TextStyle(
                  fontFamily: _font,
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 9),
              Icon(
                buttonIcon,
                size: 17,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Google Sign-In & Divider Section
  Widget _buildGoogleSection(bool isDark, AuthProvider auth, Color primary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF23352F)
                    : const Color(0xFFE2ECE8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'HOẶC TIẾP TỤC VỚI',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF8FA89F)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF23352F)
                    : const Color(0xFFE2ECE8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172622) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF283D37) : const Color(0xFFDCE7E2),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: auth.isLoading ? null : () => auth.signInWithGoogle(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(
                      painter: _OfficialGoogleLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _mode == AuthMode.signup
                        ? 'Đăng ký nhanh bằng Google'
                        : 'Tiếp tục với tài khoản Google',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Feature Highlights Row below Auth Card
  Widget _buildFeatureHighlights(bool isDark, Color primary) {
    final items = [
      (LucideIcons.users, 'Vợ & Chồng'),
      (LucideIcons.bell_ring, 'Auto Ngân hàng'),
      (LucideIcons.bot, 'Trợ lý AI'),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2ECE8),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.$1,
                  size: 15,
                  color: isDark ? const Color(0xFF34D399) : primary,
                ),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Security Footer
  Widget _buildSecurityFooter(bool isDark, Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.shield_check,
          size: 15,
          color: isDark ? const Color(0xFF34D399) : primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Mã hóa bảo mật chuẩn Finora Cloud Ledger 2026',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8FA89F) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  /// Loading Overlay
  Widget _buildLoadingOverlay(bool isDark, Color primary) {
    return Container(
      color: Colors.black.withValues(alpha: 0.48),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14201D) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF283B34) : const Color(0xFFE2ECE7),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang xác thực tài khoản...',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Official 4-Color Google 'G' Mark Painter (Exact Vector Identity)
class _OfficialGoogleLogoPainter extends CustomPainter {
  const _OfficialGoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue (#4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green (#34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow (#FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red (#EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.70, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
