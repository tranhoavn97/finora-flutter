import 'package:flutter/material.dart';

/// The same credit-card skins as web/src/components/wallets/BankCard.tsx.
abstract final class CreditCardPalette {
  static const skins = <String, List<Color>>{
    'gold': [Color(0xFF4A380A), Color(0xFF785C14), Color(0xFF2E2205)],
    'silver': [Color(0xFF2C3440), Color(0xFF455263), Color(0xFF1C222B)],
    'blue': [Color(0xFF0D366E), Color(0xFF1A5BB8), Color(0xFF082247)],
    'cyan': [Color(0xFF084857), Color(0xFF0D728A), Color(0xFF052C36)],
    'emerald': [Color(0xFF08452D), Color(0xFF0F6E49), Color(0xFF052B1C)],
    'lime': [Color(0xFF354D08), Color(0xFF567A10), Color(0xFF203004)],
    'orange': [Color(0xFF632707), Color(0xFF9C3F0E), Color(0xFF3B1703)],
    'rose': [Color(0xFF590D1B), Color(0xFF8C162D), Color(0xFF3B0710)],
    'pink': [Color(0xFF590B37), Color(0xFF8C1457), Color(0xFF3B0623)],
    'purple': [Color(0xFF3A0F5C), Color(0xFF601A99), Color(0xFF24083B)],
    'indigo': [Color(0xFF1F1F69), Color(0xFF3535A6), Color(0xFF131342)],
    'black': [Color(0xFF18191E), Color(0xFF242730), Color(0xFF0F1013)],
  };

  static String resolve(String? theme, String? bankCode, String name) {
    if (theme?.isNotEmpty == true) return theme == 'dark' ? 'black' : theme!;
    if (RegExp(r'gold|vàng', caseSensitive: false).hasMatch(name))
      return 'gold';
    if (RegExp(r'sliver|silver|bạc|platinum', caseSensitive: false)
        .hasMatch(name)) return 'silver';
    return switch (bankCode?.toLowerCase()) {
      'mbbank' || 'mb' || 'bidv' || 'acb' => 'blue',
      'vcb' || 'vietcombank' || 'vpb' || 'vpbank' => 'emerald',
      'tcb' || 'techcombank' || 'cake' || 'hdb' || 'hdbank' => 'rose',
      'tpb' || 'tpbank' || 'timo' => 'purple',
      _ => 'black',
    };
  }

  static List<Color> gradient(String? theme, String? bankCode, String name) =>
      skins[resolve(theme, bankCode, name)] ?? skins['black']!;

  static List<Color> resolveWithStudio(
    dynamic studio, {
    String? walletId,
    String? theme,
    String? bankCode,
    required String name,
  }) {
    if (studio != null) {
      try {
        return studio.getBankCardGradient(
          walletId: walletId,
          bankCode: bankCode,
          name: name,
          themeColor: theme,
        ) as List<Color>;
      } catch (_) {}
    }
    return gradient(theme, bankCode, name);
  }
}
