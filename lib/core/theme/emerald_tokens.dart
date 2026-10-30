import 'package:flutter/material.dart';

/// FINORA Emerald Design Tokens
/// Nguồn chuẩn: D:\FINORA-\design\emerald-demo-20261027 (style.css & README.md)
/// Chuẩn màn hình logic 384 × 824 px.
class EmeraldTokens {
  EmeraldTokens._();

  // --- 1. Colors & Palette ---
  static const Color pine = Color(0xFF003D35);
  static const Color pineDark = Color(0xFF002C25);
  static const Color pineMedium = Color(0xFF004B3C);
  static const Color pineHeader = Color(0xFF003E34);
  static const Color pineHeaderEnd = Color(0xFF00705B);

  static const Color emerald = Color(0xFF00866A);
  static const Color emeraldPrimary = Color(0xFF008367);
  static const Color primary = emeraldPrimary;
  static const Color emeraldActive = Color(0xFF006B50);
  static const Color emeraldDark = Color(0xFF005B43);
  static const Color emeraldDeep = Color(0xFF00503F);
  static const Color emeraldGradStart = Color(0xFF007B60);
  static const Color emeraldGradEnd = Color(0xFF00503F);

  static const Color buttonGradStart = Color(0xFF00896B);
  static const Color buttonGradEnd = Color(0xFF00785E);

  static const Color mint = Color(0xFFBDEDD6);
  static const Color mintLight = Color(0xFFE2F2E8);
  static const Color mintSoft = Color(0xFFEDF7F1);
  static const Color mintSubtle = Color(0xFFEEF6F1);
  static const Color mintTabBg = Color(0xFFF0F6F2);
  static const Color mintCardBg = Color(0xFFE7F5EC);
  static const Color mintCardBorder = Color(0xFFD8ECE1);

  static const Color ivoryBg = Color(0xFFF9FBFA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF152B29);
  static const Color inkLight = Color(0xFF263C32);
  static const Color inkSecondary = Color(0xFF566B63);
  static const Color muted = Color(0xFF7A8C85);
  static const Color meta = Color(0xFF86928C);
  static const Color placeholder = Color(0xFFA5B2AC);
  static const Color fieldBg = Color(0xFFF7FAF8);
  static const Color border = Color(0xFFE6EEEA);
  static const Color borderField = Color(0xFFE2EBE5);
  static const Color borderDivider = Color(0xFFEDF1EE);
  static const Color dockBorder = Color(0xFFE9EFEB);

  // Semantics
  static const Color positive = Color(0xFF00835F);
  static const Color negative = Color(0xFFDA6263);
  static const Color coral = Color(0xFFDA6263);
  static const Color dangerText = Color(0xFFCC5B55);
  static const Color dangerBg = Color(0xFFFFF0EE);

  static const Color gold = Color(0xFFC99821);
  static const Color goldBg = Color(0xFFFFF5DC);
  static const Color goldCardBg = Color(0xFFFFF7E5);
  static const Color goldCardBorder = Color(0xFFF6ECD1);

  static const Color blue = Color(0xFF556CC7);
  static const Color blueBg = Color(0xFFEAF1FC);

  // --- 2. Geometry & Dimensions ---
  static const double pagePadding = 22.0;
  static const double buttonHeight = 46.0;
  static const double buttonRadius = 14.0;
  static const double cardRadius = 15.0;
  static const double radiusButton = 14.0;
  static const double balanceCardRadius = 17.0;
  static const double summaryCardRadius = 18.0;
  static const double tabRadius = 23.0;
  static const double dockHeight = 62.0;
  static const double appBarHeight = 58.0;
  static const double minTouchTarget = 44.0;

  // --- 3. Gradients ---
  static const LinearGradient balanceCardGrad = LinearGradient(
    begin: Alignment(-0.8, -0.6),
    end: Alignment(0.9, 0.8),
    colors: [Color(0xFF007B60), Color(0xFF00503F)],
  );

  static const LinearGradient buttonGrad = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [Color(0xFF00896B), Color(0xFF00785E)],
  );

  static const LinearGradient featureBannerGrad = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4),
    colors: [Color(0xFF005E50), Color(0xFF0D636A)],
  );

  static const LinearGradient checkmarkGrad = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF1DB486), Color(0xFF00926A)],
  );

  static const LinearGradient profileTopGrad = LinearGradient(
    begin: Alignment(-0.8, -0.6),
    end: Alignment(0.9, 0.8),
    colors: [Color(0xFF003E34), Color(0xFF00705B)],
  );

  // --- 4. Shadows ---
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08004D3C),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> activeTabShadow = [
    BoxShadow(
      color: Color(0x1F00694F),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];
}
