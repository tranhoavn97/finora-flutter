import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/widgets/glass_widgets.dart';
import 'catalog_registry.dart';

/// Interactive Sandbox Runner for executing any of the 22 screens
/// with live theme switching, data mode toggling, and overflow-safe viewports.
class CatalogSandboxScreen extends StatefulWidget {
  final ScreenCatalogItem item;

  const CatalogSandboxScreen({
    super.key,
    required this.item,
  });

  @override
  State<CatalogSandboxScreen> createState() => _CatalogSandboxScreenState();
}

class _CatalogSandboxScreenState extends State<CatalogSandboxScreen> {
  bool _isDarkMode = true;
  bool _isLiveMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Builder(
        builder: (themedContext) {
          final isDark = Theme.of(themedContext).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            body: Stack(
              children: [
                // Ambient Aurora Background Mesh
                AmbientFloatingBackground(
                  isDark: isDark,
                  child: const SizedBox.expand(),
                ),

                // Active Demo Screen Viewport
                Positioned.fill(
                  child: widget.item.builder(
                    themedContext,
                    _isLiveMode,
                    () => Navigator.maybePop(context),
                  ),
                ),

                // Floating Top Sandbox Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrow_left, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.item.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.item.cluster.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Theme Toggle
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isDarkMode = !_isDarkMode);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                              size: 16,
                              color: _isDarkMode ? const Color(0xFFFFD700) : const Color(0xFF5856D6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Live / Demo Toggle
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isLiveMode = !_isLiveMode);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isLiveMode ? 'Đã chuyển sang Dữ liệu thực tế' : 'Đang ở chế độ Dữ liệu mẫu (Demo)'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isLiveMode
                                  ? GlassmorphismTokens.income.withValues(alpha: 0.2)
                                  : GlassmorphismTokens.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isLiveMode ? GlassmorphismTokens.income : GlassmorphismTokens.primary,
                              ),
                            ),
                            child: Text(
                              _isLiveMode ? 'Live' : 'Demo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isLiveMode ? GlassmorphismTokens.income : GlassmorphismTokens.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
