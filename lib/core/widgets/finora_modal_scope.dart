import 'package:flutter/material.dart';

/// Marks modal/dialog/bottom-sheet subtrees so theme glass transparency
/// (`studio.glassOpacity`) only applies to main-screen cards/controls and
/// never makes modals, bottom sheets, pickers, or their inner cards transparent.
class FinoraModalScope extends InheritedWidget {
  const FinoraModalScope({super.key, required super.child});

  static bool isInsideModal(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<FinoraModalScope>() !=
        null) {
      return true;
    }
    final route = ModalRoute.of(context);
    if (route is PopupRoute) return true;
    if (route is PageRoute && route.fullscreenDialog) return true;
    return false;
  }

  static ThemeData opaqueModalTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final solidCard = isDark ? const Color(0xFF162033) : Colors.white;
    return theme.copyWith(
      cardColor: solidCard,
      cardTheme: theme.cardTheme.copyWith(color: solidCard),
    );
  }

  @override
  bool updateShouldNotify(FinoraModalScope oldWidget) => false;
}
