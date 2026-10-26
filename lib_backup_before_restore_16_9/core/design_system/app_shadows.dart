import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: const Color(0x06000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0x0A000000),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: const Color(0x1F000000),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowingActiveShadow => [
        BoxShadow(
          color: const Color(0xFF1877F2).withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
