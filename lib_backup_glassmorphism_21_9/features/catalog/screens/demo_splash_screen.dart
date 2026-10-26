import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';

/// Screen 18: Splash (Màn hình chào & loading hệ thống) in Glassmorphism 2.0
class DemoSplashScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoSplashScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoSplashScreen> createState() => _DemoSplashScreenState();
}

class _DemoSplashScreenState extends State<DemoSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 16,
              child: FinoraBackButton(
                onTap: widget.onBack ?? () => Navigator.maybePop(context),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.5),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.wallet, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'FINORA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tài chính cá nhân & Gia đình chuẩn 2.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(GlassmorphismTokens.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(LucideIcons.rotate_cw, size: 16),
                  label: const Text('Phát lại hoạt ảnh chào'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.reset();
                    _controller.forward();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
