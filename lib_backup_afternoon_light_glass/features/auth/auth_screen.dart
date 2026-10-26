import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/app_logo.dart';
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
    setState(() {
      _mode = mode;
      _email.clear();
      _password.clear();
      _fullName.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GradientBackground(
      child: FloatingBubblesBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Area: Custom vector brand logo matching the web
                    const FinoraBrandLogo(width: 160, height: 52),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _mode == AuthMode.login
                          ? 'Chào mừng trở lại!'
                          : _mode == AuthMode.signup
                              ? 'Tạo tài khoản mới của bạn'
                              : 'Khôi phục lại tài khoản',
                      textAlign: TextAlign.center,
                      style: AppTypography.footnote.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Main Glassmorphism Card
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: GlassCard(
                        radius: AppRadius.xl,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_mode == AuthMode.signup) ...[
                              FinoraTextField(
                                controller: _fullName,
                                hint: 'Họ và tên',
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            FinoraTextField(
                              controller: _email,
                              hint: 'Địa chỉ Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            if (_mode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: AppSpacing.md),
                              FinoraTextField(
                                controller: _password,
                                hint: 'Mật khẩu',
                                obscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off : Icons.visibility,
                                    color: isDark ? Colors.white38 : Colors.black38,
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
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: AppTypography.caption1.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: AppSpacing.lg),
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
                              colors: const [AppColors.accent, AppColors.accentLight],
                              radius: AppRadius.sm,
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
                                              ? 'Đăng ký'
                                              : 'Gửi Email Khôi Phục',
                                      style: AppTypography.buttonLabel.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            
                            // Third-party Auth Divider
                            if (_mode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Hoặc tiếp tục với',
                                      style: AppTypography.caption1.copyWith(
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Google Auth Button
                              ClipRRect(
                                borderRadius: AppRadius.radiusSM,
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : Colors.white.withOpacity(0.5),
                                    borderRadius: AppRadius.radiusSM,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => auth.signInWithGoogle(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.radiusSM,
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
                                      style: AppTypography.buttonLabel.copyWith(
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Navigation Footer links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mode == AuthMode.login
                              ? 'Chưa có tài khoản?'
                              : 'Đã có tài khoản?',
                          style: AppTypography.footnote.copyWith(
                            color: secondaryTextColor,
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
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_mode == AuthMode.forgotPassword) ...[
                      TextButton(
                        onPressed: () => _switchMode(AuthMode.login),
                        child: Text(
                          'Quay lại Đăng nhập',
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
