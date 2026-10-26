import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/state/theme_studio_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeStudioController Tests', () {
    test('Initializes with default values properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      expect(studio.dockNavStyle, isNotNull);
      expect(studio.seasonalTheme, AppSeasonalTheme.none);
      expect(studio.systemIconPack, isNotNull);
      expect(studio.tabSelectStyle, isNotNull);
      expect(studio.buttonVisualKind, isNotNull);
      expect(studio.widgetCardStyle, isNotNull);
      expect(studio.categoryIconStyle, isNotNull);
      expect(studio.appBarScrollBehavior, isNotNull);
      expect(studio.highRefreshRate120Hz, isNotNull);
    });

    test('All 14 Dock navigation styles can be set and persist', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final style in AppDockNavStyle.values) {
        await studio.setDockNavStyle(style);
        expect(studio.dockNavStyle, style);
      }
    });

    test('All Seasonal Themes can be set', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final season in AppSeasonalTheme.values) {
        await studio.setSeasonalTheme(season);
        expect(studio.seasonalTheme, season);
      }
    });

    test('All Button Visual Kinds can be set', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final kind in AppButtonStyle.values) {
        await studio.setButtonVisualKind(kind);
        expect(studio.buttonVisualKind, kind);
      }
    });

    test('All Widget Card Styles can be set', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final cardStyle in AppWidgetCardStyle.values) {
        await studio.setWidgetCardStyle(cardStyle);
        expect(studio.widgetCardStyle, cardStyle);
      }
    });

    test('All System Icon Packs can be set', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final pack in AppSystemIconPack.values) {
        await studio.setSystemIconPack(pack);
        expect(studio.systemIconPack, pack);
      }
    });

    test('All Category Icon Styles can be set', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final catStyle in AppCategoryIconStyle.values) {
        await studio.setCategoryIconStyle(catStyle);
        expect(studio.categoryIconStyle, catStyle);
      }
    });

    test('120Hz High Refresh Rate toggle works', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setHighRefreshRate120Hz(true);
      expect(studio.highRefreshRate120Hz, isTrue);

      await studio.setHighRefreshRate120Hz(false);
      expect(studio.highRefreshRate120Hz, isFalse);
    });

    test('All 5 Loading Styles can be set and persist', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final style in AppLoadingIndicatorStyle.values) {
        await studio.setLoadingStyle(style);
        expect(studio.loadingStyle, style);
      }
    });

    test('All Master UI Presets apply correctly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final presetMeta in ThemeStudioController.allMasterUiPresets) {
        await studio.applyMasterUiPreset(presetMeta.preset);
        expect(studio.palette, presetMeta.palette);
        expect(studio.uiUxStyle, presetMeta.uiUxStyle);
      }
    });

    test('Reset to default restores expected states', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setHighRefreshRate120Hz(true);
      await studio.setSeasonalTheme(AppSeasonalTheme.springTet);
      await studio.resetToDefault();

      expect(studio.seasonalTheme, AppSeasonalTheme.none);
      expect(studio.highRefreshRate120Hz, isTrue);
      expect(studio.buttonColorMode, AppButtonColorMode.paletteSync);
      expect(studio.dockIconStyle, AppDockIconStyle.modernLucide);
    });

    test('All Button Color Modes can be set and resolve proper gradients', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final mode in AppButtonColorMode.values) {
        await studio.setButtonColorMode(mode);
        expect(studio.buttonColorMode, mode);
        expect(studio.resolvedButtonPrimary, isNotNull);
        expect(studio.resolvedButtonGradient.length, greaterThanOrEqualTo(2));
      }
    });

    test('All Dock Icon Styles can be set and persist', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final iconStyle in AppDockIconStyle.values) {
        await studio.setDockIconStyle(iconStyle);
        expect(studio.dockIconStyle, iconStyle);
      }
    });

    test('TopBar style and scroll behavior sync and persist properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setTopBarStyle(AppTopBarStyle.floatingIsland);
      expect(studio.topBarStyle, AppTopBarStyle.floatingIsland);
      expect(studio.isAppBarFloating, isTrue);
      expect(studio.appBarScrollBehavior, AppAppBarScrollBehavior.floating);

      await studio.setTopBarStyle(AppTopBarStyle.frostedGlass);
      expect(studio.topBarStyle, AppTopBarStyle.frostedGlass);
      expect(studio.isAppBarFloating, isFalse);
      expect(studio.appBarScrollBehavior, AppAppBarScrollBehavior.pinned);

      await studio.setTopBarStyle(AppTopBarStyle.pureMinimal);
      expect(studio.topBarStyle, AppTopBarStyle.pureMinimal);
      expect(studio.appBarOpacity, 0.0);
      expect(studio.appBarBlur, 0.0);
      expect(studio.appBarShowBorder, isFalse);

      await studio.setAppBarScrollBehavior(AppAppBarScrollBehavior.scrollHide);
      expect(studio.isAppBarScrollHide, isTrue);
    });

    test('Smart Lock protects locked components from preset overrides', () async {
      final studio = ThemeStudioController();
      await studio.load();

      // Custom button mode and dock style
      await studio.setButtonColorMode(AppButtonColorMode.cyberNeonPink);
      await studio.setDockNavStyle(AppDockNavStyle.glassNeonUnderline);

      // Lock button style
      await studio.toggleLock('button_style');
      expect(studio.isLocked('button_style'), isTrue);
      expect(studio.isLocked('dock_style'), isFalse);

      // Apply master preset that has its own dockNavStyle
      await studio.applyMasterUiPreset(AppMasterUiPreset.royalCenturion);

      // Locked button_style should be PRESERVED
      expect(studio.buttonColorMode, AppButtonColorMode.cyberNeonPink);
      // Unlocked dock_style should be updated to preset value (pillTabs for royalCenturion)
      expect(studio.dockNavStyle, AppDockNavStyle.pillTabs);

      // Unlock button_style and apply another preset
      await studio.setLock('button_style', false);
      expect(studio.isLocked('button_style'), isFalse);
      await studio.applyMasterUiPreset(AppMasterUiPreset.cyberpunk2077);
      expect(studio.palette, AppColorPalette.cyberNeonPink);
    });

    test('Theme Code export and import preserves full configuration', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setDockNavStyle(AppDockNavStyle.pillTabs);
      await studio.setButtonVisualKind(AppButtonStyle.gradientGlow);
      await studio.setButtonColorMode(AppButtonColorMode.sunsetCoral);
      await studio.setSeasonalTheme(AppSeasonalTheme.springTet);

      final code = studio.exportThemeCode();
      expect(code.startsWith('FINORA-'), isTrue);

      // Change values
      await studio.resetToDefault();
      expect(studio.dockNavStyle, AppDockNavStyle.floatingIsland);
      expect(studio.seasonalTheme, AppSeasonalTheme.none);

      // Import the exported code
      final success = await studio.importThemeCode(code);
      expect(success, isTrue);
      expect(studio.dockNavStyle, AppDockNavStyle.pillTabs);
      expect(studio.buttonVisualKind, AppButtonStyle.gradientGlow);
      expect(studio.buttonColorMode, AppButtonColorMode.sunsetCoral);
      expect(studio.seasonalTheme, AppSeasonalTheme.springTet);
    });

    test('Custom user presets save, load, and delete properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setDockNavStyle(AppDockNavStyle.hyperOsFloatingBar);
      await studio.setButtonColorMode(AppButtonColorMode.emeraldWealth);

      // Save as custom preset
      await studio.saveCustomPreset('My Test Liquid Theme');
      expect(studio.customPresetNames.contains('My Test Liquid Theme'), isTrue);

      // Reset
      await studio.resetToDefault();
      expect(studio.dockNavStyle, AppDockNavStyle.floatingIsland);

      // Load custom preset
      final loaded = await studio.loadCustomPreset('My Test Liquid Theme');
      expect(loaded, isTrue);
      expect(studio.dockNavStyle, AppDockNavStyle.hyperOsFloatingBar);
      expect(studio.buttonColorMode, AppButtonColorMode.emeraldWealth);

      // Delete custom preset
      await studio.deleteCustomPreset('My Test Liquid Theme');
      expect(studio.customPresetNames.contains('My Test Liquid Theme'), isFalse);
    });

    test('Granular resets restore specific sections while preserving others', () async {
      final studio = ThemeStudioController();
      await studio.load();

      // Modify background, card, dock, button, and glass
      await studio.setCustomBgGradient(colors: [Colors.red, Colors.blue]);
      await studio.setGlobalCardSkin(AppCardSkinStyle.carbonObsidian);
      await studio.setDockNavStyle(AppDockNavStyle.compactCapsule);
      await studio.setButtonColorMode(AppButtonColorMode.cyberNeonPink);
      await studio.setGlassBlur(30.0);

      // Verify modified
      expect(studio.useCustomBgGradient, isTrue);
      expect(studio.globalCardSkin, AppCardSkinStyle.carbonObsidian);
      expect(studio.dockNavStyle, AppDockNavStyle.compactCapsule);
      expect(studio.buttonColorMode, AppButtonColorMode.cyberNeonPink);
      expect(studio.glassBlur, 30.0);

      // Reset only background
      await studio.resetBackgroundSettings();
      expect(studio.useCustomBgGradient, isFalse);
      // Other modified properties must remain untouched!
      expect(studio.globalCardSkin, AppCardSkinStyle.carbonObsidian);
      expect(studio.dockNavStyle, AppDockNavStyle.compactCapsule);
      expect(studio.buttonColorMode, AppButtonColorMode.cyberNeonPink);
      expect(studio.glassBlur, 30.0);

      // Reset only dock
      await studio.resetDockSettings();
      expect(studio.dockNavStyle, AppDockNavStyle.floatingIsland);
      // Others still preserved!
      expect(studio.globalCardSkin, AppCardSkinStyle.carbonObsidian);
      expect(studio.buttonColorMode, AppButtonColorMode.cyberNeonPink);
      expect(studio.glassBlur, 30.0);

      // Reset only button
      await studio.resetButtonSettings();
      expect(studio.buttonColorMode, AppButtonColorMode.paletteSync);
      expect(studio.globalCardSkin, AppCardSkinStyle.carbonObsidian);
      expect(studio.glassBlur, 30.0);

      // Reset only cards
      await studio.resetCardSettings();
      expect(studio.globalCardSkin, AppCardSkinStyle.brandClassic);
      expect(studio.glassBlur, 30.0);

      // Reset glass
      await studio.resetGlassSettings();
      expect(studio.glassBlur, 25.0);
    });

    test('preserveBankCardColors toggle and persist works properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      expect(studio.preserveBankCardColors, isTrue);

      await studio.setPreserveBankCardColors(false);
      expect(studio.preserveBankCardColors, isFalse);

      await studio.setPreserveBankCardColors(true);
      expect(studio.preserveBankCardColors, isTrue);
    });

    test('setCustomGradientDirect updates dual adaptive light/dark gradients correctly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      // Set dark custom gradient
      await studio.setCustomGradientDirect(
        startColor: const Color(0xFF0F172A),
        endColor: const Color(0xFF1E1B4B),
        isDark: true,
        angle: 1,
      );

      expect(studio.useCustomBgGradient, isTrue);
      expect(studio.customBgGradientAngle, 1);
      final darkColors = studio.getEffectiveCustomBgGradientColors(true);
      expect(darkColors.first.toARGB32(), const Color(0xFF0F172A).toARGB32());
      expect(darkColors.last.toARGB32(), const Color(0xFF1E1B4B).toARGB32());

      // Set light custom gradient
      await studio.setCustomGradientDirect(
        startColor: const Color(0xFFFFFFFF),
        endColor: const Color(0xFFF1F5F9),
        isDark: false,
        angle: 2,
      );

      expect(studio.customBgGradientAngle, 2);
      final lightColors = studio.getEffectiveCustomBgGradientColors(false);
      expect(lightColors.first.toARGB32(), const Color(0xFFFFFFFF).toARGB32());
      expect(lightColors.last.toARGB32(), const Color(0xFFF1F5F9).toARGB32());
    });

    test('All 6 Transaction List Styles can be switched and preserved', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final style in AppTransactionListStyle.values) {
        await studio.setTransactionListStyle(style);
        expect(studio.transactionListStyle, style);
      }
    });

    test('Curated Community Presets list has 8 presets and can be applied', () async {
      final studio = ThemeStudioController();
      await studio.load();

      expect(ThemeStudioController.curatedCommunityPresets.length, 8);
      final swissPreset = ThemeStudioController.curatedCommunityPresets.first;
      await studio.applyCuratedCommunityPreset(swissPreset);

      expect(studio.palette, swissPreset.palette);
      expect(studio.fontFamily, swissPreset.fontFamily);
      expect(studio.heroCardStyle, swissPreset.heroCardStyle);
      expect(studio.dockNavStyle, swissPreset.dockNavStyle);
      expect(studio.categoryIconStyle, swissPreset.categoryIconStyle);
    });

    test('Theme code export and import roundtrip preserves font, loading, hero card', () async {
      final studio = ThemeStudioController();
      await studio.load();

      await studio.setFontFamily(AppFontFamily.beVietnamPro);
      await studio.setLoadingStyle(AppLoadingIndicatorStyle.goldenCoin3D);
      await studio.setHeroCardStyle(AppHeroCardStyle.executiveBlackVip);

      final code = studio.exportThemeCode();
      expect(code.startsWith('FINORA-'), isTrue);

      final anotherStudio = ThemeStudioController();
      final success = await anotherStudio.importThemeCode(code);
      expect(success, isTrue);
      expect(anotherStudio.fontFamily, AppFontFamily.beVietnamPro);
      expect(anotherStudio.loadingStyle, AppLoadingIndicatorStyle.goldenCoin3D);
      expect(anotherStudio.heroCardStyle, AppHeroCardStyle.executiveBlackVip);
    });

    test('System-Wide Liquid Glass toggles, persists, exports/imports and resets properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      // Check defaults
      expect(studio.systemWideLiquidGlass, isTrue);
      expect(studio.isSystemWideLiquidGlass, isTrue);
      expect(studio.liquidGlassSpecularHighlight, isTrue);
      expect(studio.liquidGlassCausticRefraction, isTrue);

      // Mutate optical parameters
      await studio.setSystemWideLiquidGlass(false);
      await studio.setLiquidGlassSpecularHighlight(false);
      await studio.setLiquidGlassCausticRefraction(false);

      expect(studio.systemWideLiquidGlass, isFalse);
      expect(studio.isSystemWideLiquidGlass, isFalse);
      expect(studio.liquidGlassSpecularHighlight, isFalse);
      expect(studio.liquidGlassCausticRefraction, isFalse);

      // Verify persistence by loading into a new instance
      final freshStudio = ThemeStudioController();
      await freshStudio.load();
      expect(freshStudio.systemWideLiquidGlass, isFalse);
      expect(freshStudio.liquidGlassSpecularHighlight, isFalse);
      expect(freshStudio.liquidGlassCausticRefraction, isFalse);

      // Verify export & import preserves liquid glass settings
      final exported = freshStudio.exportThemeCode();
      expect(exported.startsWith('FINORA-'), isTrue);
      final decodedJson = utf8.decode(base64Url.decode(exported.substring(7)));
      expect(decodedJson.contains('"swlg":0'), isTrue);
      expect(decodedJson.contains('"lgsh":0'), isTrue);
      expect(decodedJson.contains('"lgcr":0'), isTrue);

      final importedStudio = ThemeStudioController();
      await importedStudio.load();
      await importedStudio.setSystemWideLiquidGlass(true);
      await importedStudio.setLiquidGlassSpecularHighlight(true);
      await importedStudio.setLiquidGlassCausticRefraction(true);

      final importOk = await importedStudio.importThemeCode(exported);
      expect(importOk, isTrue);
      expect(importedStudio.systemWideLiquidGlass, isFalse);
      expect(importedStudio.liquidGlassSpecularHighlight, isFalse);
      expect(importedStudio.liquidGlassCausticRefraction, isFalse);

      // Reset glass settings
      await importedStudio.resetGlassSettings();
      expect(importedStudio.systemWideLiquidGlass, isTrue);
      expect(importedStudio.liquidGlassSpecularHighlight, isTrue);
      expect(importedStudio.liquidGlassCausticRefraction, isTrue);
    });

    test('All AppHeroCardStyle values including spatialPrismOrbital persist properly', () async {
      final studio = ThemeStudioController();
      await studio.load();

      for (final style in AppHeroCardStyle.values) {
        await studio.setHeroCardStyle(style);
        expect(studio.heroCardStyle, style);

        final newStudio = ThemeStudioController();
        await newStudio.load();
        expect(newStudio.heroCardStyle, style);
      }
    });
  });

}
