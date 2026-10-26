import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/widgets/finora_navigation.dart';
import '../../../core/widgets/glass_widgets.dart';
import 'demo_dashboard_screen.dart';
import 'demo_profile_screen.dart';
import 'demo_transaction_screen.dart';
import 'demo_wallet_screen.dart';

/// Screen 22: Main Shell (Thanh điều hướng chính Navigation Bar & Header) in Glassmorphism 2.0
class DemoMainShellScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoMainShellScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoMainShellScreen> createState() => _DemoMainShellScreenState();
}

class _DemoMainShellScreenState extends State<DemoMainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background ambient aurora mesh
          const AmbientFloatingBackground(
            child: SizedBox.expand(),
          ),
          // Content views
          IndexedStack(
            index: _currentIndex,
            children: [
              DemoDashboardScreen(
                isLiveMode: widget.isLiveMode,
                onBack: widget.onBack,
              ),
              DemoTransactionScreen(
                isLiveMode: widget.isLiveMode,
                onBack: widget.onBack,
              ),
              DemoWalletScreen(
                isLiveMode: widget.isLiveMode,
                onBack: widget.onBack,
              ),
              DemoProfileScreen(
                isLiveMode: widget.isLiveMode,
                onBack: widget.onBack,
              ),
            ],
          ),
          // Floating translucent dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FinoraNavigation(
              index: _currentIndex,
              onTap: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = idx);
              },
              onAddTap: () {
                HapticFeedback.heavyImpact();
                _showQuickAddSheet(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ghi chép nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionBtn(ctx, 'Khoản chi', LucideIcons.arrow_up_right, GlassmorphismTokens.expense),
                  _buildQuickActionBtn(ctx, 'Khoản thu', LucideIcons.arrow_down_left, GlassmorphismTokens.income),
                  _buildQuickActionBtn(ctx, 'Chuyển khoản', LucideIcons.arrow_left_right, GlassmorphismTokens.primary),
                  _buildQuickActionBtn(ctx, 'Quét hóa đơn', LucideIcons.scan, const Color(0xFFFF9500)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
