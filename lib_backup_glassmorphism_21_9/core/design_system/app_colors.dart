import 'package:flutter/material.dart';

class AppColors {
  // Apple System Grouped Backgrounds
  static const Color lightBg = Color(0xFFF2F2F7); // Apple iOS light grouped canvas
  static const Color lightSurface = Color(0xFFFFFFFF); // Apple iOS secondary grouped surface
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF000000); // Apple label
  static const Color lightTextSecondary = Color(0xFF8E8E93); // Apple secondaryLabel
  static const Color lightTextTertiary = Color(0xFFC7C7CC); // Apple tertiaryLabel
  static const Color lightBorder = Color(0xFFE5E5EA); // Apple hairline separator
  static const Color lightDivider = Color(0xFFE5E5EA);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF000000); // Apple iOS pure dark canvas
  static const Color darkSurface = Color(0xFF1C1C1E); // Apple iOS secondary grouped surface (dark)
  static const Color darkSurfaceSolid = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF48484A);
  static const Color darkBorder = Color(0xFF38383A); // Apple dark separator
  static const Color darkDivider = Color(0xFF38383A);

  // Semantic Colors (Apple HIG Standard)
  static const Color primary = Color(0xFF007AFF); // Apple System Blue
  static const Color primaryLight = Color(0xFF5AC8FA); // Apple System Cyan
  static const Color primaryDark = Color(0xFF0051A8);
  static const Color secondary = Color(0xFF5856D6); // Apple System Indigo/Purple
  static const Color accent = Color(0xFF007AFF); // Apple Blue
  static const Color accentLight = Color(0xFF5AC8FA);
  static const Color sirenDarkNavy = Color(0xFF000000);
  static const Color success = Color(0xFF34C759); // Apple System Green
  static const Color warning = Color(0xFFFF9500); // Apple System Orange
  static const Color error = Color(0xFFFF3B30); // Apple System Red
  static const Color info = Color(0xFF007AFF);

  // Apple Card & Cash Gradients
  static const LinearGradient heroBlueGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF0051A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroPurpleGradient = LinearGradient(
    colors: [Color(0xFF5856D6), Color(0xFF3634A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBalanceGradient = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
