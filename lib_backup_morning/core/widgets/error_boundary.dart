import 'dart:ui';
import 'package:flutter/material.dart';

/// Catches uncaught UI build errors inside subtrees and displays an elegant fallback
/// instead of the red screen of death or crashing the application.
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? componentName;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.componentName,
  });

  static void initializeGlobalHandlers() {
    // 1. Intercept Flutter framework errors (layout, render, build)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // In production, send to Crashlytics / analytics here
      debugPrint('[Finora ErrorBoundary] Framework error: ${details.exceptionAsString()}');
    };

    // 2. Intercept asynchronous platform dispatcher errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('[Finora ErrorBoundary] Async platform error: $error\n$stack');
      return true; // Handled, prevent app crash
    };

    // 3. Fallback widget builder when build() throws
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tạm thời không hiển thị được thành phần này',
                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    };
  }

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  void retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(height: 8),
            Text(
              'Không thể tải dữ liệu ${widget.componentName ?? ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}
