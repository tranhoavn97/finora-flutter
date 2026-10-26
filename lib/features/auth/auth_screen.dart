import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/finora_tokens.dart';
import '../../state/auth_provider.dart';
import '../../state/family_provider.dart';
import '../main/main_screen.dart';

enum AuthMode { login, signup, forgotPassword }

/// FINORA Design System 2026 "Ledger" Authentication Screen (Board 04 Screen 01).
/// Minimalist Warm Paper & Ink aesthetic: zero neon/sapphire gradients, crisp Be Vietnam Pro typography,
/// hairline borders, monolithic ink buttons, and instant Guest/Demo mode access.
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
      duration: const Duration(milliseconds: 240),
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
              Icon(LucideIcons.info, color: FinoraTokens.ink(isDark), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: FinoraTokens.ink(isDark),
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: FinoraTokens.line(isDark), width: 1.0),
          ),
          backgroundColor: FinoraTokens.surface(isDark),
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

    return Scaffold(
      backgroundColor: FinoraTokens.bg(isDark),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // 1. Minimalist Ledger Brand Mark
                      _buildBrandMark(isDark),

                      const SizedBox(height: 20),

                      // 2. Title & Subtitle
                      _buildHeaderTexts(isDark),

                      const SizedBox(height: 24),

                      // 3. Mode Segmented Tabs [ Đăng nhập | Đăng ký ]
                      if (_mode != AuthMode.forgotPassword)
                        _buildModeTabs(isDark),

                      const SizedBox(height: 18),

                      // 4. Main Inset Form Card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFormCard(isDark, auth),
                      ),

                      const SizedBox(height: 20),

                      // 5. Google Sign-In & Instant Demo/Guest Link
                      if (_mode != AuthMode.forgotPassword) ...[
                        _buildGoogleButton(isDark, auth),
                        const SizedBox(height: 14),

                        // Prominent Guest Access Button
                        _buildGuestAccessButton(isDark, auth),
                        const SizedBox(height: 16),
                      ],

                      // 6. Security Footer
                      _buildSecurityFooter(isDark),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (auth.isLoading) _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  /// 1. Minimalist Ledger Brand Mark (Board 01 & 05)
  Widget _buildBrandMark(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FinoraTokens.ink(isDark),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            'F',
            style: TextStyle(
              color: FinoraTokens.bg(isDark),
              fontWeight: FontWeight.w800,
              fontSize: 20,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FINORA',
          style: TextStyle(
            color: FinoraTokens.ink(isDark),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.5,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ],
    );
  }

  /// 2. Header Texts
  Widget _buildHeaderTexts(bool isDark) {
    String title;
    String subtitle;

    switch (_mode) {
      case AuthMode.login:
        title = 'Chào mừng trở lại';
        subtitle = 'Đăng nhập để quản lý chi tiêu & đầu tư cùng Finora';
        break;
      case AuthMode.signup:
        title = 'Tạo tài khoản FINORA';
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
            fontFamily: 'BeVietnamPro',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: FinoraTokens.ink(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: FinoraTokens.inkSecondary(isDark),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 3. Mode Segmented Tabs [ Đăng nhập | Đăng ký ]
  Widget _buildModeTabs(bool isDark) {
    final isLogin = _mode == AuthMode.login;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FinoraTokens.surface2(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FinoraTokens.line(isDark), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.login),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isLogin ? FinoraTokens.surface(isDark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isLogin ? Border.all(color: FinoraTokens.line(isDark), width: 0.8) : null,
                  boxShadow: isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: isLogin ? FontWeight.w600 : FontWeight.w500,
                    color: isLogin ? FinoraTokens.ink(isDark) : FinoraTokens.inkSecondary(isDark),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.signup),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isLogin ? FinoraTokens.surface(isDark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: !isLogin ? Border.all(color: FinoraTokens.line(isDark), width: 0.8) : null,
                  boxShadow: !isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: !isLogin ? FontWeight.w600 : FontWeight.w500,
                    color: !isLogin ? FinoraTokens.ink(isDark) : FinoraTokens.inkSecondary(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Main Inset Form Card
  Widget _buildFormCard(bool isDark, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinoraTokens.line(isDark), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              prefixIcon: LucideIcons.user,
              isDark: isDark,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
          ],

          // 2. Email Address
          _buildFieldLabel('ĐỊA CHỈ EMAIL', isDark),
          const SizedBox(height: 6),
          _buildFieldInput(
            controller: _emailController,
            focusNode: _emailFocus,
            hint: 'name@example.com',
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),

          // 3. Password
          if (_mode != AuthMode.forgotPassword) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFieldLabel('MẬT KHẨU', isDark),
                if (_mode == AuthMode.login)
                  GestureDetector(
                    onTap: () => _switchMode(AuthMode.forgotPassword),
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: FinoraTokens.moss,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _buildFieldInput(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hint: '••••••••',
              prefixIcon: LucideIcons.lock,
              isDark: isDark,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                  color: FinoraTokens.inkSecondary(isDark),
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ],

          // 4. Confirm Password (Signup only)
          if (_mode == AuthMode.signup) ...[
            const SizedBox(height: 14),
            _buildFieldLabel('XÁC NHẬN MẬT KHẨU', isDark),
            const SizedBox(height: 6),
            _buildFieldInput(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              hint: '••••••••',
              prefixIcon: LucideIcons.shield,
              isDark: isDark,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? LucideIcons.eye_off : LucideIcons.eye,
                  color: FinoraTokens.inkSecondary(isDark),
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Primary Solid Ink Action Button (FnButton Primary)
          _buildPrimaryActionButton(isDark, auth),

          // Back to Login for Forgot Password Mode
          if (_mode == AuthMode.forgotPassword) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _switchMode(AuthMode.login),
                child: Text(
                  '← Quay lại Đăng nhập',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: FinoraTokens.inkSecondary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: FinoraTokens.inkSecondary(isDark),
      ),
    );
  }

  /// Flat Sunken Input Field
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
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: FinoraTokens.surface2(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? FinoraTokens.ink(isDark) : FinoraTokens.line(isDark),
          width: isFocused ? 1.4 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        cursorColor: FinoraTokens.ink(isDark),
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: FinoraTokens.ink(isDark),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: FinoraTokens.inkTertiary(isDark),
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 18,
            color: isFocused ? FinoraTokens.ink(isDark) : FinoraTokens.inkSecondary(isDark),
          ),
          suffixIcon: suffixIcon,
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  /// Solid Ink Primary CTA Button (FnButton Primary)
  Widget _buildPrimaryActionButton(bool isDark, AuthProvider auth) {
    String buttonText;
    switch (_mode) {
      case AuthMode.login:
        buttonText = 'Đăng nhập ngay';
        break;
      case AuthMode.signup:
        buttonText = 'Tạo tài khoản';
        break;
      case AuthMode.forgotPassword:
        buttonText = 'Gửi link khôi phục';
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinoraTokens.ink(isDark),
          foregroundColor: FinoraTokens.bg(isDark),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: auth.isLoading ? null : _submit,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: FinoraTokens.bg(isDark),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.arrow_right, size: 16, color: FinoraTokens.bg(isDark)),
          ],
        ),
      ),
    );
  }

  /// Google Sign-In Button (FnButton Outline)
  Widget _buildGoogleButton(bool isDark, AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: FinoraTokens.line(isDark))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'hoặc tiếp tục với',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  color: FinoraTokens.inkTertiary(isDark),
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: FinoraTokens.line(isDark))),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: FinoraTokens.surface(isDark),
              side: BorderSide(color: FinoraTokens.line(isDark), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: auth.isLoading ? null : () => auth.signInWithGoogle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(
                    painter: _OfficialGoogleLogoPainter(),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Đăng nhập với Google',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FinoraTokens.ink(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Prominent Guest Access Button
  Widget _buildGuestAccessButton(bool isDark, AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: FinoraTokens.surface2(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FinoraTokens.line(isDark), width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: auth.isLoading
              ? null
              : () {
                  context.read<FamilyProvider>().init(null);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(),
                    ),
                  );
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: FinoraTokens.moss),
              const SizedBox(width: 8),
              Text(
                'Trải nghiệm ngay (Chế độ dùng thử)',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FinoraTokens.ink(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Security Footer
  Widget _buildSecurityFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.shield_check,
          size: 14,
          color: FinoraTokens.inkTertiary(isDark),
        ),
        const SizedBox(width: 6),
        Text(
          'Mã hóa bảo mật tài chính chuẩn Ledger 2026',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: FinoraTokens.inkTertiary(isDark),
          ),
        ),
      ],
    );
  }

  /// Loading Overlay
  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: FinoraTokens.surface(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinoraTokens.line(isDark), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(FinoraTokens.ink(isDark)),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang xử lý...',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FinoraTokens.ink(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Official Google 'G' Logo Painter (Vector)
class _OfficialGoogleLogoPainter extends CustomPainter {
  const _OfficialGoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Red
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

    // Yellow
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

    // Green
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

    // Blue
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
