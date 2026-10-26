import '../../core/widgets/glass_widgets.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_logo.dart';
import '../../state/auth_provider.dart';
import '../main/main_screen.dart';

enum AuthMode { login, signup, forgotPassword }

/// Finora Authentication Screen with Palette Inspired by Ethereal Sky & Deep Sapphire.
/// Features pill-shaped buttons, official Google G logo, and system Light/Dark mode.
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
      duration: const Duration(milliseconds: 320),
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

  void _showToast(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF00C2FA), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0E2D6C),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(
              color: isDark
                  ? const Color(0xFF00C2FA).withOpacity(0.3)
                  : const Color(0xFFADCDEF),
              width: 1.2,
            ),
          ),
          backgroundColor: isDark
              ? const Color(0xFF0E2D6C).withOpacity(0.95)
              : Colors.white.withOpacity(0.98),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _switchMode(AuthMode mode) {
    HapticFeedback.selectionClick();
    _animController.reset();
    setState(() {
      _mode = mode;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _fullNameController.clear();
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
    final size = MediaQuery.of(context).size;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Dynamic Iridescent Orbs Background
          _buildPaletteAuraBackground(isDark, size),

          // 2. Main Scrollable View
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Brand Hero Logo Badge
                      _buildHeroLogo(isDark),

                      const SizedBox(height: 16),

                      // Title & Subtitle
                      _buildHeaderTexts(isDark),

                      const SizedBox(height: 22),

                      // Pill-shaped Mode Tab Bar [ Đăng nhập | Đăng ký ]
                      if (_mode != AuthMode.forgotPassword)
                        _buildPillModeTabBar(isDark),

                      const SizedBox(height: 18),

                      // Main Frosted Glass Form Card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFormCard(isDark, auth),
                      ),

                      const SizedBox(height: 22),

                      // Big Pill Google Sign-in Button
                      if (_mode != AuthMode.forgotPassword) ...[
                        _buildPillGoogleButton(isDark, auth),
                        const SizedBox(height: 20),
                      ],

                      // Privacy / Security Badge
                      _buildSecurityFooter(isDark),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Iridescent Aura Orbs from palette
  Widget _buildPaletteAuraBackground(bool isDark, Size size) => Positioned.fill(
        child: DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF0F172A),
                            Color(0xFF17243A),
                            Color(0xFF101B2C)
                          ]
                        : const [
                            Color(0xFFF8FAFC),
                            Color(0xFFEEF4FF),
                            Color(0xFFF3F7FB)
                          ]))),
      );

  /// Finora Brand Hero Logo Badge
  Widget _buildHeroLogo(bool isDark) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: FinoraBrandLogo(width: 192, height: 60),
      );

  Widget _buildHeaderTexts(bool isDark) {
    String title;
    String subtitle;

    switch (_mode) {
      case AuthMode.login:
        title = 'Chào mừng trở lại';
        subtitle = 'Đăng nhập để quản lý chi tiêu & đầu tư cùng Finora';
        break;
      case AuthMode.signup:
        title = 'Tạo tài khoản Finora';
        subtitle = 'Khởi đầu kế hoạch tiết kiệm & thịnh vượng tài chính';
        break;
      case AuthMode.forgotPassword:
        title = 'Khôi phục mật khẩu';
        subtitle = 'Nhập email để nhận đường dẫn đặt lại mật khẩu an toàn';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: isDark ? Colors.white : const Color(0xFF0E2D6C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFFA3B4D4) : const Color(0xFF5B6E8C),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Pill-shaped Mode Tab Bar: [ Đăng nhập | Đăng ký ] (BorderRadius: 100)
  Widget _buildPillModeTabBar(bool isDark) => BouncyPillTabs(
        labels: const ['Đăng nhập', 'Đăng ký'],
        selectedIndex: _mode == AuthMode.login ? 0 : 1,
        colors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
        onChanged: (i) =>
            _switchMode(i == 0 ? AuthMode.login : AuthMode.signup),
      );

  /// Main Frosted Glass Form Card
  Widget _buildFormCard(bool isDark, AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E1A33).withOpacity(0.82)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? const Color(0xFF1E335C) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF0E2D6C))
                    .withOpacity(isDark ? 0.35 : 0.06),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Full Name (Signup only)
              if (_mode == AuthMode.signup) ...[
                _buildFieldLabel('HỌ VÀ TÊN', isDark),
                const SizedBox(height: 6),
                _buildFieldInput(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  hint: 'Nguyễn Văn A',
                  prefixIcon: Icons.person_outline_rounded,
                  isDark: isDark,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
              ],

              // 2. Email Address
              _buildFieldLabel('ĐỊA CHỈ EMAIL', isDark),
              const SizedBox(height: 6),
              _buildFieldInput(
                controller: _emailController,
                focusNode: _emailFocus,
                hint: 'name@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
              ),

              // 3. Password
              if (_mode != AuthMode.forgotPassword) ...[
                const SizedBox(height: 16),
                _buildFieldLabel('MẬT KHẨU', isDark),
                const SizedBox(height: 6),
                _buildFieldInput(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: isDark
                          ? const Color(0xFFA3B4D4)
                          : const Color(0xFF6A92C8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],

              // 4. Confirm Password (Signup only)
              if (_mode == AuthMode.signup) ...[
                const SizedBox(height: 16),
                _buildFieldLabel('XÁC NHẬN MẬT KHẨU', isDark),
                const SizedBox(height: 6),
                _buildFieldInput(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  hint: '••••••••',
                  prefixIcon: Icons.shield_outlined,
                  isDark: isDark,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: isDark
                          ? const Color(0xFFA3B4D4)
                          : const Color(0xFF6A92C8),
                      size: 20,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ],

              // 5. Remember Me & Forgot Password
              if (_mode == AuthMode.login) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? true),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                activeColor: const Color(0xFF005FEA),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghi nhớ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFA3B4D4)
                                    : const Color(0xFF5B6E8C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _switchMode(AuthMode.forgotPassword),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Color(0xFF005FEA),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // 6. Pill-shaped Primary CTA Button (BorderRadius: 100)
              const SizedBox(height: 20),
              _buildPillPrimaryActionButton(isDark, auth),

              // 7. Back to Login for Forgot Password Mode
              if (_mode == AuthMode.forgotPassword) ...[
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _switchMode(AuthMode.login),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: Color(0xFF005FEA)),
                    label: const Text(
                      'Quay lại Đăng nhập',
                      style: TextStyle(
                        color: Color(0xFF005FEA),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: isDark ? const Color(0xFF9DB2DC) : const Color(0xFF5B6E8C),
      ),
    );
  }

  /// Modern Pill-shaped Input Field with Active Glow (BorderRadius: 100)
  Widget _buildFieldInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark
            ? (isFocused ? const Color(0xFF132242) : const Color(0xFF0F1A33))
            : (isFocused ? const Color(0xFFF6FAFF) : const Color(0xFFEEF5FD)),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF00C2FA)
              : (isDark
                  ? const Color(0xFF1E3259)
                  : const Color(0xFFADCDEF).withOpacity(0.7)),
          width: isFocused ? 1.6 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF00C2FA).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
        cursorColor: const Color(0xFF005FEA),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0E2D6C),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF6A7E9F) : const Color(0xFF9DB2DC),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              prefixIcon,
              size: 20,
              color: isFocused
                  ? const Color(0xFF00C2FA)
                  : (isDark
                      ? const Color(0xFF6A7E9F)
                      : const Color(0xFF9DB2DC)),
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: suffixIcon,
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
    );
  }

  /// Primary Gradient CTA Button - Bo chuẩn viên thuốc (BorderRadius: 100)
  Widget _buildPillPrimaryActionButton(bool isDark, AuthProvider auth) {
    String buttonText;
    switch (_mode) {
      case AuthMode.login:
        buttonText = 'Đăng nhập ngay';
        break;
      case AuthMode.signup:
        buttonText = 'Tạo tài khoản mới';
        break;
      case AuthMode.forgotPassword:
        buttonText = 'Gửi liên kết khôi phục';
        break;
    }

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF005FEA), // Vibrant sapphire blue
            Color(0xFF00C2FA), // Radiant sky cyan
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005FEA).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: auth.isLoading ? null : _submit,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Big Pill Google Sign-In Button with Official Vector 4-Color Google 'G' Logo (BorderRadius: 100)
  Widget _buildPillGoogleButton(bool isDark, AuthProvider auth) {
    return Column(
      children: [
        // "Hoặc tiếp tục với" Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color:
                    isDark ? const Color(0xFF1E335C) : const Color(0xFFD5E4F7),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'hoặc tiếp tục với',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFA3B4D4)
                      : const Color(0xFF6A92C8),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color:
                    isDark ? const Color(0xFF1E335C) : const Color(0xFFD5E4F7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Large Pill Google Login Button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E1A33).withOpacity(0.85)
                : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E355E)
                  : const Color(0xFFADCDEF).withOpacity(0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF0E2D6C))
                    .withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: auth.isLoading ? null : () => auth.signInWithGoogle(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vector-sharp Official Google 'G' Logo (Correct Upright Orientation)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: _OfficialGoogleLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đăng nhập với Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0E2D6C),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Demo Guest Mode Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainScreen(
                    demoUserId: 'demo_user_123',
                    demoUserName: 'Hòa Trần',
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                    : const Color(0xFF0284C7).withValues(alpha: 0.3),
              ),
              backgroundColor: isDark
                  ? const Color(0xFF161B26).withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.85),
            ),
            icon: const Icon(Icons.flash_on_rounded,
                color: Color(0xFF38BDF8), size: 18),
            label: Text(
              'Trải nghiệm nhanh (Khách / Demo)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Security Footer
  Widget _buildSecurityFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 14,
          color: isDark ? const Color(0xFF6A7E9F) : const Color(0xFF9DB2DC),
        ),
        const SizedBox(width: 6),
        Text(
          'Mã hóa bảo mật cấp ngân hàng 256-bit SSL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF6A7E9F) : const Color(0xFF9DB2DC),
          ),
        ),
      ],
    );
  }

  /// Beautiful Frosted Loading Overlay
  Widget _buildLuxuryLoadingOverlay(bool isDark) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color:
            (isDark ? const Color(0xFF070D1B) : Colors.white).withOpacity(0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0E1A33).withOpacity(0.92)
                  : Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF00C2FA).withOpacity(0.3)
                    : const Color(0xFFADCDEF),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005FEA).withOpacity(0.25),
                  blurRadius: 35,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Animated Pulse Ring & Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C2FA)),
                        backgroundColor:
                            const Color(0xFF005FEA).withOpacity(0.2),
                      ),
                    ),
                    const FinoraLogo(size: 34),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Đang xác thực...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0E2D6C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vui lòng chờ trong giây lát',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFA3B4D4)
                        : const Color(0xFF5B6E8C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Official Google 'G' Logo Painter (Accurate Official Vector Coordinates)
/// Red at Top, Yellow at Left, Green at Bottom, Blue at Right/Bar
class _OfficialGoogleLogoPainter extends CustomPainter {
  const _OfficialGoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Red Section (Top curve)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 5.0)
      ..cubicTo(13.56, 5.0, 14.98, 5.54, 16.1, 6.43)
      ..lineTo(19.17, 3.36)
      ..cubicTo(17.33, 1.63, 14.86, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.34, 9.15, 5.0, 12.0, 5.0)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // 2. Yellow Section (Left curve)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 3. Green Section (Bottom curve)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.09)
      ..lineTo(2.18, 16.93)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 4. Blue Section (Horizontal bar & Right curve)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.49, 12.28)
      ..cubicTo(23.49, 11.49, 23.42, 10.74, 23.3, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.47, 14.51)
      ..cubicTo(18.18, 15.99, 17.33, 17.24, 16.07, 18.09)
      ..lineTo(19.94, 21.09)
      ..cubicTo(22.2, 19.0, 23.49, 15.92, 23.49, 12.28)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
