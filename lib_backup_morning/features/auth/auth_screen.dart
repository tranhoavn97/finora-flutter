import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../state/auth_provider.dart';

enum AuthMode { login, signup, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _obscure = true;
  
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _sub = auth.events.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _email.clear();
      _password.clear();
      _fullName.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return GradientBackground(
      child: FloatingBubblesBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FinoraBrandLogo(width: 170, height: 56),
                    const SizedBox(height: 8),
                    Text(
                      _mode == AuthMode.login
                          ? 'Chào mừng bạn quay lại Finora'
                          : _mode == AuthMode.signup
                              ? 'Tạo tài khoản quản lý tài chính thông minh'
                              : 'Khôi phục quyền truy cập tài khoản',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Soft Glassmorphism Card
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: GlassCard(
                        radius: 28,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_mode == AuthMode.signup) ...[
                              FinoraTextField(
                                controller: _fullName,
                                hint: 'Họ và tên',
                                radius: 18,
                              ),
                              const SizedBox(height: 12),
                            ],
                            FinoraTextField(
                              controller: _email,
                              hint: 'Địa chỉ Email',
                              keyboardType: TextInputType.emailAddress,
                              radius: 18,
                            ),
                            if (_mode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: 12),
                              FinoraTextField(
                                controller: _password,
                                hint: 'Mật khẩu',
                                obscure: _obscure,
                                radius: 18,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: c.textTertiary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ],
                            if (_mode == AuthMode.login) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _switchMode(AuthMode.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                            ],
                            
                            // Action Button
                            GradientButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () {
                                      final emailStr = _email.text.trim();
                                      final passStr = _password.text;
                                      if (emailStr.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vui lòng nhập Email')),
                                        );
                                        return;
                                      }
                                      if (_mode != AuthMode.forgotPassword && passStr.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vui lòng nhập Mật khẩu')),
                                        );
                                        return;
                                      }
                                      if (_mode == AuthMode.signup && _fullName.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vui lòng nhập Họ tên')),
                                        );
                                        return;
                                      }

                                      if (_mode == AuthMode.login) {
                                        auth.signInWithEmail(emailStr, passStr);
                                      } else if (_mode == AuthMode.signup) {
                                        auth.signUpWithEmail(emailStr, passStr, _fullName.text.trim());
                                      } else {
                                        auth.sendPasswordResetEmail(emailStr);
                                      }
                                    },
                              colors: const [AppColors.primary, AppColors.secondary],
                              radius: 18,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _mode == AuthMode.login
                                          ? 'Đăng nhập'
                                          : _mode == AuthMode.signup
                                              ? 'Tạo tài khoản'
                                              : 'Gửi Email Khôi Phục',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.5,
                                      ),
                                    ),
                            ),
                            
                            // Third-party Auth Divider
                            if (_mode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'Hoặc tiếp tục với',
                                      style: TextStyle(
                                        color: c.textTertiary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Google Auth Button
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF141F3C) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8),
                                    width: 1.2,
                                  ),
                                ),
                                child: TextButton.icon(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => auth.signInWithGoogle(),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                                  ),
                                  label: Text(
                                    'Tiếp tục với Google',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Footer links
                    if (_mode != AuthMode.forgotPassword)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _mode == AuthMode.login
                                ? 'Chưa có tài khoản?'
                                : 'Đã có tài khoản?',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_mode == AuthMode.login) {
                                _switchMode(AuthMode.signup);
                              } else {
                                _switchMode(AuthMode.login);
                              }
                            },
                            child: Text(
                              _mode == AuthMode.login ? 'Đăng ký ngay' : 'Đăng nhập',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: () => _switchMode(AuthMode.login),
                        child: const Text(
                          'Quay lại Đăng nhập',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
