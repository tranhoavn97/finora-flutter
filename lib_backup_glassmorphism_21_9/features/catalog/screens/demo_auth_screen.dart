import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 16: Auth (Đăng nhập, đăng ký & xác thực bảo mật) in Glassmorphism 2.0
class DemoAuthScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoAuthScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoAuthScreen> createState() => _DemoAuthScreenState();
}

class _DemoAuthScreenState extends State<DemoAuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FinoraBackButton(
                  onTap: widget.onBack ?? () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 20),
              // Finora Brand Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.wallet, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'FINORA',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Quản lý tài chính cá nhân & Gia đình chuẩn 2.0',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 32),
              CatalogGlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isLogin = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLogin ? GlassmorphismTokens.primary.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isLogin ? GlassmorphismTokens.primary : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                                  color: _isLogin ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isLogin = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLogin ? GlassmorphismTokens.primary.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isLogin ? GlassmorphismTokens.primary : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Đăng ký mới',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                                  color: !_isLogin ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInputField('Email hoặc Số điện thoại', LucideIcons.mail, false, isDark),
                    const SizedBox(height: 14),
                    _buildInputField('Mật khẩu bảo mật', LucideIcons.lock, true, isDark),
                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassmorphismTokens.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_isLogin ? 'Đăng nhập thành công!' : 'Đăng ký tài khoản thành công!')),
                          );
                        },
                        child: Text(
                          _isLogin ? 'Đăng nhập' : 'Tạo tài khoản FINORA',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('HOẶC', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                ],
              ),
              const SizedBox(height: 20),
              CatalogGlassCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tiếp tục với tài khoản Google')),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.globe, size: 20),
                    SizedBox(width: 10),
                    Text('Tiếp tục với Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, bool isPassword, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: TextField(
        obscureText: isPassword && _obscurePassword,
        decoration: InputDecoration(
          icon: Icon(icon, size: 18, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? LucideIcons.eye_off : LucideIcons.eye, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}
